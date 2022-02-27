require_relative 'test_helper'
require_relative 'prepare_db'

#ActiveRecord::Base.logger = Logger.new(STDOUT)

class ARQuestion < ActiveRecord::Base
  self.table_name =  "sample"
  self.primary_key = "policy_id"
end

class ARQuestion_wLR < ActiveRecord::Base
  self.table_name =  "sample"
  self.primary_key = "policy_id"

  module LightRecord
    def light_included?
      true
    end

    def point_granularity
      "Extended #{super}"
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
    module ClassMethods
      def im_a_class_method
        :pam_param_pam_pam
      end
    end
  end
end

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

  describe "LightRecord submodule" do
    it "should include LightRecord submodule if present" do
      record = ARQuestion_wLR.limit(1).light_records.first
      assert(record.light_included?)

      klass = LightRecord.base_extended(ARQuestion_wLR)
      assert_includes(klass.ancestors, ARQuestion_wLR::LightRecord)
      assert_equal(:pam_param_pam_pam, klass.im_a_class_method)
    end

    it "should override attribute methods" do
      record = ARQuestion_wLR.order(:policy_id).limit(1).light_records.first
      assert_equal(record.point_granularity, "Extended 3")
    end
  end

  it "should work with #respond_to?" do
    rand_sql_fn = DB_TYPE == 'postgres' ? "random" : "rand"
    light = ARQuestion.select("*, #{rand_sql_fn}() as extra_column_from_sql").limit(1).light_records.first

    refute_nil(light.extra_column_from_sql)
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
      record.update(ARQuestion.column_names.first => "bla bla lba")
    end
  end

  it "should be not as a new record" do
    record = ARQuestion_wLR.limit(1).light_records.first
    refute(record.new_record?)
  end

  it "should add extra params in query" do
    record = ARQuestion_wLR.where(policy_id: 119736).light_records.first
    assert_equal(record.id, 119736)
  end

  if ActiveRecord::Base.connection.is_a?(ActiveRecord::ConnectionAdapters::Mysql2Adapter)
    it "should select datetime in UTC" do
      # Active Record will set :database_timezone on first query
      # But if no query run on that connection then it will be blank
      # This code is simulating that behaviour
      ActiveRecord::Base.connection_pool.connections.each do |conn|
        client = ActiveRecord::Base.connection.instance_variable_get(:@connection)
        client.query_options.delete(:database_timezone)
      end

      record = ARQuestion_wLR.select("now() as time").light_records.first
      assert(record.time.gmt?, "Time is not UTC")
    end
  end

  it "should return #model_name of original class" do
    record = ARQuestion.where(policy_id: 119736).light_records.first
    assert_equal(ARQuestion.model_name, record.class.model_name)
  end

  it "should reload record" do
    record = ARQuestion.offset(3).limit(1).light_records.first

    new_granularity = Time.now.to_i
    ARQuestion.find_by(policy_id: record.policy_id).update_columns(point_granularity: new_granularity)

    refute_equal(record.point_granularity, new_granularity)
    record.reload
    assert_equal(record.point_granularity, new_granularity)
  end
end