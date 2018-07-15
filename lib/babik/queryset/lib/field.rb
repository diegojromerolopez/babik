# frozen_string_literal: true

# Common module for Babik library
module Babik
  module Table
    # Field module
    # abstracts the concept of table field according to some useful conversions
    class Field

      def initialize(model, field)
        @model = model
        @field = field
      end

      def real_field
        # If the selected field is a local attribute return the condition as-is (that's the most usual case)
        is_local_attribute = @model.column_names.include?(@field.to_s)
        return @field if is_local_attribute
        # If the selected field is the name of an association, convert it to be a right condition
        association = @model.reflect_on_association(@field.to_sym)
        # Only if the association is belongs to, the other associations will be checked by foreign filter method
        return association.foreign_key if association && association.belongs_to?
        # Field that is not present in the model
        raise "Unrecognized field #{@field} for model #{@model} in filter/exclude"
      end
    end
  end
end