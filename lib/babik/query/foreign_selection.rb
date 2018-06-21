# frozen_string_literal: true

require_relative 'sql'

class ForeignSelection < Selection

  attr_reader :model, :selection_path, :associations, :selected_field,
              :left_joins, :left_joins_by_alias, :sql_where_condition,
              :value, :operator,
              :sql_operator, :sql_value

  def initialize(model, selection_path, value)
    @model = model
    @value = value
    @selection_path = selection_path
    @association_path = selection_path.to_s.split(RELATIONSHIP_SEPARATOR)
    selection_path = @association_path.pop
    @selected_field, @operator = selection_path.split(OPERATOR_SEPARATOR)

    _initialize_associations
    _init_sql
  end

  def _initialize_associations
    @associations = []
    associated_model_i = @model
    @association_path.each do |association_i_name|
      association_i = associated_model_i.reflect_on_association(association_i_name.to_sym)
      if association_i.belongs_to? || association_i.has_one?
        @associations << association_i
        associated_model_i = association_i.klass
      else
        # Add model-through association
        @associations << association_i.through_reflection
        # Add through-target association
        through_target_association = association_i.active_record.reflect_on_association(association_i.source_reflection.name)
        @associations << through_target_association
        # The next association comes from target model
        associated_model_i = through_target_association.klass
      end
    end
  end

  def _init_sql
    _initialize_sql_operator
    _initialize_sql_value
    _init_left_join
    _init_where
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

  def _init_where
    last_association = @left_joins[-1]
    @sql_where_condition = "#{last_association.alias}.#{@selected_field} #{@sql_operator} #{@sql_value}"
  end

end