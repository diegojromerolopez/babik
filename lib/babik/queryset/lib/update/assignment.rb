# frozen_string_literal: true

# Common module for Babik library
module Babik
  module QuerySet
    # Update operation module
    module Update
      # Field assignment module
      module Assignment
        # Return the field prepared for the UPDATE operation.
        # Used when rendering the SQL template
        # @param model [ActiveRecord::Base] model this field belongs to.
        # @param field [String] field to be updated.
        # @return [String] Field prepared to be inserted in the left part of a SQL UPDATE assignment.
        def self.sql_field(model, field)
          field = Babik::Table::Field.new(model, field)
          field.real_field
        end

        # Return the value prepared for the UPDATE operation.
        # Used when rendering the SQL template
        # @param update_field_value [Operation, Function, String, ActiveRecord::BASE] field to be updated.
        #        if Operation, an arithmetic operation based on other field of the record will be applied (+, -, * ...)
        #        if Function, a function will be called.
        #         The parameters of the function can ben any other field of the record.
        #        if String, a escaped version of the value will be returned.
        #        if ActiveRecord::Base, the id of the object will be returned.
        #        Otherwise, the value as-is will be returned.
        # @return [String] Field prepared to be inserted in the left part of a SQL UPDATE assignment.
        def self.sql_value(update_field_value)
          return update_field_value.sql_value if update_field_value.is_a?(Operation) || update_field_value.is_a?(Function)
          return _escape(update_field_value) if update_field_value.is_a?(String)
          return update_field_value.id if update_field_value.is_a?(ActiveRecord::Base)
          update_field_value
        end

        # Escape a value for database
        # @param str [String] original string value.
        # @return [String] escaped string value.
        def self._escape(str)
          Babik::Database.escape(str)
        end

        # Represents a function operator that can be used in an UPDATE
        # For example:
        #   UPDATE SET stars = ABS(stars)
        class Function
          def initialize(field, function_call)
            @field = field
            @function_call = function_call
          end

          # Return the right part of the assignment of the UPDATE statement.
          # @return [String] right part of the assignment with the format defined by the function_call attribute.
          def sql_value
            @function_call
          end
        end

        # Represents a table field. It will be used when an update field is based on its value an nothing else.
        # For example:
        #   UPDATE SET stars = stars + 1
        class Operation
          def initialize(field, operation, value)
            @field = field
            @operation = operation
            @value = value
          end

          # Return the right part of the assignment of the UPDATE statement.
          # @return [String] right part of the assignment with the format <field> <operation> <value>.
          def sql_value
            "#{@field} #{@operation} #{@value}"
          end
        end

        # Decrement operation
        class Decrement < Operation
          def initialize(field, value = 1)
            super(field, '-', value)
          end
        end

        # Increment operation
        class Increment < Operation
          def initialize(field, value = 1)
            super(field, '+', value)
          end
        end

        # Multiplication operation
        class Multiply < Operation
          def initialize(field, value)
            super(field, '*', value)
          end
        end

        # Division operation
        class Divide < Operation
          def initialize(field, value)
            super(field, '/', value)
          end
        end

      end
    end
  end
end