# frozen_string_literal: true

module Babik
  module QuerySet
    # Distinguishable functionality for QuerySet
    module Distinguishable

      # Mark this QuerySet as distinguishable.
      # Modify this object
      # (i.e. DISTINCT keyword will be applied to the final SQL query).
      # @return [QuerySet] Reference to this QuerySet.
      def distinct!
        @_distinct = true
        self
      end

      # Mark this QuerySet as not distinguishable
      # (i.e. DISTINCT keyword will NOT be applied to query).
      # @return [QuerySet] Reference to this QuerySet.
      def undistinct!
        @_distinct = false
        self
      end

      # Inform if it is distinct QuerySet
      # @return [Boolean] true if DISTINCT modifier will be applied to query, false otherwise.
      def distinct?
        @_distinct
      end
    end
  end
end