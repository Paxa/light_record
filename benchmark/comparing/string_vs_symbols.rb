require "benchmark/ips"
require "benchmark/memory"
require_relative '../init'

conn = ActiveRecord::Base.connection_pool.checkout
$client = conn.instance_variable_get(:@connection)
$max_rows = ENV['LIMIT'] ? ENV['LIMIT'].to_i : 40_000


def simbols_sample
  $client.query("SELECT * FROM sample limit #{$max_rows}", as: :hash, cache_rows: false, symbolize_keys: true).each do |row|
    row
  end
end

def strings_sample
  $client.query("SELECT * FROM sample limit #{$max_rows}", as: :hash, cache_rows: false, symbolize_keys: false).each do |row|
    row
  end
end

Benchmark.ips do |x|
  x.config(time: 7, warmup: 2)

  x.report("Symbols") { simbols_sample }
  x.report("Strings") { strings_sample }

  x.compare!
end

puts "\n## Benchmarking Memory Usage ##\n\n"

Benchmark.memory do |x|
  x.report("Symbols") { simbols_sample }
  x.report("Strings") { strings_sample }

  x.compare!
end
