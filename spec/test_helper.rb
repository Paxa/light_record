require 'bundler/setup'
require "minitest/reporters"

Minitest::Reporters.use!(
  Minitest::Reporters::DefaultReporter.new(color: true)
)

def MiniTest.filter_backtrace(bt)
  bt
end

require "mysql2"
require "active_record"
require 'light_record'
require 'looksee'

require "minitest/autorun"

if ActiveRecord.version < Gem::Version.new("6.0.0") && RUBY_VERSION >= '3.0.0'
  raise "Rails 5 doesn't support ruby 3.0+"
end

# ActiveRecord::Base.logger = Logger.new(STDOUT)
