# frozen_string_literal: true

module Babik
  module QuerySet
    # Functionality related to the DELETE operation
    module Filterable
      # Exclude objects according to some criteria.
      # @return [QuerySet] Reference to self.
      def exclude(filters)
        _filter(filters, @exclusion_filters)
      end

      # Select objects according to some criteria.
      # @param filters [Array, Hash] if array, it is considered an disjunction (OR clause),
      #        if a hash, it is considered a conjunction (AND clause).
      # @return [QuerySet] Reference to self.
      def filter(filters)
        _filter(filters, @inclusion_filters)
      end

      # Select the objects according to some criteria.
      def _filter(filters, applied_filters)
        if filters.class == Array
          disjunctions = filters.map do |filter|
            Conjunction.new(@model, filter)
          end
          applied_filters << disjunctions
        elsif filters.class == Hash
          applied_filters << Conjunction.new(@model, filters)
        end
        self
      end
    end
  end
end