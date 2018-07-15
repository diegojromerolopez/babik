# frozen_string_literal: true

require 'babik/queryset/lib/selection'
require 'babik/queryset/lib/association_joiner'

class ForeignSelection < Selection

  attr_reader :model, :selection_path, :associations, :selected_field,
              :sql_where_condition,
              :value, :operator,
              :sql_operator, :sql_value

  delegate :left_joins_by_alias, to: :@association_joiner
  delegate :target_alias, to: :@association_joiner

  def initialize(model, selection_path, value)
    super
    @association_path = selection_path.to_s.split(RELATIONSHIP_SEPARATOR)
    selection_path = @association_path.pop
    @selected_field, @operator = selection_path.split(OPERATOR_SEPARATOR)

    _initialize_associations
    _initialize_association_joins
    _init_sql
  end

  def _initialize_associations
    @associations = []
    associated_model_i = @model
    @association_path.each do |association_i_name|
      association_i = associated_model_i.reflect_on_association(association_i_name.to_sym)
      unless association_i
        raise "Bad selection path: #{selection_path}. #{association_i_name} not found " \
              "in model #{associated_model_i} when filtering #{@model} objects"
      end

      # To one relationship
      if association_i.belongs_to? || association_i.has_one?
        @associations << association_i
        associated_model_i = association_i.klass
      # Classic many-to-many relationship
      elsif association_i.class == ActiveRecord::Reflection::HasAndBelongsToManyReflection
        raise "Relationship #{association_i.name} is has_and_belongs_to_many. Convert it to has_many-through"
      # Many-to-many with through relationship
      else
        # Add model-through association (active_record -> klass)
        if association_i.through_reflection
          @associations << association_i.through_reflection
          # Add through-target association (through -> target)
          target_name = association_i.source_reflection_name
          through_model = association_i.through_reflection.klass
          through_target_association = through_model.reflect_on_association(target_name)
          @associations << through_target_association
          # The next association comes from target model
          associated_model_i = through_target_association.klass
        # Add direct has_many association
        else
          @associations << association_i
          target_class = Object.const_get(association_i.class_name)
          # The next association comes from target model
          associated_model_i = target_class
        end
      end
    end
  end

  def _init_sql
    _initialize_sql_operator
    _initialize_sql_value
    _init_where
  end

  def _initialize_association_joins
    @association_joiner = Babik::QuerySet::AssociationJoiner.new(@associations)
  end

  def _init_where
    @sql_where_condition = "#{target_alias}.#{@selected_field} #{@sql_operator} #{@sql_value}"
  end

end