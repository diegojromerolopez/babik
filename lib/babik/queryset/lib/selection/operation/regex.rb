# frozen_string_literal: true

require 'babik/queryset/lib/selection/operation/base'

module Babik
  module Selection
    # SQL operation module
    module Operation
      # Match by case sensitive regex
      class Regex < Base
        def initialize(field, value)
          value = value.inspect[1..-2] if value.instance_of?(Regexp)
          value = value[1..-2] if value.instance_of?(String) && value[0] == '/' && value[-1] == '/'
          value = _mysql2_convert_regex(value) if db_engine == 'mysql2'
          super(field, "?field #{operator} ?value", value)
        end

        def operator
          dbms_adapter = db_engine
          return 'REGEXP' if dbms_adapter == 'mysql2'
          return '~' if dbms_adapter == 'postgresql'
          return 'REGEXP' if dbms_adapter == 'sqlite3'
          raise NotImplementedError, "Invalid dbms #{dbms_adapter}. Only mysql, postgresql, and sqlite3 are accepted"
        end

        def _mysql2_convert_regex(value)
          replacements = { '\\d' => '[0-9]', '\\w' => '[a-zA-Z]' }
          replacements.each do |pcre_pattern, mysql_pattern|
            value = value.gsub(pcre_pattern, mysql_pattern)
          end
          value
        end
      end

      # Match by case insensitive regex
      class IRegex < Regex
        def initialize(field, value)
          value = value.inspect[1..-2] if value.instance_of?(Regexp)
          value = value[1..-2] if value.instance_of?(String) && value[0] == '/' && value[-1] == '/'
          value = "(?i)#{value}" if db_engine == 'sqlite3'
          field = "LOWER(#{field})" if db_engine == 'mysql2'
          super(field, value)
        end

        def operator
          dbms_adapter = db_engine
          return 'REGEXP' if dbms_adapter == 'mysql2'
          return '~*' if dbms_adapter == 'postgresql'
          return 'REGEXP' if dbms_adapter == 'sqlite3'
          raise NotImplementedError, "Invalid dbms #{dbms_adapter}. Only mysql, postgresql, and sqlite3 are accepted"
        end
      end
    end
  end
end
