$:.unshift File.expand_path('../lib', File.dirname(__FILE__))

require 'bundler/setup'
require "mysql2"
require "active_record"
require 'light_record'

=begin
-- Create syntax for TABLE 'posts'
CREATE TABLE `posts` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(200) DEFAULT NULL,
  `body` text,
  `user_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8;

-- Create syntax for TABLE 'users'
CREATE TABLE `users` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(200) DEFAULT NULL,
  `email` varchar(200) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;
=end

class User < ActiveRecord::Base
  #self.table_name =  "users"
  has_many :posts
end

class Post < ActiveRecord::Base
  #self.table_name =  "posts"
  belongs_to :user
end

ActiveRecord::Base.establish_connection(
  adapter: 'mysql2',
  database: 'light_record',
  host: 'localhost',
  username: 'root',
  password: ''
)

ActiveRecord::Base.logger = Logger.new(STDOUT)

10.times do |i|
  p i
  user = User.create!(name: "User N#{i}", email: "user#{i}@example.com")
  5.times do |n|
    Post.create!(title: "Post #{i}-#{n}", body: "Example " * i * n, user: user)
  end
end if User.all.blank?

users = User.limit(5000).light_records
p users.size
p users[0].posts.to_a
p users[0].posts.light_records

