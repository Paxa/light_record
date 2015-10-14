require 'bundler/setup'

require "active_record"

#require "stackprof"
#require "flamegraph"
require 'memory_profiler'
require "process_memory"

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

ARQuestion.first
#filename = "1.html"
#Flamegraph.generate(filename) do
#end

report = MemoryProfiler.report do
  records = []
  records_data = []
  GC.start
  start_mem = ProcessMemory.current_mb
  start_time = Time.now
  puts "#{Time.now} --- RAM: #{start_mem}mb"
  ARQuestion.all.limit(5000).each do |record|
    records_data << record.attributes.to_json #"#{record.rev_id} #{record.title} #{record.serial_id} #{record.question}"
    records << record
    #records_json << record.to_json
  end

  puts "Time: #{Time.now - start_time}"
  end_mem = ProcessMemory.current_mb
  puts "#{Time.now} --- RAM: #{end_mem}mb"
  puts "Diff: #{end_mem - start_mem}mb"
  puts records.size
end

report.pretty_print
