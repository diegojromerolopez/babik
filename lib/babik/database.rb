# frozen_string_literal: true

module Babik
  # Database configuration
  class Database
    # Return database configuration
    # @return [Hash{adapter:}] Database configuration as a Hash.
    def self.config
      # For ruby version < 3.0
      ActiveRecord::Base.connection_config
    rescue NoMethodError
      ActiveRecord::Base.connection_db_config
    end

    def self.escape(string)
      ActiveRecord::Base.connection.quote(string)
    end
  end
end
