# Acts::As::Logically::Deletable

Implements logical deletion in ActiveRecord 2.x, including associations.

## Installation

Add this line to your application's Gemfile:

    gem 'acts_as_logically_deletable'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install acts_as_logically_deletable

## Usage

Models with logical deletion must have a '_deleted' boolean column in their schema.

Example:

    class Foo < ActiveRecord::Base
      acts_as_logically_deletable
    end

Several methods are added to facilitate managing logically deleted records:

    foo.undelete              # un-deletes the record by setting _deleted to false
    Foo.delete_all!(options)  # physically delete all records
    Foo.destroy!              # physically delete record

In addition, the finder option :with_deleted can be added to include deleted records in the call.

    foo = Foo.create
    Foo.count                        # 1
    foo.destroy                      # logically deletes the record
    Foo.count                        # 0
    Foo.count(:with_deleted => true) # 1
    
## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
