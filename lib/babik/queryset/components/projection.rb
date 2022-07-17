# frozen_string_literal: true

require 'babik/queryset/lib/selection/path/path'

module Babik
  # QuerySet module
  module QuerySet

    # Manages the projection of a SELECT QuerySet
    class Projection

      # Constructs a projection
      # @param model [ActiveRecord::Base] model the projection is based on.
      # @param fields [Array] array of fields that will be projected.
      def initialize(model, fields)
        @fields = []
        @fields_hash = {}
        fields.each do |field|
          new_field = ProjectedField.new(model, field)
          @fields << new_field
          @fields_hash[new_field.alias.to_sym] = new_field
        end
      end

      def apply_transforms(result_set)
        result_set.map do |record|
          record.symbolize_keys!
          transformed_record = {}
          record.each do |field, value|
            transform = @fields_hash[field].transform
            transformed_record[field] = if transform
                                          transform.call(value)
                                        else
                                          value
                                        end
          end
          transformed_record
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
      attr_reader :model, :alias, :transform, :selection

      # Construct a projected field from a model and its field.
      # @param model [ActiveRecord::Base] model whose field will be returned in the SELECT query.
      # @param field [Array, String]
      #   if Array, it must be [field_name, alias, transform] where
      #   - field_name is the name of the field (the column name). It is mandatory and must be the first
      #   item of the array.
      #   - alias if present, it will be used to name the field instead of its name.
      #   - transform, if present, a lambda function with the transformation each value of that column it must suffer.
      # e.g.:
      #   [:created_at, :birth_date]
      #   [:stars, ->(stars) { [stars, 5].min } ]
      #   Otherwise, a field of the local table or foreign tables.
      #
      def initialize(model, field)
        @model = model
        method_name = "initialize_from_#{field.class.to_s.downcase}"
        unless self.respond_to?(method_name)
          raise "No other parameter type is permitted in #{self.class}.new than Array, String and Symbol."
        end
        self.send(method_name, field)
        @selection = Babik::Selection::Path::Factory.build(model, @name)
      end

      # Initialize from Array
      def initialize_from_array(field)
        @name = field[0]
        @alias = @name
        [1, 2].each do |field_index|
          next unless field[field_index]
          field_i = field[field_index]
          if [Symbol, String].include?(field_i.class)
            @alias = field_i
          elsif field_i.class == Proc
            @transform = field_i
          else
            raise "#{self.class}.new only accepts String/Symbol or Proc. Passed a #{field_i.class}."
          end
        end
      end

      # Initialize from String
      def initialize_from_string(field)
        @name = field.to_sym
        @alias = field.to_sym
        @transform = nil
      end

      # Initialize from Symbol
      def initialize_from_symbol(field)
        initialize_from_string(field)
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
        "#{@selection.target_alias}.#{@selection.selected_field} AS #{@alias}"
      end
    end
  end
end
