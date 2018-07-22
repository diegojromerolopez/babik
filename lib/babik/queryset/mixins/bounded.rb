# frozen_string_literal: true

module Babik
  module QuerySet
    # Every QuerySet is bounded by its first and last items
    module Bounded

      # Return the first element given some order
      # @param order [Array, String, Hash] ordering that will be applied to the QuerySet.
      #              See {Babik::QuerySet::Sortable#order_by}.
      # @return [ActiveRecord::Base] First element according to the order.
      def earliest(*order)
        self.order_by(*order).first
      end

      # Return the first element of the QuerySet.
      # @return [ActiveRecord::Base] First element of the QuerySet.
      def first
        self.all.first
      end

      # Return the last element of the QuerySet.
      # @return [ActiveRecord::Base] Last element of the QuerySet.
      def last
        self.invert_order.all.first
      end

      # Return the last element given some order
      # @param order [Array, String, Hash] ordering that will be applied to the QuerySet.
      #              See {Babik::QuerySet::Sortable#order_by}.
      # @return [ActiveRecord::Base] Last element according to the order.
      def latest(*order)
        self.order_by(*order).last
      end

    end
  end
end