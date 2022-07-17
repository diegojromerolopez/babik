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
          @sql_operation = @sql_operation_template.sub('?field', @field).sub('?value', '?')
          # Use Rails SQL escaping and avoid possible SQL-injection issues
          # and also several DB-related issues (like MySQL escaping quotes by \' instead of '')
          # Only if it has not been already replaced
          @sql_operation = ActiveRecord::Base.sanitize_sql([@sql_operation, @value]) if @sql_operation.include?('?')
        end

        # Convert the operation to string
        # @return [String] Return the replaced SQL operation.
        def to_s
          @sql_operation
        end

        # Return the database engine: sqlite3, mysql, postgres, mssql, etc.
        def db_engine
          Babik::Database.config[:adapter]
        end

        # Operation factory
        def self.factory(field, operator, value)
          # Some operators can have a secondary operator, like the year lookup that can be followed by
          # a gt, lt, equal, etc. Check this case, and get it to prepare its passing to the operation.
          raw_main_operator, secondary_operator = self.initialize_operators(operator)
          # The field, operator or value can change in some special cases, e.g. if operator is equals and the value
          # is an array, the operator should be 'in' actually.
          field, main_operator, value = self.special_cases(field, raw_main_operator, value)
          # At last, initialize operation
          self.initialize_operation(field, main_operator, secondary_operator, value)
        end

        # Inform if the operation has a operator
        # @return [Boolean] True if the operation needs an operator, false otherwise.
        def self.operator?
          self.const_defined?('HAS_OPERATOR') && self.const_get('HAS_OPERATOR')
        end

        # Initialize the operators (both main and secondary)
        # When the operator is an Array, it means it actually is two different operators. The first one will be applied
        # to the main operation, and the second one, to the lookup.
        # e.g. selector 'created_at__time__gt' contains two operators, 'time' and 'gt'.
        # @return [Array<String>] Array with both operations.
        #         First element will be the main operation, the second one will be
        #         the secondary operation. If there is no secondary operation, the second item will be nil.
        def self.initialize_operators(operator)
          secondary_operator = nil
          if operator.instance_of?(Array)
            secondary_operator = operator[1]
            operator = operator[0]
          end
          [operator, secondary_operator]
        end

        # Initialize the operation
        # @param field [String] Field name that takes part in the selection operation.
        # @param operator [Symbol] Operator name that defines which operation will be used.
        # @param secondary_operator [Symbol] Some operations have a particular operation that's it.
        # @param value [String, Integer] Value used in the selection.
        # @return [Babik::Selection::Operation::Base] A SQL selection operation.
        def self.initialize_operation(field, operator, secondary_operator, value)
          operation_class_name = Babik::Selection::Operation::CORRESPONDENCE[operator.to_sym]
          raise "Unknown lookup #{operator}" unless operation_class_name
          operation_class = Object.const_get("Babik::Selection::Operation::#{operation_class_name}")
          # If there is a secondary operator, pass it to the operation
          if secondary_operator || operation_class.operator?
            return operation_class.new(field, secondary_operator, value)
          end
          # Otherwise, return the operation
          operation_class.new(field, value)
        end

        # Special conversion of operations
        def self.special_cases(field, operator, value)
          return field, 'in', value if operator == 'equal' && [Babik::QuerySet::Base, Array].include?(value.class)
          self.date_special_cases(field, operator, value)
        end

        # Special conversion of operations for date lookup
        def self.date_special_cases(field, operator, value)
          if operator == 'date' && value.is_a?(::Date)
            return field, 'between', [value.beginning_of_day,
                                      value.end_of_day]
          end
          if operator == 'year' && value.is_a?(::Date)
            return field, 'between', [Time(value.year, 1, 1).beginning_of_day,
                                      Time(value.year, 12, 31).end_of_day]
          end
          [field, operator, value]
        end

        # Escape a string
        def self.escape(str)
          Babik::Database.escape(str)
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
