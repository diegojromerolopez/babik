# frozen_string_literal: true

module Babik
  module QuerySet
    # Functionality related to the aggregation selection
    module Aggregatable
      # Aggregate a set of objects.
      # @param agg_functions [Hash{symbol: Babik.agg}] hash with the different aggregations that will be computed.
      # @return [Hash{symbol: float}] Result of computing each one of the aggregations.
      def aggregate(agg_functions)
        @_aggregation = Babik::QuerySet::Aggregation.new(@model, agg_functions)
        select_sql = sql.select
        self.class._execute_sql(select_sql).first.transform_values(&:to_f).symbolize_keys
      end
    end
  end
end
