require "benchmark/ips"
require_relative '../init'

conn = ActiveRecord::Base.connection_pool.checkout
client = conn.instance_variable_get(:@connection)


class SequelRecord < Sequel::Model
  set_dataset(:sample)
end

class ARRecord < ActiveRecord::Base
  self.table_name = "sample"
end

max_rows = ENV['LIMIT'] ? ENV['LIMIT'].to_i : 40_000

Benchmark.ips do |x|
  x.config(time: 10, warmup: 2)

  x.report("Hash") do
    client.query("SELECT * FROM sample limit #{max_rows}", as: :hash, cache_rows: false, symbolize_keys: true).each do |row|
      [row[:policy_id], row[:statecode], row[:county], row[:eq_site_limit]]
    end
  end

  x.report("Array") do
    client.query("SELECT * FROM sample limit #{max_rows}", as: :array, cache_rows: false).each do |row|
      [row[0], row[1], row[2], row[3]]
    end
  end

  x.report("Sequel") do
    SequelRecord.dataset.limit(max_rows).each do |record|
      [record.policy_id, record.statecode, record.county, record.eq_site_limit]
    end
  end

  x.report("ActiveRecord") do
    ARRecord.all.limit(max_rows).each do |record|
      [record.policy_id, record.statecode, record.county, record.eq_site_limit]
    end
  end

  x.report("LightRecord") do
    ARRecord.all.limit(max_rows).light_records.each do |record|
      [record.policy_id, record.statecode, record.county, record.eq_site_limit]
    end
  end

  x.report("LightRecord Stream") do
    ARRecord.all.limit(max_rows).light_records_each do |record|
      [record.policy_id, record.statecode, record.county, record.eq_site_limit]
    end
  end

  x.compare!
end
