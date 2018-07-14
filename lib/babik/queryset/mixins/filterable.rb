# frozen_string_literal: true

module Babik
  module QuerySet
    # Functionality related to the DELETE operation
    module Filterable
      # Exclude objects according to some criteria.
      # @return [QuerySet] Reference to self.
      def exclude(filter)
        _filter(filter, 'exclusion')
        self
      end

      # Select objects according to some criteria.
      # @param filter [Array, Hash] if array, it is considered an disjunction (OR clause),
      #        if a hash, it is considered a conjunction (AND clause).
      # @return [QuerySet] Reference to self.
      def filter(filter)
        _filter(filter, 'inclusion')
        self
      end

      # Get an single element
      # @param filter [Array, Hash] if array, it is considered an disjunction (OR clause),
      #        if a hash, it is considered a conjunction (AND clause).
      # @raise [RuntimeError] Exception:
      #        'Multiple objects returned' if more than one object matches the condition.
      #        'Does not exist' if no object match the conditions.
      # @return [ActiveRecord::Base] object that matches the filter.
      def get(filter)
        result_ = self.filter(filter).all
        result_count = result_.count
        raise 'Does not exist' if result_count.zero?
        raise 'Multiple objects returned' if result_count > 1
        result_.first
      end

      # Select the objects according to some criteria.
      # @param filter [Array, Hash] if array, it is considered an disjunction (OR clause),
      #        if a hash, it is considered a conjunction (AND clause).
      # @param filter_type [String] Filter type. Must be 'inclusion' or 'exclusion'.
      # @raise [NoMethodError] if filter_type is not 'inclusion' nor 'exclusion'.
      def _filter(filter, filter_type)
        @_where.send("add_#{filter_type}_filter", filter)
      end

    end
  end
end