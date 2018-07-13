# frozen_string_literal: true

module Babik
  module QuerySet
    # Sort functionality of QuerySet
    module Sortable

      # Sort QuerySet according to an order
      # @param order [Array, String, Hash] ordering that will be applied to the QuerySet.
      # @return [QuerySet] reference to this QuerySet.
      def order_by(*order)
        @_order = Babik::QuerySet::Order.new(@model, *order)
        self
      end

      #  Alias for order_by
      # @see #order_by
      # @param order [Array, String, Hash] ordering that will be applied to the QuerySet.
      # @return [QuerySet] reference to this QuerySet.
      def order(*order)
        order_by(*order)
      end

    end
  end
end