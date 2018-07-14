# frozen_string_literal: true

require 'babik/query/select_related_association'

module Babik
  # QuerySet module
  module QuerySet

    # Manages the projection of a SELECT QuerySet
    class Projection

      # Constructs a projection
      # @param model [ActiveRecord::Base] model the projection is based on.
      # @param *fields [Array] array of fields that will be projected.
      def initialize(model, fields)
        @fields = []
        fields.each do |field|
          @fields << ProjectedField.new(model, field)
        end
      end

      # Return sql of the fields to project.
      # Does not include SELECT.
      # @return [SQL] SQL code for fields to select in SELECT.
      def sql
        @fields.map(&:sql).join(', ')
      end
    end

    # Each one of the fields that will be returned by SELECT clause
    class ProjectedField

      # Construct a projected field from a model and its field.
      # @param model [ActiveRecord::Base] model whose field will be returned in the SELECT query.
      # @param field [Array, String] if Array, a pair or field, alias of the field.
      #                              Otherwise, a field of the local table or foreign tables.
      def initialize(model, field)
        if field.class == Array
          actual_field = field[0]
          @alias = field[1]
        else
          actual_field = field
          @alias = nil
        end
        @selection = Selection.factory(model, actual_field, '_')
      end

      # Return sql of the field to project.
      # i.e. something like this:
      #   <table_alias>.<field>
      #   <table_alias>.<field> AS <field_alias>
      # e.g.
      #   users_0.first_name
      #   posts_0.title AS post_title
      # @return [SQL] SQL code for field to appear in SELECT.
      def sql
        return "#{@selection.table_alias}.#{@selection.selected_field} AS #{@alias}" if @alias
        "#{@selection.table_alias}.#{@selection.selected_field}"
      end
    end
  end
end