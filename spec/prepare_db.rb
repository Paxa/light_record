require "mysql2"
require "active_record"

require 'active_record/connection_adapters/mysql2_adapter'
require 'active_record/connection_adapters/postgresql_adapter'

DB_TYPE = ENV['DB'] == 'postgres' || ENV['DATABASE_URL'].to_s.start_with?("postgresql://") ? 'postgres' : 'mysql'

if DB_TYPE == 'postgres'
  ActiveRecord::Base.establish_connection(
    adapter: 'postgresql',
    url: ENV['DATABASE_URL'] || "postgresql://#{ENV["USER"]}@localhost/light_record",
    pool: 5,
    reconnect: true
  )
else
  ActiveRecord::Base.establish_connection(
    adapter: 'mysql2',
    url: ENV['DATABASE_URL'] || "mysql2://root@127.0.0.1/light_record",
    pool: 5,
    reconnect: true
  )
end


module TestDB

  SAMPLE_TABLE = 'sample'

  def self.init
    db = ActiveRecord::Base.connection

    if db.data_source_exists?(SAMPLE_TABLE)
      puts "Testing table already exists"
      return
    end

    if db.is_a?(ActiveRecord::ConnectionAdapters::Mysql2Adapter)
      db.execute(%{
        CREATE TABLE `#{SAMPLE_TABLE}` (
          `policy_id` int(11) NOT NULL,
          `statecode` varchar(255) DEFAULT NULL,
          `county` varchar(255) DEFAULT NULL,
          `eq_site_limit` varchar(255) DEFAULT NULL,
          `hu_site_limit` varchar(255) DEFAULT NULL,
          `fl_site_limit` varchar(255) DEFAULT NULL,
          `fr_site_limit` varchar(255) DEFAULT NULL,
          `tiv_2011` varchar(255) DEFAULT NULL,
          `tiv_2012` varchar(255) DEFAULT NULL,
          `eq_site_deductible` float DEFAULT NULL,
          `hu_site_deductible` varchar(255) DEFAULT NULL,
          `fl_site_deductible` int(11) DEFAULT NULL,
          `fr_site_deductible` int(11) DEFAULT NULL,
          `point_latitude` varchar(255) DEFAULT NULL,
          `point_longitude` varchar(255) DEFAULT NULL,
          `line` varchar(255) DEFAULT NULL,
          `construction` varchar(255) DEFAULT NULL,
          `point_granularity` int(11) DEFAULT NULL,
          PRIMARY KEY (`policy_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
      })
    elsif db.is_a?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      db.execute(%{
        CREATE TABLE #{SAMPLE_TABLE} (
          policy_id integer NULL,
          statecode varchar(255) NULL,
          county varchar(255) NULL,
          eq_site_limit varchar(255) NULL,
          hu_site_limit varchar(255) NULL,
          fl_site_limit varchar(255) NULL,
          fr_site_limit varchar(255) NULL,
          tiv_2011 varchar(255) NULL,
          tiv_2012 varchar(255) NULL,
          eq_site_deductible real NULL,
          hu_site_deductible varchar(255) NULL,
          fl_site_deductible real NULL,
          fr_site_deductible real NULL,
          point_latitude varchar(255) NULL,
          point_longitude varchar(255) NULL,
          line varchar(255) DEFAULT NULL,
          construction varchar(255) NULL,
          point_granularity integer NULL,
          PRIMARY KEY(policy_id)
        );
      })
    end

    import_csv(db)

  ensure
    #db.execute(%{drop table #{SAMPLE_TABLE}})
  end

  def self.import_csv(db)
    require 'csv'

    index = 0
    headers = nil
    rows_to_insert = []

    puts "Importing testing data"

    CSV.foreach(File.dirname(__FILE__) + "/../test_data/FL_insurance_sample.csv", headers: true) do |row|
      headers ||= row.headers

      row_values = []
      headers.size.times do |i|
        row_values << %{'#{db.quote_string(row.field(i))}'}
      end

      rows_to_insert << row_values

      if index % 3000 == 0 && index > 0 || index == 36633
        puts "Row #{index}"

        values = rows_to_insert.map {|r| '(' + r.join(", ") + ')' }.join(', ')

        db.execute(%{
          insert into #{SAMPLE_TABLE} (#{headers.join(", ")}) values #{values}
        })
        rows_to_insert.clear
      end

      index += 1
    end
  end
end

TestDB.init
