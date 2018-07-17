# frozen_string_literal: true

require 'babik/queryset/lib/selection/operation/base'

module Babik
  module Selection
    # SQL operation module
    module Operation

      # Match by regex
      class Regex < Base
        def initialize(field, value)
          value = value.inspect[1..-2] if value.class == Regexp
          value = value[1..-2] if value.class == String && value[0] == '/' && value[-1] == '/'
          super(field, "?field #{operator} ?value", value)
        end

        def operator
          dbms_adapter = db_engine
          return 'REGEXP BINARY' if dbms_adapter == 'mysql'
          return '~' if dbms_adapter == 'postgresql'
          return 'REGEXP' if dbms_adapter == 'sqlite3'
          raise "Invalid dbms #{dbms_adapter}. Only mysql, postgresql, and sqlite3 are accepted"
        end
      end

      # Match by case-insensitive regex
      class IRegex < Base
        def initialize(field, value)
          dbms_adapter = Babik::Config::Database.config[:adapter]
          sql_operation = if dbms_adapter == 'sqlite3'
                            "?field #{operator} ?value"
                          else
                            "LOWER(?field) #{operator} ?value"
                          end
          super(field, sql_operation, value)
        end

        def _init_sql_operation
          if db_engine == 'sqlite3'
            @value = "(?i)#{@value.inspect[1..-1]}"
          else
            @value = @value.inspect[1..-1]
            @sql_operation_template = "LOWER(?field) #{SQL_OPERATOR} ?value"
          end
          @sql_operation = @sql_operation_template.sub('?field', @field).sub('?value', "#{Base.escape(@value)}")
        end

        def operator
          dbms_adapter = db_engine
          return 'REGEXP' if dbms_adapter == 'mysql'
          return '~*' if dbms_adapter == 'postgresql'
          return 'REGEXP' if dbms_adapter == 'sqlite3'
          raise "Invalid dbms #{dbms_adapter}. Only mysql, postgresql, and sqlite3 are accepted"
        end
      end

    end
  end
end