# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_record/acts/logically_deletable/version"

Gem::Specification.new do |spec|
  spec.name          = "acts_as_logically_deletable"
  spec.version       = ActiveRecord::Acts::LogicallyDeletable::VERSION
  spec.authors       = ["Dave Pijuan-Nomura"]
  spec.email         = ["dnomura@mac.com"]
  spec.description   = %q{Implements logical deletion in ActiveRecord 2.x, including associations.}
  spec.summary       = %q{Logical deletion for ActiveRecord.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `find .`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "sqlite3"
  spec.add_dependency "activerecord", "~> 2.3.18"
end
