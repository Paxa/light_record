#$:.unshift File.expand_path('lib', File.dirname(__FILE__))
#require 'looksee/version'

Gem::Specification.new do |gem|
  gem.name = 'light_record'
  gem.version = "0.2"
  gem.authors = ["Pavel Evstigneev"]
  gem.email = ["pavel.evst@gmail.com"]
  gem.license = 'MIT'
  gem.date = '2016-09-13'
  gem.summary = "Getting process memory"
  gem.homepage = 'http://github.com/paxa/light_record'

  #gem.extra_rdoc_files = ['CHANGELOG', 'LICENSE', 'README.markdown']
  gem.files = Dir['lib/**/*']
  gem.test_files = Dir["spec/**/*.rb"]
  gem.require_path = 'lib'

  gem.specification_version = 3
end