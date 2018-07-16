# frozen_string_literal: true

module Babik
  module Selection
    module Operation

      class Base
        def initialize(field, sql_operation, value)
          @field = field
          @value = value
          @sql_operation_template = sql_operation.dup
          @sql_operation = sql_operation.dup
          _init_sql_operation
        end

        def _init_sql_operation
          @sql_operation = @sql_operation_template.sub('?field', @field).sub('?value', Base.escape(@value))
        end

        def to_s
          @sql_operation
        end

        def db_engine
          Babik::Config::Database.config[:adapter]
        end

        def self.factory(field, operator, value)
          final_field, final_operator, final_value = self.special_cases(field, operator, value)
          final_operator_class_name = Babik::Selection::Operation::CORRESPONDENCE[final_operator.to_sym]
          final_operator_class = Object.const_get("Babik::Selection::Operation::#{final_operator_class_name}")
          final_operator_class.new(final_field, final_value)
        end

        def self.special_cases(field, operator, value)
          return field, 'equal', value.id if operator == 'equal' && value.is_a?(ActiveRecord::Base)
          return field, 'between', [value.beginning_of_day, value.end_of_day] if operator == 'date' && value.is_a?(::Date)
          return field, 'in', value if operator == 'equal' && value.is_a?(Babik::QuerySet::Base)
          [field, operator, value]
        end

        def self.escape(str)
          ActiveRecord::Base.connection.quote(str)
        end
      end

      class BinaryOperator < Base
        def initialize(field, value)
          super(field, "?field #{self.class::SQL_OPERATOR} ?value", value)
        end
      end

      class Different < BinaryOperator
        SQL_OPERATOR = '<>'
      end

      class OperatorIfNotNull < Base
        SQL_OPERATOR = '='
        def initialize(field, value)
          if value.nil?
            super(field, '?field IS NULL', value)
          else
            super(field, "?field #{SQL_OPERATOR} ?value", value)
          end
        end
      end

      class Equal < OperatorIfNotNull
        SQL_OPERATOR = '='
      end

      class Exact < OperatorIfNotNull
        SQL_OPERATOR = 'LIKE'
      end

      class IExact < Exact
        SQL_OPERATOR = 'ILIKE'
      end

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

      class IsNull < Base
        def initialize(field, value)
          sql_operation = value ? '?field IS NULL' : '?field IS NOT NULL'
          super(field, sql_operation, value)
        end
      end

      class LessThan < BinaryOperator
        SQL_OPERATOR = '<'
      end

      class LessThanOrEqual < BinaryOperator
        SQL_OPERATOR = '<='
      end

      class GreaterThan < BinaryOperator
        SQL_OPERATOR = '>'
      end

      class GreaterThanOrEqual < BinaryOperator
        SQL_OPERATOR = '>='
      end

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

      class StartsWith < BinaryOperator
        SQL_OPERATOR = 'LIKE'
        def _init_sql_operation
          escaped_value = self.class.escape("#{@value}%")
          @sql_operation = @sql_operation_template.sub('?field', @field).sub('?value', escaped_value)
        end
      end

      class IStartsWith < StartsWith
        SQL_OPERATOR = 'ILIKE'
      end

      class EndsWith < BinaryOperator
        SQL_OPERATOR = 'LIKE'
        def _init_sql_operation
          escaped_value = self.class.escape("%#{@value}")
          @sql_operation = @sql_operation.sub('?field', @field).sub('?value', escaped_value)
        end
      end

      class IEndsWith < StartsWith
        SQL_OPERATOR = 'ILIKE'
      end

      class Contains < BinaryOperator
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
        iregex: IRegex
      }.freeze

    end
  end
end