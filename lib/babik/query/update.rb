# frozen_string_literal: true

# Common module for Babik library
module Babik

  # Update operation module
  module Update

    def self.sql_field(model, field)
      field = Babik::Field.new(model, field)
      field.real_field
    end

    def self.sql_value(update_field_value)
      return update_field_value.sql_value if update_field_value.is_a?(Operation) || update_field_value.is_a?(Function)
      return _escape(update_field_value) if update_field_value.is_a?(String)
      return update_field_value.id if update_field_value.is_a?(ActiveRecord::Base)
      update_field_value
    end

    def self._escape(str)
      conn = ActiveRecord::Base.connection
      conn.quote(str)
    end

    # Represents a table field. It will be used when an update field is based on its value a function an nothing else.
    # For example:
    #   UPDATE SET stars = ABS(stars)
    class Function
      def initialize(field, function_call)
        @field = field
        @function_call = function_call
      end

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

      def sql_value
        "#{@field} #{@operation} #{@value}"
      end
    end

    class Decrement < Operation
      def initialize(field, value = 1)
        super(field, '-', value)
      end
    end

    class Increment < Operation
      def initialize(field, value = 1)
        super(field, '+', value)
      end
    end

    class Multiply < Operation
      def initialize(field, value)
        super(field, '*', value)
      end
    end

    class Divide < Operation
      def initialize(field, value)
        super(field, '/', value)
      end
    end

  end

end