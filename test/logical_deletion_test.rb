require 'test_helper'

class ActsAsSyncableLogicalDeletionTest < ActiveSupport::TestCase
  def setup
    setup_db
    (1..2).each { |counter| s = Staff.new(:name => "staff_#{counter}"); s.id = counter; s.save! }
    (1..6).each { |counter| c = Contact.new(:name => "contact_#{counter}", :staff_id => counter % 2 + 1); c.id = counter; c.save! }
    
    # get the initial record count so that we don't have to hard-code the record count
    @count = ActiveRecord::Base.connection.select_value('SELECT COUNT(*) FROM contacts').to_i
    
    @contacts = [
      contacts(1),
      contacts(2),
      contacts(3),
      contacts(4),
      contacts(5),
      contacts(6)
    ]
    # logically delete contact 2
    contacts(2).destroy
    # physically delete contact 4
    contacts(4).destroy!
  end
  
  def teardown
    teardown_db
    # ActiveRecord::Base.connection.execute('delete from contacts')
    # ActiveRecord::Base.connection.execute('delete from staff')
  end
  
  def test_find
    # find all
    assert_equal @contacts - [contacts(2),contacts(4)], @contacts & Contact.find(:all)
    # find all with conditions
    assert_equal [contacts(6)], @contacts & Contact.find(:all, :conditions => { :staff_id => staff(1).id })
    # find all (including deleted)
    assert_equal @contacts - [contacts(4)], @contacts & Contact.send(:with_deleted) { Contact.all }
    # find all with conditions (including deleted)
    assert_equal [contacts(2),contacts(6)], @contacts & Contact.send(:with_deleted) { Contact.find(:all, :conditions => { :staff_id => staff(1).id }) }
    # find specific
    assert_equal contacts(1), Contact.find(contacts(1).id)
    assert_raises(ActiveRecord::RecordNotFound) { Contact.find(contacts(2).id) }
    # find specific (including deleted)
    assert_equal contacts(2), Contact.send(:with_deleted) { Contact.find(contacts(2).id) }
    # find by dynamic finder
    assert_equal contacts(1), Contact.find_by_id(contacts(1).id)
    assert Contact.find_all_by_staff_id(staff(1).id).include?(contacts(6))
    assert_nil Contact.find_by_id(contacts(2).id)
    assert_equal [], Contact.find_all_by_id(contacts(2).id)
    # find by dynamic finder including deleted
    assert_equal contacts(2), Contact.send(:with_deleted) { Contact.find_by_id(contacts(2).id) }
    assert (Contact.send(:with_deleted) { Contact.find_all_by_id(contacts(2).id) }).include?(contacts(2))
  end
  
  def test_find_with_eager_loading
    # find with eager loading
    assert_equal(staff(2), contacts(1).staff)
    staff(2).destroy
    assert_equal(nil, Contact.find(contacts(1), :include => :staff).staff)
  end

  def test_exists_or_deleted
    # existing record
    # - should exist
    assert Contact.exists?(contacts(1).id)
    # - should exist when including logically deleted
    assert Contact.send(:with_deleted) { Contact.exists?(contacts(1).id) }
    # - should not be deleted
    assert ! Contact.find(contacts(1).id).deleted?

    # logically deleted
    # - should not exist
    assert ! Contact.exists?(contacts(2).id)
    # - should exist when including logically deleted
    assert Contact.send(:with_deleted) { Contact.exists?(contacts(2).id) }
    # - should be deleted
    assert (Contact.send(:with_deleted) { Contact.find(contacts(2).id) }).deleted?
    
    # physically deleted
    # - should not exist
    assert ! Contact.exists?(contacts(4).id)
    # - should not exist when including logically deleted
    assert ! Contact.send(:with_deleted) { Contact.exists?(contacts(4).id) }
  end
  
  def test_count
    # count all
    assert_equal (@count - 2), Contact.count
    # count all with conditions
    assert_equal 1, Contact.count(:all, :conditions => { :staff_id => staff(1).id })
    # count all (including deleted)
    assert_equal (@count - 1), Contact.send(:with_deleted) { Contact.count(:all) }
    # count all with conditions (including deleted)
    assert_equal 2, Contact.send(:with_deleted) { Contact.count(:all, :conditions => { :staff_id => staff(1).id }) }
  end
  
  # TODO: test that children have NOT been deleted (or logically deleted, if they are acts_as_syncable too)
  def test_delete_all
    # delete all with conditions
    assert_equal 1, Contact.delete_all(:staff_id => staff(1).id)
    assert_equal (@count - 3), Contact.count
    assert_equal (@count - 1), Contact.send(:with_deleted) { Contact.count(:all) }
    # really delete all with conditions
    assert_equal 3, Contact.delete_all!(:staff_id => staff(2).id)
    assert_equal 0, Contact.count
    assert_equal (@count - 4), Contact.send(:with_deleted) { Contact.count(:all) }
    # delete all
    assert_equal 0, Contact.delete_all
    assert_equal 0, Contact.count
    assert_equal (@count - 4), Contact.send(:with_deleted) { Contact.count(:all) }
    # really delete all
    assert_equal (@count - 4), Contact.delete_all!
    assert_equal 0, Contact.count
    assert_equal 0, Contact.send(:with_deleted) { Contact.count(:all) }
  end
  
  def test_undelete
    assert_equal (@count - 2), Contact.count

    assert (Contact.send(:with_deleted) { Contact.find(contacts(2).id) }).deleted?
    assert (Contact.send(:with_deleted) { Contact.find(contacts(2).id) }).undelete
    assert ! (Contact.send(:with_deleted) { Contact.find(contacts(2).id) }).deleted?

    assert_equal (@count - 1), Contact.count
  end

  def test_destroy
    assert_equal (@count - 2), Contact.count

    # destroy
    # TODO: test that children have been deleted (or logically deleted, if they are acts_as_syncable too)
    assert_equal contacts(5), Contact.find(contacts(5).id).destroy
    assert_equal (@count - 3), Contact.count
    assert_equal (@count - 1), Contact.send(:with_deleted) { Contact.count(:all) }
    
    # really destroy
    # TODO: test that children have been deleted
    assert_equal contacts(6), Contact.find(contacts(6).id).destroy!
    assert_equal (@count - 4), Contact.count
    assert_equal (@count - 2), Contact.send(:with_deleted) { Contact.count(:all) }
  end
end