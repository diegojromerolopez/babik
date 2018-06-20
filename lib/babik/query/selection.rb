# frozen_string_literal: true

class Selection
  RELATIONSHIP_SEPARATOR = '::'
  OPERATOR_SEPARATOR = '__'

  def self.factory(model, selection_path, value)
    @model = model
    if selection_path.match?(RELATIONSHIP_SEPARATOR)
      return ForeignSelection.new(model, selection_path, value)
    end
    LocalSelection.new(model, selection_path, value)
  end

  def _initialize_sql_operator
    # TODO: startswith, endswith, between, contains, icontains, jsonb operators
    case @operator
    when 'equal'
      @sql_operator = '='
    when 'different'
      @sql_operator = '<>'
    when 'in'
      @sql_operator = 'IN'
    when 'isnull'
      @sql_operator = 'IS NULL'
    when 'isnotnull'
      @sql_operator = 'IS NOT NULL'
    when 'lt'
      @sql_operator = '<'
    when 'lte'
      @sql_operator = '<='
    when 'gt'
      @sql_operator = '>='
    when 'gte'
      @sql_operator = '>='
    when 'startswith', 'endswith', 'contains', 'exact'
      @sql_operator = 'LIKE'
    when 'istartswith', 'iendswith', 'icontains', 'iexact'
      @sql_operator = 'ILIKE'
    else
      @operator = 'equal'
      @sql_operator = '='
    end
  end

  def _initialize_sql_value
    if @value.class != String
      @sql_value = @value
      return
    end
    escaped_value_ = @model.sanitize_sql(@value)
    case @operator
    when 'startswith', 'istartswith'
      @sql_value = "'#{escaped_value_}%'"
    when 'endswith', 'iendswith'
      @sql_value = "'%#{escaped_value_}'"
    when 'contains', 'icontains'
      @sql_value = "'%#{escaped_value_}%'"
    when 'exact', 'iexact'
      @sql_value = "'#{escaped_value_}'"
    else
      @sql_value = "'#{escaped_value_}'"
    end
  end
end