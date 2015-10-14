require 'bundler/setup'

#$:.unshift File.expand_path('../lib', File.dirname(__FILE__))

require "minitest/autorun"

require "mysql2"
require "active_record"
require 'light_record'
require "minitest/reporters"
require 'looksee'

Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new

class ARQuestion < ActiveRecord::Base
  self.table_name =  "sample"
  self.primary_key = "policyID"
end

class ARQuestion_wLR < ActiveRecord::Base
  self.table_name =  "sample"
  self.primary_key = "policyID"

  module LightRecord
    def light_included?
      true
    end
  end
end

ActiveRecord::Base.establish_connection(
  adapter: 'mysql2',
  database: 'light_record',
  host: 'localhost',
  username: 'root',
  password: '',
  pool: 5
)

describe "LightRecord" do

  it "should use different connection with #light_records_each" do
    # Should not raise error
    iterated = false
    ARQuestion.all.light_records_each do |sample|
      iterated = true
      ARQuestion.first
      break
    end

    assert(iterated)
  end

  it "should create class from AR object" do
    klass = LightRecord.base_extended(ARQuestion)
    assert(klass < ARQuestion)

    assert_equal(LightRecord.base_extended(ARQuestion).object_id, klass.object_id)

    assert_equal(klass.column_names, ARQuestion.column_names)
  end

  it "should be serializable" do
    records = ARQuestion.limit(10).light_records
    assert_equal(records.to_json, ARQuestion.limit(10).to_a.to_json)
  end

  it "should be serializable" do
    light = ARQuestion.limit(1).light_records.first
    dark  = ARQuestion.find(light.id)

    assert_equal(light.attributes, dark.attributes.symbolize_keys)
  end

  it "should include LightRecord submodule if present" do
    record = ARQuestion_wLR.limit(1).light_records.first
    assert(record.light_included?)

    klass = LightRecord.base_extended(ARQuestion_wLR)
    assert_includes(klass.ancestors, ARQuestion_wLR::LightRecord)
  end

  it "should work with #respond_to?" do
    light = ARQuestion.select("*, rand() as extra_column_from_sql").limit(1).light_records.first

    assert_respond_to(light, :extra_column_from_sql)
    ARQuestion.column_names.each do |column_name|
      assert_respond_to(light, column_name)
    end
  end

  it "sgould have primary key" do
    light = ARQuestion.limit(1).light_records.first
    dark  = ARQuestion.find(light.id)

    assert_equal(light.id, light[ARQuestion.primary_key])
    assert_equal(light.id, dark.id)
  end

  it "should be read-only" do
    record = ARQuestion_wLR.limit(1).light_records.first

    assert(record.readonly?)

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      record.update_attributes(ARQuestion.column_names.first => "bla bla lba")
    end
  end

  it "should be not as a new record" do
    record = ARQuestion_wLR.limit(1).light_records.first
    refute(record.new_record?)
  end
end