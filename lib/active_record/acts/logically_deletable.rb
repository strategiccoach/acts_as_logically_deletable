require "active_record/acts/logically_deletable/version"
require "active_record/acts/logically_deletable/logical_deletion"

module ActiveRecord
  module Acts
    module LogicallyDeletable
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_logically_deletable
          if table_exists?
            if has_logical_deletion?
              include ActiveRecord::Acts::LogicallyDeletable::LogicalDeletion
            end
          end
        end

        def has_logical_deletion?
          if table_exists?
            column_names.include?('_deleted')
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, ActiveRecord::Acts::LogicallyDeletable
ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation.send :include, ActiveRecord::Acts::LogicallyDeletable::LogicalDeletionAssociations
ActiveRecord::Associations::HasManyThroughAssociation.send :include, ActiveRecord::Acts::LogicallyDeletable::HasManyThroughWithLogicalDeletionAssociation