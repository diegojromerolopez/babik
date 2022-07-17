# frozen_string_literal: true

module Babik
  module QuerySet
    # Functionality related to the size of the QuerySet
    module Countable

      # Return the number of elements that match the condition defined by successive calls of filter and exclude.
      # @return [Integer] Number of elements that match the condition defined in this QuerySet.
      def count
        self.all.count
      end

      # Inform if the QuerySet has no elements that match the condition.
      # @return [Boolean] True if no records match the filter, false otherwise.
      def empty?
        self.count.zero?
      end

      # Inform if the QuerySet has at least one element that match the condition.
      # @return [Boolean] True if one or more records match the filter, false otherwise.
      def exists?
        self.count.positive?
      end

      # Return the number of elements that match the condition defined by successive calls of filter and exclude.
      # Alias of count.
      # @see Babik::QuerySet::Countable#count
      # @return [Integer] Number of elements that match the condition defined in this QuerySet.
      def length
        self.count
      end

      # Return the number of elements that match the condition defined by successive calls of filter and exclude.
      # Alias of count.
      # @see Babik::QuerySet::Countable#count
      # @return [Integer] Number of elements that match the condition defined in this QuerySet.
      def size
        self.count
      end

    end
  end
end
