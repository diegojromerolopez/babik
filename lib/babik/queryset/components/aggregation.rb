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
        selected_field_path = "#{@selection.target_alias}.#{@selection.selected_field}"
        operation = self.sql_operation.sub('?field', selected_field_path)
        "#{operation} AS #{@field_name}"
      end

      # Return the joins grouped by alias
      # @return [Hash{alias: Babik::QuerySet::Join}] Hash where the value is the alias of the table and the value is a Babik::Join
      def left_joins_by_alias
        @selection.left_joins_by_alias
      end

      # Return the database adapter
      # @return [String] Database adapter: 'mysql2', 'postgres' o 'sqlite'
      def self.db_adapter
        Babik::Database.config[:adapter]
      end

    end

    # Class method utility method
    # @param operation [String] Function that will be executed in the aggregation.
    # @param aggregation_path [String]
    # @return [Class < AbstractAggregationFunction] aggregation function object.
    def self.agg(operation, aggregation_path)
      operation_class_name = operation.to_s.camelize
      operation_class = Object.const_get("Babik::QuerySet::#{operation_class_name}")
      operation_class.new(aggregation_path)
    end

    # Mixin that injects the sql_operation method in aggregations with the same SQL syntax
    # independently of the database adapter (SUM, MAX, MIN, etc.)
    module StandardSqlOperation
      def sql_operation
        self.class::SQL_OPERATION
      end
    end

    # Average operation. Compute the mean of a set of values.
    class Avg < AbstractAggregationFunction
      include StandardSqlOperation
      SQL_OPERATION = 'AVG(?field)'
    end

    # Count operation. Compute the count of a set of values.
    class Count < AbstractAggregationFunction
      include StandardSqlOperation
      SQL_OPERATION = 'COUNT(?field)'
    end

    # Count distinct operation. Compute the count distinct of a set of values.
    class CountDistinct < AbstractAggregationFunction
      include StandardSqlOperation
      SQL_OPERATION = 'COUNT(DISTINCT(?field))'
    end

    # Max operation. Compute the maximum of a set of values.
    class Max < AbstractAggregationFunction
      include StandardSqlOperation
      SQL_OPERATION = 'MAX(?field)'
    end

    # Min operation. Compute the minimum of a set of values.
    class Min < AbstractAggregationFunction
      include StandardSqlOperation
      SQL_OPERATION = 'MIN(?field)'
    end

    # Sum operation. Compute the sum of a set of values.
    class Sum < AbstractAggregationFunction
      include StandardSqlOperation
      SQL_OPERATION = 'SUM(?field)'
    end

    # When a aggregation function is in PostgreSQL and MySQL (main supported databases)
    class PostgresMySQLAggregationFunction < AbstractAggregationFunction
      # Return the SQL code operation for this aggregation, e.g.:
      #   - STDDEV_POP(?field)
      #   - VAR_POP(?field)
      # @raise [RuntimeException] if database has no support for this operation.
      # @return [String] SQL code for the aggregation
      def sql_operation
        db_adapter = self.class.db_adapter
        return self.class::SQL_OPERATION if %w[postgresql mysql2].include?(db_adapter)
        raise "#{db_adapter} has no support for #{self.class} aggregation"
      end
    end

    # Standard deviation of a set of values
    class StdDev < PostgresMySQLAggregationFunction
      SQL_OPERATION = 'STDDEV_POP(?field)'
    end

    # Standard deviation (sample) of a set of values
    class StdDevSample < PostgresMySQLAggregationFunction
      SQL_OPERATION = 'STDDEV_SAMP(?field)'
    end

    # Variance of a set of values
    class Var < PostgresMySQLAggregationFunction
      SQL_OPERATION = 'VAR_POP(?field)'
    end

    # Variance (sample) of a set of values
    class VarSample < PostgresMySQLAggregationFunction
      SQL_OPERATION = 'VAR_SAMP(?field)'
    end

  end
end
