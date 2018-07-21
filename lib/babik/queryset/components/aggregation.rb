# frozen_string_literal: true

# Common module for Babik library
module Babik
  # QuerySet module
  module QuerySet
    # A set of aggregation operations
    class Aggregation

      attr_reader :model, :functions

      # Construct a new aggregation
      # @param model [Class] class that inherits from ActiveRecord::Base.
      # @param functions [Array<Avg, Max, Min, Sum>] array of aggregation functions.
      def initialize(model, functions)
        @model = model
        @functions = []
        functions.each do |field_name, function|
          @functions << function.prepare(@model, field_name)
        end
      end

      # Return the joins grouped by alias
      # @return [Hash{alias: Babik::QuerySet::Join}] Hash where the value is the alias of the table and the value is a Babik::Join
      def left_joins_by_alias
        left_joins_by_alias = {}
        @functions.each do |function|
          left_joins_by_alias.merge!(function.left_joins_by_alias)
        end
        left_joins_by_alias
      end

      # Return aggregation SQL
      # @return [String] Aggregation SQL
      def sql
        @functions.map(&:sql).join(', ')
      end
    end

    # Abstract aggregation function. Do not use
    class AbstractAggregationFunction
      SQL_OPERATION = 'OVERWRITE IN CHILDREN CLASSES'
      attr_reader :model, :selection, :field_name

      # Construct a aggregation function for a field
      # @param aggregation_path [String] Field or foreign field path.
      def initialize(aggregation_path)
        @aggregation_path = aggregation_path
      end

      # Prepare the aggregation function for a model class and a field
      # @param model [ActiveRecord::Base] model that will be used as origin for association paths.
      # @param field_name [String, nil] Name that will take the computed aggregation operation.
      #        If nil, it will take the value <table_alias>__<agg_function>.
      def prepare(model, field_name = nil)
        @model = model
        @selection = Babik::Selection::Path::Factory.build(model, @aggregation_path)
        @field_name = field_name || "#{self.table_alias}__#{SQL_OPERATION.downcase}"
        self
      end

      # Return aggregation function SQL
      # @return [String] Aggregation function SQL
      def sql
        "#{self.class::SQL_OPERATION}(#{@selection.target_alias}.#{@selection.selected_field}) AS #{@field_name}"
      end

      # Return the joins grouped by alias
      # @return [Hash{alias: Babik::QuerySet::Join}] Hash where the value is the alias of the table and the value is a Babik::Join
      def left_joins_by_alias
        @selection.left_joins_by_alias
      end
    end

    # Class method utility method
    # @param operation [String] Function that will be executed in the aggregation.
    # @param aggregation_path [String]
    # @return [Class < AbstractAggregationFunction] aggregation function object.
    def self.agg(operation, aggregation_path)
      operation_class_name = operation.capitalize
      operation_class = Object.const_get("Babik::QuerySet::#{operation_class_name}")
      operation_class.new(aggregation_path)
    end

    # Average operation. Compute the mean of a set of values.
    class Avg < AbstractAggregationFunction
      SQL_OPERATION = 'AVG'
    end

    # Max operation. Compute the maximum of a set of values.
    class Max < AbstractAggregationFunction
      SQL_OPERATION = 'MAX'
    end

    # Min operation. Compute the minimum of a set of values.
    class Min < AbstractAggregationFunction
      SQL_OPERATION = 'MIN'
    end

    # Sum operation. Compute the sum of a set of values.
    class Sum < AbstractAggregationFunction
      SQL_OPERATION = 'SUM'
    end
  end
end