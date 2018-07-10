# frozen_string_literal: true

require_relative 'sql'

class SelectRelatedAssociation
  RELATIONSHIP_SEPARATOR = '::'
  attr_reader :model, :association_path, :associations, :left_joins, :left_joins_by_alias, :target_model, :id

  def initialize(model, association_path)
    @model = model
    @association_path = association_path
    @association_path_parts = association_path.to_s.split(RELATIONSHIP_SEPARATOR)
    @id = @association_path_parts.join('__')
    @target_model = nil

    _initialize_associations
    _init_left_join
  end

  def _initialize_associations
    @associations = []
    associated_model_i = @model
    @association_path_parts.each do |association_i_name|
      association_i = associated_model_i.reflect_on_association(association_i_name.to_sym)
      unless association_i
        raise "Bad association path: #{association_i_name} not found " \
              "in model #{associated_model_i} when constructing select_related for #{@model} objects"
      end

      # To one relationship
      if association_i.belongs_to? || association_i.has_one?
        @associations << association_i
        associated_model_i = association_i.klass
        @target_model = associated_model_i
      else
        raise "Bad association path: #{association_i_name} in model #{associated_model_i} " \
              "is not belongs_to or has_one when constructing select_related for #{@model} objects"
      end
    end
  end

  def _init_left_join
    @left_joins = []
    @left_joins_by_alias = {}
    last_owner_table_alias = nil
    @associations.each_with_index do |association, association_path_index|
      left_join = SQL::Join.new("LEFT JOIN", association, association_path_index, last_owner_table_alias)
      @left_joins_by_alias[left_join.alias] = left_join
      @left_joins << left_join
      last_owner_table_alias = left_join.alias
    end
  end

  def target_alias
    @left_joins[-1].alias
  end
end