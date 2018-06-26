# frozen_string_literal: true

require 'active_record'
require 'minitest/unit'
require 'minitest/autorun'
require 'minitest/pride'

# Configure Rails Environment
ENV['RAILS_ENV'] = ENV['RACK_ENV'] = 'test'
if ENV['COVERAGE'] && !%w[rbx jruby].include?(RUBY_ENGINE)
  require 'simplecov'
  SimpleCov.command_name 'RSpec'
end

# Setup the log
require 'fileutils'
FileUtils.mkpath 'log' unless File.directory? 'log'
ActiveRecord::Base.logger = Logger.new('log/test-queries.log')

# Make a connection
adapter = ENV.fetch('DB', 'sqlite3')
case adapter
when 'mysql2', 'postgresql'
  config = {
      # Host 127.0.0.1 required for default postgres installation on Ubuntu.
      host: '127.0.0.1',
      database: 'babik_test',
      encoding: 'utf8',
      min_messages: 'WARNING',
      adapter: adapter,
      username: ENV['DB_USERNAME'] || 'postgres',
      password: ENV['DB_PASSWORD'] || 'postgres'
  }
  ActiveRecord::Tasks::DatabaseTasks.create config.stringify_keys
  ActiveRecord::Base.establish_connection config
when 'sqlite3'
  ActiveRecord::Base.establish_connection adapter: adapter, database: ':memory:'
else
  fail "Unknown DB adapter #{adapter}. Valid adapters are: mysql2, postgresql, sqlite3."
end

# Load babik library
require 'babik'

# Create tables
load "#{__dir__}/db/schema.rb"

# Load models
require 'models/geozone'
require 'models/user'
require 'models/tag'
require 'models/category'
require 'models/post'
require 'models/post_tag'
require 'models/bad_tag'



