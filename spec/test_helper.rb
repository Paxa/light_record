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
