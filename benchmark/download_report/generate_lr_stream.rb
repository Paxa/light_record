require_relative './init'

measure_memory do
  count = 0
  CSV.open('./report_lr_stream.csv', 'w') do |csv|

    #headers = nil

    Question.all.light_records_each do |record|
      #headers ||= record.attributes.keys
      csv << record.attributes.values

      #puts "Done #{count}" if count % 5000 == 0
      #count += 1
    end
  end
end