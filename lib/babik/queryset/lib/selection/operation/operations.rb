# frozen_string_literal: true

require 'babik/queryset/lib/selection/operation/base'
require 'babik/queryset/lib/selection/operation/date'
require 'babik/queryset/lib/selection/operation/regex'

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
          _init_value(value)
          super(field, '?field IN ?value', @value)
        end

        def _init_value(value)
          if value.instance_of?(Array)
            values = value.map do |value_i|
              case value_i
              when String
                self.class.escape(value_i)
              when ActiveRecord::Base
                value_i.id
              else
                value_i
              end
            end
            @value = "(#{values.join(', ')})"
          elsif value.instance_of?(Babik::QuerySet::Base)
            @value = "(#{value.sql.select})"
          elsif value.instance_of?(String)
            @value = "('#{self.class.escape(value)}')"
          else
            @value = "(#{value})"
          end
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

        # rubocop:disable Metrics/AbcSize
        def _init_sql_operation
          raise 'Array is needed if operator is between' unless @value.instance_of?(Array)
          if [@value[0], @value[1]].map { |v| [DateTime, Date, Time].include?(v.class) } == [true, true]
            value1 = "'#{@value[0].utc.to_s(:db)}'"
            value2 = "'#{@value[1].utc.to_s(:db)}'"
          else
            value1 = self.class.escape(@value[0])
            value2 = self.class.escape(@value[1])
          end
          @sql_operation = @sql_operation_template.sub('?field', @field).sub('?value1', value1).sub('?value2', value2)
        end
      end
      # rubocop:enable Metrics/AbcSize

      # "Starts with" db search: search if the value starts by a given string.
      class StartsWith < BinaryOperation
        SQL_OPERATOR = 'LIKE'
        def _init_sql_operation
          escaped_value = self.class.escape("#{@value}%")
          @sql_operation = @sql_operation_template.sub('?field', @field).sub('?value', escaped_value)
        end
      end

      # "Starts with (case search)" db operation: search if the value starts by a given string.
      class IStartsWith < StartsWith
        SQL_OPERATOR = 'ILIKE'
      end

      # "Ends with" db search: search if the value ends by a given string.
      class EndsWith < BinaryOperation
        SQL_OPERATOR = 'LIKE'
        def _init_sql_operation
          escaped_value = self.class.escape("%#{@value}")
          @sql_operation = @sql_operation.sub('?field', @field).sub('?value', escaped_value)
        end
      end

      # "Ends with (case insensitive)" db search: search if the value ends by a given string.
      class IEndsWith < StartsWith
        SQL_OPERATOR = 'ILIKE'
      end

      # String search: search if the value contains a given string.
      class Contains < BinaryOperation
        SQL_OPERATOR = 'LIKE'
        def _init_sql_operation
          escaped_value = self.class.escape("%#{@value}%")
          @sql_operation = @sql_operation_template.sub('?field', @field).sub('?value', escaped_value)
        end
      end

      # String search (case insensitive): search if the value contains a given string.
      class IContains < Contains
        SQL_OPERATOR = 'ILIKE'
      end

      # Map between operation names and operation classes.
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
        year: Year,
        quarter: Quarter,
        month: Month,
        day: Day,
        week_day: WeekDay,
        week: Week,
        hour: Hour,
        minute: Minute,
        second: Second,
        time: Babik::Selection::Operation::Time
      }.freeze
    end
  end
end
