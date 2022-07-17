# frozen_string_literal: true

module Babik
  module Association
    # Association chain for association paths
    # An association chain is a chain of associations
    # where the target model of association i is the origin model of association i + 1
    # Remember, an association path is of the form: zone::parent_zone, category::posts::tags
    class ForeignAssociationChain
      attr_reader :model, :associations, :target_model, :selection_path

      # Construct the association chain
      # @param model [ActiveRecord::Base] origin model
      # @param association_path [Array] association path as an array.
      # @param selection_path [String, Symbol] selection path used only to raise errors.
      def initialize(model, association_path, selection_path)
        @model = model
        @association_path = association_path
        @selection_path = selection_path
        _init_associations
      end

      # Init associations
      def _init_associations
        @associations = []
        associated_model_i = @model
        @association_path.each do |association_i_name|
          associated_model_i = _init_association(associated_model_i, association_i_name)
        end
        @target_model = associated_model_i
      end

      # Initialize association by name
      # @param model [ActiveRecord::Base] origin model of the association association_name
      # @param association_name [String, Symbol] association name.
      # @return [ActiveRecord::Base] target model of ith association.
      def _init_association(model, association_name)
        association = _assert_association(model, association_name)
        _association_pass(association)
      end

      # Each one of the asssociation
      # @param association_i [AssociationReflection] ith association.
      # @return [ActiveRecord::Base] target model of ith association.
      def _association_pass(association_i)
        # To one relationship
        if association_i.belongs_to? || association_i.has_one?
          @associations << association_i
          return association_i.klass
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
          return through_target_association.klass
        end

        # Add direct has_many association
        @associations << association_i
        Object.const_get(association_i.class_name)
      end

      # Return an association or raise an exception if is not an allowed association
      # @return [Association] Association of model
      def _assert_association(association_model, association_name)
        association = association_model.reflect_on_association(association_name.to_sym)

        # Check the association exists
        unless association
          raise "Bad selection path: #{@selection_path}. #{association_name} not found " \
                "in model #{association_model} when filtering #{@model} objects"
        end

        # Check the association is no a has-and belongs-to-many
        # These associations are discouraged by Rails Community
        if association.instance_of?(ActiveRecord::Reflection::HasAndBelongsToManyReflection)
          raise "Relationship #{association.name} is has_and_belongs_to_many. Convert it to has_many-through"
        end

        # Valid association
        association
      end
    end
  end
end
