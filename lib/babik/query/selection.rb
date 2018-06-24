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
      @sql_operator = @value ? 'IS NULL' : 'IS NOT NULL'
    when 'lt'
      @sql_operator = '<'
    when 'lte'
      @sql_operator = '<='
    when 'gt'
      @sql_operator = '>='
    when 'gte'
      @sql_operator = '>='
    when 'between', 'date'
      @sql_operator = 'BETWEEN'
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
    if @value.class == String
      escaped_value_ = @model.sanitize_sql(@value)
    elsif @value.class == Date
      escaped_value_ = Time.parse(@value.to_s).beginning_of_day.utc.to_s(:db)
    elsif @value.class == DateTime || @value.class == Time
      escaped_value_ = @value.utc.to_s(:db)
    else
      escaped_value_ = @value
    end

    if @operator == 'date'
      @operator = 'between'
      @value = [@value.beginning_of_day, @value.end_of_day]
    end

    case @operator
    when 'startswith', 'istartswith'
      @sql_value = "'#{escaped_value_}%'"
    when 'endswith', 'iendswith'
      @sql_value = "'%#{escaped_value_}'"
    when 'contains', 'icontains'
      @sql_value = "'%#{escaped_value_}%'"
    when 'exact', 'iexact'
      @sql_value = "'#{escaped_value_}'"
    when 'between'
      if @value.class == Array
        if [@value[0], @value[1]].map { |v| v.class == DateTime || v.class == Date || v.class == Time } == [true, true]
          @sql_value = "'#{@value[0].utc.to_s(:db)}' AND '#{@value[1].utc.to_s(:db)}'"
        else
          @sql_value = "'#{@value[0]}' AND '#{@value[1]}'"
        end
      else
        raise 'Array is needed if operator is between'
      end
    when 'isnull'
      @sql_value = ''
    when 'in'
      escaped_values_ = @value.map do |in_value|
        in_value.class == String ? "'#{@model.sanitize_sql(in_value)}'" : in_value
      end
      @sql_value = "(#{escaped_values_.join(', ')})"
    else
      @sql_value = "'#{escaped_value_}'"
    end
  end

  def left_joins_by_alias
    {}
  end

end