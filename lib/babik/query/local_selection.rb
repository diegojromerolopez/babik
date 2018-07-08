# frozen_string_literal: true

require_relative 'selection'

class LocalSelection < Selection

  attr_reader :model, :selection_path, :selected_field, :operator, :value, :sql_operator, :sql_value

  def initialize(model, selection_path, value)
    super
    @selected_field, @operator = @selection_path.to_s.split(OPERATOR_SEPARATOR)
    _initialize_sql_operator
    _initialize_sql_value
  end

  def sql_where_condition
    # If the selected field is a local attribute return the condition as-is (that's the most usual case)
    is_local_attribute = @model.column_names.include?(@selected_field)
    return "#{self.table_alias}.#{@selected_field} #{@sql_operator} #{@sql_value}" if is_local_attribute
    # If the selected field is the name of an association, convert it to be a right condition
    association = @model.reflect_on_association(@selected_field.to_sym)
    # Only if the association is belongs to, the other associations will be checked by foreign filter method
    if association && true && association.belongs_to?
      selected_field = association.foreign_key
      sql_value = if @sql_value.class == association.klass
                    @sql_value.id
                  else
                    @sql_value
                  end
      return "#{self.table_alias}.#{selected_field} #{@sql_operator} #{sql_value}"
    end
    raise "Unrecognized field #{@selected_field} for model #{@model} in filter/exclude"
  end

  def table_alias
    @model.table_name
  end

end