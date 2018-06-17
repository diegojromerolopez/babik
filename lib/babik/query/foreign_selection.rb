# frozen_string_literal: true

require_relative 'sql'

class ForeignSelection < Selection

  attr_reader :model, :selection_path, :association_path, :selected_field,
              :left_joins, :left_joins_by_alias, :sql_where_condition,
              :value, :operator,
              :sql_operator, :sql_value

  def initialize(model, selection_path, value)
    @model = model
    @value = value
    @selection_path = selection_path
    association_path = selection_path.to_s.split(RELATIONSHIP_SEPARATOR)
    selection_path = association_path.pop
    @selected_field, @operator = selection_path.split(OPERATOR_SEPARATOR)

    _initialize_association_path(association_path)
    _init_sql
  end

  def _initialize_association_path(association_path)
    @association_path = []
    associated_model_i = @model
    association_path.each do |association_i_name|
      association_i = associated_model_i.reflect_on_association(association_i_name.to_sym)
      if association_i.belongs_to? || association_i.has_one?
        @association_path << association_i
        associated_model_i = association_i.klass
      else
        # Add model-through association
        @association_path << association_i.through_reflection
        # Add through-target association
        through_target_association = association_i.active_record.reflect_on_association(association_i.source_reflection.name)
        @association_path << through_target_association
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
    @association_path.each do |association|
      left_join = SQL::Join.new("LEFT JOIN", association, last_owner_table_alias)
      @left_joins_by_alias[left_join.alias] = left_join
      @left_joins << left_join
      last_owner_table_alias = left_join.alias
    end

    #@sql_left_joins = (@left_joins.map { |left_join| left_join.sql }).join("\n")
  end

  def _init_where
    last_association = @association_path[-1]
    table_alias = "#{last_association.active_record.table_name}__#{last_association.name}"
    @sql_where_condition = "#{table_alias}.#{@selected_field} #{@sql_operator} #{@sql_value}"
  end

end