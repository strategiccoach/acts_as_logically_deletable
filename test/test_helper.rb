require 'test/unit'

require 'rubygems'
gem 'activerecord', '2.3.18'
gem 'activesupport', '2.3.18'
require 'active_record'
require 'active_support/test_case'
require 'active_record/acts/logically_deletable'
# ActiveRecord::Base.logger = ActiveSupport::BufferedLogger.new(STDOUT)

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
def setup_db
  ActiveRecord::Migration.verbose = false
  ActiveRecord::Schema.define(:version => 1) do
    create_table :contacts do |t|
      t.column :name, :string
      t.column :staff_id, :integer
      t.column :_deleted, :boolean
      t.column :created_at, :datetime      
      t.column :updated_at, :datetime
    end
    create_table :staff do |t|
      t.column :name, :string
      t.column :_deleted, :boolean
      t.column :created_at, :datetime      
      t.column :updated_at, :datetime
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

setup_db # the tables must exist for the mixin to work
class Contact < ActiveRecord::Base
  acts_as_logically_deletable
  belongs_to :staff
end
class Staff < ActiveRecord::Base
  set_table_name 'staff'
  acts_as_logically_deletable
end
teardown_db

def contacts(num)
  @contacts_cache ||= {}
  @contacts_cache[num] ||= Contact.find_by_name("contact_#{num}")
end
def staff(num)
  @staff_cache ||= {}
  @staff_cache[num] ||= Staff.find_by_name("staff_#{num}")
end

