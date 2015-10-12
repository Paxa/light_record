$:.unshift File.expand_path('lib', File.dirname(__FILE__))

require 'bundler/setup'
require "mysql2"
require "active_record"
require 'light_record'

class ARQuestion < ActiveRecord::Base
  self.table_name =  "sample"
end

ActiveRecord::Base.establish_connection(
  adapter: 'mysql2',
  database: 'light_record',
  host: 'localhost',
  username: 'root',
  password: ''
)

ActiveRecord::Base.logger = Logger.new(STDOUT)

p ARQuestion.limit(5000).class
records = ARQuestion.limit(5000).light_records
p records.size

p records.first