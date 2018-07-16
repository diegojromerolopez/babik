# frozen_string_literal: true

module Babik
  module Config
    # Database configuration
    class Database
      # Return database configuration
      # @return [Hash{adapter:}] Database configuration as a Hash.
      def self.config
        ActiveRecord::Base.connection_config
      end
    end
  end
end