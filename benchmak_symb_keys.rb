# Here I compare mysql query with "symbolize_keys: true" and "symbolize_keys: false"

require 'bundler/setup'

require "mysql2"
require "active_record"
require 'light_record'

require 'process_memory'

require 'benchmark'
require 'benchmark/ips'

client = Mysql2::Client.new(
  adapter: 'mysql2',
  database: 'light_record',
  host: 'localhost',
  username: 'root',
  password: ''
)


sql = "select s1.*, s2.* from sample s1 left outer join questions s2 on 1=1 limit 100000"

Benchmark.bm(14) do |x|
  x.report("Symbols") do
    result = client.query(sql, symbolize_keys: true, cache_rows: false)
  end
  x.report("Strings") do
    result = client.query(sql, symbolize_keys: false, cache_rows: false)
  end
end

GC.disable

def measure_memory(title)
  puts "~~~"
  puts "Testing: #{title}"
  recorder = ProcessMemory.start_recording
  yield
  recorder.stop
  puts "Time spent: #{Time.now - recorder.instance_variable_get(:@start_time)} sec"
  puts recorder.report_per_second_pretty
end

measure_memory("Symbols") do
  sleep 0.5
  result = client.query(sql, symbolize_keys: true, cache_rows: false)
  sleep 0.5
end

measure_memory("String") do
  sleep 0.5
  result = client.query(sql, symbolize_keys: false, cache_rows: false)
  sleep 0.5
end