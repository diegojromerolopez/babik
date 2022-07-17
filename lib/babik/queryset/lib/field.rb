# frozen_string_literal: true

# Common module for Babik library
module Babik
  module Table
    # Field module
    # abstracts the concept of table field according to some useful conversions
    class Field
      # Create an actual field for a model.
      # @param model [ActiveRecord::Base] model this field belongs to.
      # @param field [String] field model that could need the conversion.
      def initialize(model, field)
        @model = model
        @field = field
      end

      # Check if the field requires some conversion and if that's the case, return the converted final field
      # If the field is a name of an association, it will be converted to the foreign entity id
      # @return [String] Actual name of the field that will be used in the SQL.
      def real_field
        # If the selected field is a local attribute return the condition as-is (that's the most usual case)
        is_local_attribute = @model.column_names.include?(@field.to_s)
        return @field if is_local_attribute
        # If the selected field is the name of an association, convert it to be a right condition
        association = @model.reflect_on_association(@field.to_sym)
        # Only if the association is belongs to, the other associations will be checked by foreign filter method
        return association.foreign_key if association&.belongs_to?
        # Field that is not present in the model
        raise "Unrecognized field #{@field} for model #{@model} in filter/exclude"
      end
    end
  end
end
