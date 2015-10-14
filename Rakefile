require 'rake/testtask'

Rake::TestTask.new do |test|
  test.test_files = Dir.glob('spec/**/*_spec.rb')
end

task :default => :test