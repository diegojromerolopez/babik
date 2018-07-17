# frozen_string_literal: true

module Babik
  module Selection
    # SQL operation module
    module Operation
      # Base class
      class Base

        attr_reader :field, :value, :sql_operation, :sql_operation_template

        # Construct a SQL operation
        # @param field [String] Name of the field. Prefixed with the table or table alias.
        # @param sql_operation [String] Template string with the SQL code or the operation.
        #        Something like ?field = ?value.
        def initialize(field, sql_operation, value)
          @field = field
          @value = value
          @sql_operation_template = sql_operation.dup
          @sql_operation = sql_operation.dup
          _init_sql_operation
        end

        # Replace the SQL operation template and store the result in sql_operation attribute
        def _init_sql_operation
          @sql_operation = @sql_operation_template.sub('?field', @field).sub('?value', Base.escape(@value))
        end

        # Convert the operation to string
        # @return [String] Return the replaced SQL operation.
        def to_s
          @sql_operation
        end

        # Return the database engine: sqlite3, mysql, postgres, mssql, etc.
        def db_engine
          Babik::Config::Database.config[:adapter]
        end

        # Operation factory
        def self.factory(field, operator, value)
          # Some operators can have a secondary operator, like the year lookup that can be followed by
          # a gt, lt, equal, etc. Check this case, and get it to prepare its passing to the operation.
          secondary_operator = nil
          if operator.class == Array
            secondary_operator = operator[1]
            operator = operator[0]
          end
          final_field, final_operator, final_value = self.special_cases(field, operator, value)
          final_operator_class_name = Babik::Selection::Operation::CORRESPONDENCE[final_operator.to_sym]
          final_operator_class = Object.const_get("Babik::Selection::Operation::#{final_operator_class_name}")
          # If there is a secondary operator, pass it to the operation
          if secondary_operator ||
            (final_operator_class.const_defined?('HAS_OPERATOR') && final_operator_class.const_get('HAS_OPERATOR'))
            return final_operator_class.new(final_field, secondary_operator, final_value)
          end
          # Otherwise, return the operation
          final_operator_class.new(final_field, final_value)
        end

        # Special conversion of operations
        def self.special_cases(field, operator, value)
          return field, 'in', value if operator == 'equal' && value.is_a?(Babik::QuerySet::Base)
          self.date_special_cases(field, operator, value)
        end

        # Special conversion of operations for date lookup
        def self.date_special_cases(field, operator, value)
          return field, 'between', [value.beginning_of_day, value.end_of_day] if operator == 'date' && value.is_a?(::Date)
          return field, 'between', [Time(value.year, 1, 1).beginning_of_day, Time(value.year, 12, 31).end_of_day] if operator == 'year' && value.is_a?(::Date)
          [field, operator, value]
        end

        # Escape a string
        def self.escape(str)
          ActiveRecord::Base.connection.quote(str)
        end
      end

      # Binary operation
      # That's it ?field <operator> ?value
      # Most operations will have this format
      class BinaryOperation < Base
        def initialize(field, value)
          super(field, "?field #{self.class::SQL_OPERATOR} ?value", value)
        end
      end

    end
  end
end