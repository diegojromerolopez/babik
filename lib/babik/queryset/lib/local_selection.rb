# frozen_string_literal: true

require 'babik/queryset/lib/selection'

class LocalSelection < Selection

  attr_reader :model, :selection_path, :selected_field, :operator, :value, :sql_operator, :sql_value

  def initialize(model, selection_path, value)
    super
    @selected_field, @operator = @selection_path.to_s.split(OPERATOR_SEPARATOR)
    _initialize_sql_operator
    _initialize_sql_value
  end

  def sql_where_condition
    field = Babik::Field.new(model, @selected_field)
    actual_field = field.real_field
    sql_value = @sql_value
    # Only if the real field is an association and the value is an ActiveRecord,
    # then the real value is that ActiveRecord id
    sql_value = @sql_value.id if actual_field != @selected_field && @sql_value.is_a?(ActiveRecord::Base)
    # If the value is a QuerySet, include the SQL code
    sql_value = "(#{@sql_value.select_sql})" if @sql_value.class == Babik::QuerySet::Base
    # Return the condition
    "#{self.target_alias}.#{actual_field} #{@sql_operator} #{sql_value}"
  end

  def target_alias
    @model.table_name
  end

end