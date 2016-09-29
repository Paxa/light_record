require 'bundler/setup'

require 'csv'
require "process_memory"
require "sequel"

require_relative '../spec/prepare_db'
require_relative '../lib/light_record'

DB = Sequel.mysql2("light_record", username: 'root')

class Question < ActiveRecord::Base
  self.table_name =  "sample"
  self.primary_key = "policy_id"
end

begin
  Question.first # warm up
end

def measure_memory
  GC.disable
  recorder = ProcessMemory.start_recording
  start_time = Time.now
  start_objects = ObjectSpace.count_objects[:TOTAL]

  yield

  finish_time = Time.now
  recorder.stop
  finish_objects = ObjectSpace.count_objects[:TOTAL]

  puts "Total Time: #{finish_time - start_time}"
  puts "Objects allocated: #{finish_objects - start_objects}"

  start_memory = recorder.instance_variable_get(:@initial_memory)
  tracks = recorder.instance_variable_get(:@tracks)
  tracks.each do |track|
    mem = (track[1] - start_memory) / 1024.0 / 1024.0
    puts "#{(track[0] - start_time).round(2)}\t#{mem.round(4)}"
  end
end
