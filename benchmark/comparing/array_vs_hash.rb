require "benchmark/ips"
require "benchmark/memory"
require_relative '../init'

conn = ActiveRecord::Base.connection_pool.checkout
$client = conn.instance_variable_get(:@connection)
$max_rows = ENV['LIMIT'] ? ENV['LIMIT'].to_i : 40_000

def hash_sample
  $client.query("SELECT * FROM sample limit #{$max_rows}", as: :hash, cache_rows: false, symbolize_keys: true).each do |row|
    row
  end
end

def array_sample
  $client.query("SELECT * FROM sample limit #{$max_rows}", as: :array, cache_rows: false).each do |row|
    row
  end
end

Benchmark.ips do |x|
  x.config(time: 7, warmup: 2)

  x.report("Hash") { hash_sample }
  x.report("Array") { array_sample }

  x.compare!
end

puts "\n## Benchmarking Memory Usage ##\n\n"

Benchmark.memory do |x|
  x.report("Hash") { hash_sample }
  x.report("Array") { array_sample }

  x.compare!
end
