# frozen_string_literal: true

require 'babik/queryset/lib/selection/selection'
require 'babik/queryset/lib/selection/operation'
require 'babik/queryset/lib/join/association_joiner'

module Babik
  module Selection
    # Foreign selection
    class ForeignSelection < Babik::Selection::Base
      RELATIONSHIP_SEPARATOR = '::'
      OPERATOR_SEPARATOR = '__'

      attr_reader :model, :selection_path, :associations, :selected_field,
                  :sql_where_condition,
                  :value, :operator

      delegate :left_joins_by_alias, to: :@association_joiner
      delegate :target_alias, to: :@association_joiner

      def initialize(model, selection_path, value)
        super
        @selection_path = selection_path.dup
        @association_path = selection_path.to_s.split(RELATIONSHIP_SEPARATOR)
        selection_path = @association_path.pop
        @selected_field, @operator = selection_path.split(OPERATOR_SEPARATOR)
        @operator ||= 'equal'
        # If the value is an ActiveRecord model, get its id
        if @value.is_a?(ActiveRecord::Base)
          @value = @value.id
          # In case the selected field is not a local field,
          # assume it is a foreign association, so it must have the suffix id
          @selected_field += '_id' unless model.has_attribute?(@selected_field.to_sym)
        end
        _initialize_associations
        _initialize_association_joins
        _init_sql_where_condition
      end

      def _initialize_associations
        @associations = []
        associated_model_i = @model
        @association_path.each do |association_i_name|
          associated_model_i = _init_association(associated_model_i, association_i_name)
        end
      end

      def _init_association(model_i, association_i_name)
        association_i = _construct_association(model_i, association_i_name)

        # To one relationship
        if association_i.belongs_to? || association_i.has_one?
          @associations << association_i
          model_i = association_i.klass
          return model_i
        end

        # Many-to-many with through relationship
        # The has-and-belongs-to-many relationships have been detected and filtered in _construct_association

        # Add model-through association (active_record -> klass)
        if association_i.through_reflection
          @associations << association_i.through_reflection
          # Add through-target association (through -> target)
          target_name = association_i.source_reflection_name
          through_model = association_i.through_reflection.klass
          through_target_association = through_model.reflect_on_association(target_name)
          @associations << through_target_association
          # The next association comes from target model
          model_i = through_target_association.klass
          return model_i
        end

        # Add direct has_many association
        @associations << association_i
        target_class = Object.const_get(association_i.class_name)
        # The next association comes from target model
        target_class
      end

      def _construct_association(association_model, association_name)
        association = association_model.reflect_on_association(association_name.to_sym)

        # Check the association exists
        unless association
          raise "Bad selection path: #{@selection_path}. #{association_name} not found " \
                  "in model #{association_model} when filtering #{@model} objects"
        end

        # Check the association is no a has-and belongs-to-many
        # These associations are discouraged by Rails Community
        if association.class == ActiveRecord::Reflection::HasAndBelongsToManyReflection
          raise "Relationship #{association.name} is has_and_belongs_to_many. Convert it to has_many-through"
        end

        # Valid association
        association
      end

      def _initialize_association_joins
        @association_joiner = Babik::QuerySet::Join::AssociationJoiner.new(@associations)
      end

      def _init_sql_where_condition
        @sql_where_condition = Babik::Selection::Operation::Base.factory(
          "#{target_alias}.#{@selected_field}", @operator, @value
        )
      end
    end

  end
end