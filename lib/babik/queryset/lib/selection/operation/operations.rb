# frozen_string_literal: true

require 'babik/queryset/lib/selection/operation/base'

module Babik
  module Selection
    # SQL operation module
    module Operation

      # When two values are not equal
      class Different < BinaryOperation
        SQL_OPERATOR = '<>'
      end

      # Operations that in case a nil is passed will convert the equality comparison to IS NULL
      class IfNotNullOperation < Base
        SQL_OPERATOR = '='
        def initialize(field, value)
          if value.nil?
            super(field, '?field IS NULL', value)
          else
            super(field, "?field #{SQL_OPERATOR} ?value", value)
          end
        end
      end

      # Equal operation
      class Equal < IfNotNullOperation
        SQL_OPERATOR = '='
      end

      # Exact operation
      class Exact < IfNotNullOperation
        SQL_OPERATOR = 'LIKE'
      end

      # Exact case-insensitive operation
      class IExact < Exact
        SQL_OPERATOR = 'ILIKE'
      end

      # IN operation
      class In < Base
        def initialize(field, value)
          if value.class == Array
            values = value.map do |value_i|
              value_i.class == String ? self.class.escape(value_i) : value_i
            end
            @value = "(#{values.join(', ')})"
          elsif value.class == Babik::QuerySet::Base
            @value = "(#{value.sql.select})"
          elsif value.class == String
            @value = "('#{self.class.escape(value)}')"
          else
            @value = "(#{value})"
          end
          super(field, '?field IN ?value', @value)
        end

        def _init_sql_operation
          @sql_operation = @sql_operation_template.sub('?field', @field).sub('?value', @value)
        end
      end

      # IS NULL operation
      class IsNull < Base
        def initialize(field, value)
          sql_operation = value ? '?field IS NULL' : '?field IS NOT NULL'
          super(field, sql_operation, value)
        end
      end

      # Less than comparison
      class LessThan < BinaryOperation
        SQL_OPERATOR = '<'
      end

      # Less than or equal comparison
      class LessThanOrEqual < BinaryOperation
        SQL_OPERATOR = '<='
      end

      # Greater than comparison
      class GreaterThan < BinaryOperation
        SQL_OPERATOR = '>'
      end

      # Greater than or equal comparison
      class GreaterThanOrEqual < BinaryOperation
        SQL_OPERATOR = '>='
      end

      # Between comparison (check the value is between two different values)
      class Between < Base
        def initialize(field, value)
          super(field, '?field BETWEEN ?value1 AND ?value2', value)
        end

        def _init_sql_operation
          if @value.class == Array
            if [@value[0], @value[1]].map { |v| v.class == DateTime || v.class == Date || v.class == Time } == [true, true]
              value1 = "'#{@value[0].utc.to_s(:db)}'"
              value2 = "'#{@value[1].utc.to_s(:db)}'"
            else
              value1 = self.class.escape(@value[0])
              value2 = self.class.escape(@value[1])
            end
            @sql_operation = @sql_operation_template.sub('?field', @field).sub('?value1', value1).sub('?value2', value2)
          else
            raise 'Array is needed if operator is between'
          end
        end
      end

      class StartsWith < BinaryOperation
        SQL_OPERATOR = 'LIKE'
        def _init_sql_operation
          escaped_value = self.class.escape("#{@value}%")
          @sql_operation = @sql_operation_template.sub('?field', @field).sub('?value', escaped_value)
        end
      end

      class IStartsWith < StartsWith
        SQL_OPERATOR = 'ILIKE'
      end

      class EndsWith < BinaryOperation
        SQL_OPERATOR = 'LIKE'
        def _init_sql_operation
          escaped_value = self.class.escape("%#{@value}")
          @sql_operation = @sql_operation.sub('?field', @field).sub('?value', escaped_value)
        end
      end

      class IEndsWith < StartsWith
        SQL_OPERATOR = 'ILIKE'
      end

      class Contains < BinaryOperation
        SQL_OPERATOR = 'LIKE'
        def _init_sql_operation
          escaped_value = self.class.escape("%#{@value}%")
          @sql_operation = @sql_operation_template.sub('?field', @field).sub('?value', escaped_value)
        end
      end

      class IContains < Contains
        SQL_OPERATOR = 'ILIKE'
      end

      class Regex < Base
        def initialize(field, value)
          value = value.inspect[1..-1]
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

      class Year < DateOperation
        def sql_function
          dbms_adapter = db_engine
          return 'EXTRACT(YEAR FROM ?field)' if %w[mysql postgresql].include?(dbms_adapter)
          return 'strftime(\'%Y\', ?field)' if dbms_adapter == 'sqlite3'
          raise "Invalid dbms #{dbms_adapter}. Only mysql, postgresql, and sqlite3 are accepted"
        end
      end

      class Month < DateOperation
        def initialize(field, operator, value)
          value = '%02d' % value if db_engine == 'sqlite3'
          super(field, operator, value)
        end

        def sql_function
          dbms_adapter = db_engine
          return 'EXTRACT(MONTH FROM ?field)' if %w[mysql postgresql].include?(dbms_adapter)
          return 'strftime(\'%m\', ?field)' if dbms_adapter == 'sqlite3'
          raise "Invalid dbms #{dbms_adapter}. Only mysql, postgresql, and sqlite3 are accepted"
        end
      end

      class Day < DateOperation
        def initialize(field, operator, value)
          value = '%02d' % value if db_engine == 'sqlite3'
          super(field, operator, value)
        end

        def sql_function
          dbms_adapter = db_engine
          return 'EXTRACT(DAY FROM ?field)' if %w[mysql postgresql].include?(dbms_adapter)
          return 'strftime(\'%d\', ?field)' if dbms_adapter == 'sqlite3'
          raise "Invalid dbms #{dbms_adapter}. Only mysql, postgresql, and sqlite3 are accepted"
        end
      end

      CORRESPONDENCE = {
        default: Equal,
        equal: Equal,
        equals: Equal,
        equals_to: Equal,
        exact: Exact,
        iexact: IExact,
        different: Different,
        in: In,
        isnull: IsNull,
        lt: LessThan,
        lte: LessThanOrEqual,
        gt: GreaterThan,
        gte: GreaterThanOrEqual,
        between: Between,
        range: Between,
        startswith: StartsWith,
        endswith: EndsWith,
        contains: Contains,
        istartswith: IStartsWith,
        iendswith: IEndsWith,
        icontains: IContains,
        regex: Babik::Selection::Operation::Regex,
        iregex: IRegex,
        month: Month,
        day: Day,
        year: Year
      }.freeze

    end
  end
end