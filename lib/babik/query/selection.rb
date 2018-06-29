# frozen_string_literal: true

class Selection
  RELATIONSHIP_SEPARATOR = '::'
  OPERATOR_SEPARATOR = '__'

  def self.factory(model, selection_path, value)
    if selection_path.match?(RELATIONSHIP_SEPARATOR)
      return ForeignSelection.new(model, selection_path, value)
    end
    LocalSelection.new(model, selection_path, value)
  end

  def initialize(model, selection_path, value)
    @model = model
    @selection_path = selection_path
    @value = value
    @db_conf = ActiveRecord::Base.connection_config
  end

  def _initialize_sql_operator
    # TODO: startswith, endswith, between, contains, icontains, jsonb operators
    case @operator
    when 'equal', 'equals_to'
      @sql_operator = '='
    when 'exact', 'iexact'
      if @value.nil?
        @sql_operator = 'IS NULL'
      else
        @sql_operator = 'LIKE' if @operator == 'exact'
        @sql_operator = 'ILIKE' if @operator == 'iexact'
      end
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
      @sql_operator = '>'
    when 'gte'
      @sql_operator = '>='
    when 'between', 'range', 'date'
      @sql_operator = 'BETWEEN'
    when 'startswith', 'endswith', 'contains'
      @sql_operator = 'LIKE'
    when 'istartswith', 'iendswith', 'icontains'
      @sql_operator = 'ILIKE'
    when 'regex'
      @sql_operator = regex
    when 'iregex'
      @sql_operator = iregex
    else
      @operator = 'equal'
      @sql_operator = '='
    end
  end

  def _initialize_sql_value
    if @value.class == String
      escaped_value_ = _escape(@value)
    elsif @value.class == Date
      escaped_value_ = "'#{Time.parse(@value.to_s).beginning_of_day.utc.to_s(:db)}'"
    elsif @value.class == DateTime || @value.class == Time
      escaped_value_ = "'#{@value.utc.to_s(:db)}'"
    else
      escaped_value_ = @value
    end

    if @operator == 'date'
      @operator = 'between'
      @value = [@value.beginning_of_day, @value.end_of_day]
    end

    case @operator
    when 'startswith', 'istartswith'
      @sql_value = "'#{@model.sanitize_sql_like(@value)}%'"
    when 'endswith', 'iendswith'
      @sql_value = "'%#{@model.sanitize_sql_like(@value)}'"
    when 'contains', 'icontains'
      @sql_value = "'%#{@model.sanitize_sql_like(@value)}%'"
    when 'exact', 'iexact'
      if @value.nil?
        @sql_value = ''
      else
        @sql_value = escaped_value_
      end
    when 'between', 'range'
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
    when 'regex'
      @sql_value = regex_value
    when 'iregex'
      @sql_value = iregex_value
    else
      @sql_value = escaped_value_
    end
  end

  def _escape(str)
    conn = ActiveRecord::Base.connection
    conn.quote(str)
  end

  def left_joins_by_alias
    {}
  end

  def regex
    dbms_adapter = @db_conf[:adapter]
    if dbms_adapter == 'mysql'
      return 'REGEXP BINARY'
    end
    if dbms_adapter == 'postgresql'
      return '~'
    end
    if dbms_adapter == 'sqlite3'
      return 'REGEXP'
    end
    raise "Invalid dbms #{dbms_adapter}. Only mysql, postgresql, and sqlite3 are accpeted"
  end

  def iregex
    dbms_adapter = @db_conf[:adapter]
    if dbms_adapter == 'mysql'
      return 'REGEXP'
    end
    if dbms_adapter == 'postgresql'
      return '~*'
    end
    if dbms_adapter == 'sqlite3'
      return 'REGEXP'
    end
    raise "Invalid dbms #{dbms}. Only mysql, postgresql, and sqlite3 are accpeted"
  end

  def regex_value
    _escape(@value.inspect[1..-1])
  end

  def iregex_value
    dbms_adapter = @db_conf[:adapter]
    if dbms_adapter == 'sqlite3'
      return _escape("(?i)#{@value.inspect[1..-1]}")
    end
    regex_value
  end

end