# frozen_string_literal: true

module Babik
  module QuerySet
    # Clone operation for the QuerySet
    module Clonable

      # Clone the queryset
      # @return [QuerySet] Deep copy of this QuerySet.
      def clone
        other = Babik::QuerySet::Base.new(@model)
        other.instance_variable_set(:@_count, self._count.clone)
        other.instance_variable_set(:@_distinct, self._distinct.clone)
        other.instance_variable_set(:@_order, self._order.clone)
        other.instance_variable_set(:@_lock_type, self._lock_type.clone)
        other.instance_variable_set(:@_where, self._where.clone)
        other.instance_variable_set(:@_aggregation, self._aggregation.clone)
        other.instance_variable_set(:@_limit, self._limit.clone)
        other.instance_variable_set(:@_projection, self._projection.clone)
        other.instance_variable_set(:@_select_related, self._select_related.clone)
        other.instance_variable_set(:@_update, self._update.clone)
        other
      end

    end
  end
end