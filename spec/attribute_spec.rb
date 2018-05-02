require_relative 'test_helper'
require_relative 'prepare_db'

#ActiveRecord::Base.logger = Logger.new(STDOUT)

class ARQuestion < ActiveRecord::Base
  self.table_name =  "sample"
  self.primary_key = "policy_id"
end

describe "LightRecord attributes" do

  it "should assign attributes as method" do
    record = ARQuestion.limit(10).light_records.first
    record.statecode = "AAA"
    assert_equal(record.statecode, "AAA")
  end

  it "should assign attributes ignoring type casting" do
    record = ARQuestion.limit(10).light_records.first
    record.statecode = 123
    assert_equal(record.statecode, 123)
  end

  it "should assign attributes as hash" do
    record = ARQuestion.limit(10).light_records.first
    record[:statecode] = "AAA"
    assert_equal(record[:statecode], "AAA")
  end

  it "should allow updating attributes" do
    record = ARQuestion.limit(10).light_records.first
    ARQuestion.transaction do
      record.update_columns(statecode: "AAA")
      assert_equal(record.statecode, "AAA")
      raise ActiveRecord::Rollback
    end
    # TODO
    # assert_equal(record.statecode, "FL")
  end

end
