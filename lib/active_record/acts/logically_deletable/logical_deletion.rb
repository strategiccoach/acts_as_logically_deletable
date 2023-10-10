module ActiveRecord
  module Acts
    module LogicallyDeletable
      module LogicalDeletion
        def self.included(base)
          base.class_eval do
            class << self
              alias_method :delete_all!, :delete_all
            end
          end
          base.send :include, InstanceMethods
        end

        module InstanceMethods
          def self.included(base)
            base.extend(ClassMethods)
            base.class_eval do
              class << self
                VALID_FIND_OPTIONS << :with_deleted
                alias_method_chain :find_every, :logical_deletion
                alias_method_chain :calculate, :logical_deletion
                alias_method_chain :delete_all, :logical_deletion
              end

              # the chain goes like this
              # destroy => destroy_with_transactions
              # destroy_without_transactions => destroy_with_callbacks
              # destroy_without_callbacks (the real thing)
              #
              # since we do not want callbacks for a logical delete,
              # we need destroy_without_transactions to do the "deleting"
              # despite hiding the destroy_without_transactions alias,
              # the "original" destroy_with_callbacks method is still available
              alias_method :destroy_without_transactions, :destroy_with_logical_deletion
            end
          end

          module ClassMethods
            # version of exists? to force inclusion of deleted records
            def exists_without_logical_deletion?(id_or_conditions)
              with_deleted { exists?(id_or_conditions) }
            end

            # chained version of calculate which ignores deleted records
            def calculate_with_logical_deletion(*args)
              if args[2].delete(:with_deleted) || @with_deleted
                with_deleted { calculate_without_logical_deletion(*args) }
              else
                without_deleted { calculate_without_logical_deletion(*args) }
              end
            end

            # logically delete by setting delete flag
            def delete_all_with_logical_deletion(conditions = nil)
              without_deleted { self.update_all [ '_deleted = ?', true ], conditions }
            end

            protected
            # helper to scope finds with the conditions to not include deleted records
            def without_deleted(&block)
              with_scope({ :find => { :conditions => [ "#{deleted_column(table_name)} IS NULL OR #{deleted_column(table_name)} = ?", false ] } }, :merge, &block)
            end

            # helper to force lower levels to NOT use the without_deleted_scope
            def with_deleted(&block)
              begin
                @with_deleted = true
                block.call
              ensure
                @with_deleted = false
              end
            end

            private
            # replacement for find_every to optionally include deleted records
            # (default is to ignore them)
            def find_every_with_logical_deletion(options)
              if options.delete(:with_deleted) || @with_deleted
                find_every_without_logical_deletion(options)
              else
                without_deleted { find_every_without_logical_deletion(options) }
              end
            end

            def deleted_column(table_name)
              "#{table_name}.#{connection.quote_column_name('_deleted')}"
            end
          end

          # friendlier name for testing if record is deleted
          def deleted?
            _deleted?
          end

          # undelete record (if necessary)
          def undelete
            if deleted?
              update_attribute(:_deleted, false)
              DeleteAudit.undelete(self, "Rails")
            end
          end

          # physical delete record
          def destroy!
            transaction { destroy_with_callbacks }
            DeleteAudit.audit_deletion(self, "Rails", true) if self.respond_to?(:_deleted)
          end

          protected
          # logically delete record
          def destroy_with_logical_deletion
            DeleteAudit.audit_deletion(self, "Rails", false)
            unless new_record?
              # this is triggering a an update callback, which may cause ferret to re-index this record (which has been "deleted")
              update_attribute(:_deleted, true)
            end
            freeze
          end
        end
      end

      module LogicalDeletionAssociations
        def self.included(base)
          base.class_eval do
            # support logical deletion in associated models (ie. don't associate with deleted records)
            def association_join_with_logical_deletion
              join = association_join_without_logical_deletion
              join << not_deleted_join_sql if logical_deletion?
              join
            end

            alias_method_chain :association_join, :logical_deletion

            private
            # check whether or not association supports logical deletion
            def logical_deletion?
              reflection.klass.included_modules.include? ActiveRecord::Acts::LogicallyDeletable::LogicalDeletion
            end

            # generate additional condition(s) for join
            def not_deleted_join_sql
              "AND (#{reflection.klass.send :deleted_column, aliased_table_name} IS NULL OR #{reflection.klass.send :deleted_column, aliased_table_name} = 0) "
            end
          end
        end
      end

      module HasManyThroughWithLogicalDeletionAssociation
        def self.included(base)
          base.class_eval do
            # support logical deletion in associated models (ie. don't associate with deleted records)
            def construct_conditions_with_logical_deletion
              conditions = construct_conditions_without_logical_deletion
              conditions << not_deleted_join_sql if logical_deletion?
              conditions
            end

            alias_method_chain :construct_conditions, :logical_deletion

            private
            # check whether or not association supports logical deletion
            def logical_deletion?
              @reflection.through_reflection.klass.included_modules.include? ActiveRecord::Acts::LogicallyDeletable::LogicalDeletion
            end

            # generate additional condition(s) for join
            def not_deleted_join_sql
              table_name = @reflection.through_reflection.table_name
              " AND (#{@reflection.through_reflection.klass.send :deleted_column, table_name} IS NULL OR #{@reflection.through_reflection.klass.send :deleted_column, table_name} = 0) "
            end
          end
        end
      end

    end
  end
end
