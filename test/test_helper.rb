# frozen_string_literal: true

require 'active_record'
require 'minitest/unit'
require 'minitest/autorun'
require 'minitest/pride'

# Setup the log
require 'fileutils'
FileUtils.mkpath 'log' unless File.directory? 'log'
ActiveRecord::Base.logger = Logger.new('log/test-queries.log')

DEFAULT_DB_ADAPTER = 'sqlite3'
# DEFAULT_DB_ADAPTER = 'mysql2'
# DEFAULT_DB_ADAPTER = 'postgresql'

# Make a connection
adapter = ENV.fetch('DB', DEFAULT_DB_ADAPTER)
case adapter
when 'mysql2', 'postgresql'
  config = {
    host: '127.0.0.1',
    database: 'babik_test',
    encoding: 'utf8',
    min_messages: 'WARNING',
    adapter: adapter,
    username: ENV.fetch('DB_USERNAME', 'postgres'),
    password: ENV.fetch('DB_PASSWORD', 'postgres')
  }
  ActiveRecord::Tasks::DatabaseTasks.create(config.stringify_keys)
  ActiveRecord::Base.establish_connection(config)
when 'sqlite3'
  ActiveRecord::Base.establish_connection adapter: adapter, database: ':memory:'
else
  raise "Unknown DB adapter #{adapter}. Valid adapters are: mysql2, postgresql, sqlite3."
end

# Load babik library
require 'babik'

# Create tables
load "#{__dir__}/config/db/schema.rb"

# Load models
require 'config/models/geozone'
require 'config/models/user'
require 'config/models/tag'
require 'config/models/category'
require 'config/models/post'
require 'config/models/post_tag'
require 'config/models/bad_tag'
require 'config/models/bad_post'
