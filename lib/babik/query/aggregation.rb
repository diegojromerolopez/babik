# frozen_string_literal: true

module Babik

  class AbstractAggregation
    SQL_OPERATION = 'OVERWRITE IN CHILDREN CLASSES'
    attr_reader :model, :selection, :field_name

    def initialize(aggregation_path)
      @aggregation_path = aggregation_path
    end

    def prepare(model, field_name = nil)
      @model = model
      @selection = Selection.factory(model, @aggregation_path, '_')
      @field_name = field_name || "#{self.table_alias}__#{SQL_OPERATION.downcase}"
      self
    end

    def sql_select
      "#{self.class::SQL_OPERATION}(#{@selection.table_alias}.#{@selection.selected_field}) AS #{@field_name}"
    end

    def left_joins_by_alias
      @selection.left_joins_by_alias
    end
  end

  def self.agg(operation, aggregation_path)
    operation_class_name = operation.capitalize
    operation_class = Object.const_get("Babik::#{operation_class_name}")
    operation_class.new(aggregation_path)
  end

  class Avg < AbstractAggregation
    SQL_OPERATION = 'AVG'
  end

  class Max < AbstractAggregation
    SQL_OPERATION = 'MAX'
  end

  class Min < AbstractAggregation
    SQL_OPERATION = 'MIN'
  end

  class Sum < AbstractAggregation
    SQL_OPERATION = 'SUM'
  end
end