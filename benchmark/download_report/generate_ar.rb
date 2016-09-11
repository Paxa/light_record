require_relative './init'

measure_memory do
  count = 0
  CSV.open('./report_ar.csv', 'w') do |csv|

    records = Question.all.to_a
    p records.size

    #headers = nil

    records.each do |record|
      #headers ||= record.attributes.keys
      csv << record.attributes.values

      #puts "Done #{count}" if count % 5000 == 0
      #count += 1
    end
  end
end
