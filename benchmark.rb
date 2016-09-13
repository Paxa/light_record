require 'bundler/setup'

require "mysql2"
require "active_record"
require 'light_record'

require 'process_memory'

require 'benchmark'
require 'benchmark/ips'

ActiveRecord::Base.logger = ActiveSupport::Logger.new("/dev/null")

ActiveRecord::Base.establish_connection(
  adapter:  'mysql2',
  database: 'light_record',
  host:     'localhost',
  username: 'root',
  password: ''
)

class ARSample < ActiveRecord::Base
  self.table_name =  "sample"
  self.primary_key = "policy_id"
end

scope = ARSample.limit(50000)

Benchmark.bm(14) do |x|
  x.report("ActiveRecord:") do
    scope.to_a
  end
  x.report("LightRecord:") do
     scope.light_records
  end
end

GC.disable

puts "TESTING AR"
recorder = ProcessMemory.start_recording

records = []
scope.each do |record|
  records << record.to_json
end

recorder.stop
puts "Time spent: #{Time.now - recorder.instance_variable_get(:@start_time)} sec"
puts recorder.report_per_second_pretty

puts
puts "TESTING LR"
recorder = ProcessMemory.start_recording

records2 = []
scope.light_records_each do |record|
  records2 << record.to_json
end

recorder.stop
puts "Time spent: #{Time.now - recorder.instance_variable_get(:@start_time)} sec"
puts recorder.report_per_second_pretty

=begin
ar_record = scope.first
lr_record = scope.light_record_first

Benchmark.ips do |x|
  x.warmup = 2

  x.report("ActiveRecord") do
    ar_record.tiv_2012
  end

  x.report("LightRecord") do
    lr_record.tiv_2012
  end
end
=end