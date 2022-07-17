# frozen_string_literal: true

require 'babik/queryset/lib/selection/select_related_selection'

module Babik
  # QuerySet module
  module QuerySet
    # Delegate object that must deals with all the select_related particularities.
    class SelectRelated
      attr_reader :model, :associations

      # Creates a new SelectRelated
      def initialize(model, selection_paths)
        @model = model
        @associations = []
        selection_paths = [selection_paths] if selection_paths.class != Array
        selection_paths.each do |selection_path|
          @associations << Babik::Selection::SelectRelatedSelection.new(@model, selection_path)
        end
      end

      # Return the joins that are needed according to the associated path
      # @return [Hash{table_alias: String}] Left joins by table alias.
      def left_joins_by_alias
        left_joins_by_alias = {}
        @associations.each do |association|
          left_joins_by_alias.merge!(association.left_joins_by_alias)
        end
        left_joins_by_alias
      end

      # Return the next object and its related objects
      # Requires a result set of the query that selects all object attributes and the rest
      # of attributes of the associated objects.
      # @param result_set [ResultSet] Result with the query that loads all the required objects
      #        (main and related ones).
      # @return [ActiveRecord::Base, Hash{selection_path: ActiveRecord::Base}]
      #         Return and object with its associated objects.
      def all_with_related(result_set)
        result_set.map do |record|
          object = instantiate_model_object(record)
          associated_objects = @associations.map do |association|
            [association.selection_path, instantiate_associated_object(record, association)]
          end
          [object, associated_objects.to_h.symbolize_keys]
        end
      end

      private

      # Construct a model object
      def instantiate_model_object(record)
        object = @model.new
        object.assign_attributes(record.select { |attribute| @model.column_names.include?(attribute) })
        object
      end

      # Construct an associated object
      def instantiate_associated_object(record, association)
        target_model = association.target_model
        target_object = target_model.new

        # First, get the attributes that have the desired prefix (the association path)
        target_attributes_with_prefix = record.select { |attr, _value| attr.start_with?("#{association.id}__") }

        # Second, convert it to a hash
        target_attributes = (target_attributes_with_prefix.map do |attribute, value|
          [attribute.split('__')[1], value]
        end).to_h

        # Last, assign it to the associated object
        target_object.assign_attributes(target_attributes)
        target_object
      end
    end
  end
end
