require "benchmark/ips"
require_relative '../init'

conn = ActiveRecord::Base.connection_pool.checkout
client = conn.instance_variable_get(:@connection)


class ARRecord < ActiveRecord::Base
  self.table_name = "sample"
end

max_rows = ENV['LIMIT'] ? ENV['LIMIT'].to_i : 4_000

Benchmark.ips do |x|
  x.config(time: 10, warmup: 2)

  x.report("ActiveRecord") do
    ARRecord.all.limit(max_rows).each do |record|
      record.to_json
    end
  end

  x.report("LightRecord") do
    ARRecord.all.limit(max_rows).light_records.each do |record|
      record.to_json
    end
  end

  x.report("LightRecord Stream") do
    ARRecord.all.limit(max_rows).light_records_each do |record|
      record.to_json
    end
  end

  x.compare!
end
