require_relative './init'


measure_memory do
  count = 0
  CSV.open('./report_lr.csv', 'w') do |csv|

    records = Question.all.light_records.to_a

    records.each do |record|
      csv << record.attributes.values

      #puts "Done #{count}" if count % 5000 == 0
      #count += 1
    end
  end
end
