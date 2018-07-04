# frozen_string_literal: true

require_relative 'query/aggregation'
require_relative 'query/conjunction'
require_relative 'query/local_selection'
require_relative 'query/foreign_selection'

# Represents a new type of query result set
class QuerySet
  include Enumerable
  attr_reader :model, :is_count, :has_distinct, :number_of_rows_limit, :offset, :order, :lock_type, :projection,
              :inclusion_filters, :exclusion_filters, :aggregations

  def initialize(model_class)
    @model = model_class
    @is_count = false
    @has_distinct = false
    @number_of_rows_limit = nil
    @offset = nil
    @order = nil
    @order_selections = []
    @lock_type = nil
    @inclusion_filters = []
    @exclusion_filters = []
    @aggregations = []
    @projection = false
  end

  def aggregate(aggregations)
    aggregations.each do |aggregation_field_name, aggregation|
      @aggregations << aggregation.prepare(@model, aggregation_field_name)
    end
    ActiveRecord::Base.connection.exec_query(self.sql).first.symbolize_keys
  end

  # Exclude objects according to some criteria.
  def exclude(filters)
    _filter(filters, @exclusion_filters)
  end

  # Select objects according to some criteria.
  def filter(filters)
    _filter(filters, @inclusion_filters)
  end

  # Select the objects according to some criteria.
  def _filter(filters, applied_filters)
    if filters.class == Array
      disjunctions = filters.map do |filter|
        Conjunction.new(@model, filter)
      end
      applied_filters << disjunctions
    elsif filters.class == Hash
      applied_filters << Conjunction.new(@model, filters)
    end
    self
  end

  def all
    return ActiveRecord::Base.connection.exec_query(self.sql) if self.projection
    @model.find_by_sql(self.sql)
  end

  def first
    self.all.first
  end

  def each(&block)
    self.all.each(&block)
  end

  def get(filters)
    result_ = self.filter(filters).all
    result_count = result_.count
    raise 'Does not exist' if result_count.zero?
    raise 'Multiple objects returned' if result_count > 1
    result_.first
  end

  # Return an empty ActiveRecord ResultSet
  def none
    @model.find_by_sql("SELECT * FROM #{@model.table_name} WHERE 1 = 0")
  end

  def project(*params)
    @projection = params
    self
  end

  def empty?
    self.count.zero?
  end

  def exists?
    self.count.positive?
  end

  def length
    self.count
  end

  def size
    self.count
  end

  def count
    self.all.count
  end

  def distinct
    @has_distinct = true
    self
  end

  def order_by(*order_by_list)
    @order = order_by_list
    @order_selections = []
    # Check the types of each order field
    @order = @order.map do |order|
      if order.class == String
        [order, :ASC]
      elsif order.class == Array
        unless %i[ASC DES].include?(order[1].to_sym)
          raise "Invalid order type for #{self.class}.order_by: order_by_list. Expecting an array [<field>: :ASC|:DESC]"
        end
        order
      elsif order.class == Hash
        if order.keys.length > 1
          raise "More than one key found in order by for class #{self.class}"
        end
        order_field = order.keys[0]
        order_value = order[order_field]
        [order_field, order_value]
      else
        raise "Invalid value for #{self.class}.order_by: order_by_list. Expecting an array [<field>: :ASC|:DESC]"
      end
    end
    @order.each_with_index do |order_field, _order_field_index|
      order_path = order_field[0]
      @order_selections << Selection.factory(model, order_path, '_')
    end
    self
  end

  def for_update
    @lock_type = 'FOR UPDATE'
    self
  end

  def lock
    self.for_update
  end

  def fetch(index, default_value = nil)
    element = self.[](index)
    if element
      return element
    end
    if default_value
      return default_value
    end
    raise IndexError, "Index #{index} outside of QuerySet bounds"
  end

  def [](param)
    # Section selection
    if param.class == Range
      offset_ = param.min
      size_ = param.max.to_i - param.min.to_i
      return limit(size: size_, offset: offset_)
    end

    # Element selection
    if param.class == Integer
      return limit(size: 1, offset: param).first
    end

    raise "Invalid limit passed to query: #{param}"
  end

  def limit(size: nil, offset: 0)
    @offset = offset.to_i
    @number_of_rows_limit = size.to_i
    self
  end

  def sql
    _render_select_sql
  end

  def _sql_left_joins
    left_joins_by_alias = {}
    @inclusion_filters.flatten.each do |conjunction|
      left_joins_by_alias.merge!(conjunction.left_joins_by_alias)
    end
    @exclusion_filters.flatten.each do |conjunction|
      left_joins_by_alias.merge!(conjunction.left_joins_by_alias)
    end
    # FIXME: order selection should be a class with common parts with selection
    @order_selections.each do |order_selection|
      left_joins_by_alias.merge!(order_selection.left_joins_by_alias)
    end
    # Merge aggregation
    @aggregations.each do |aggregation|
      left_joins_by_alias.merge!(aggregation.left_joins_by_alias)
    end
    # Join all left joins and return a string with the SQL code
    left_joins_by_alias.values.map(&:sql).join("\n")
  end

  def _render_select_sql
    self._render_sql("#{__dir__}/templates/default/select/main.sql.erb")
  end

  def _render_sql(template_path)
    template_content = File.read(template_path)
    ERB.new(template_content).result_with_hash(queryset: self)
  end

end