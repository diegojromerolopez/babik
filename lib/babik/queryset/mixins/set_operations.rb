# frozen_string_literal: true

module Babik
  module QuerySet
    # Set operations over QuerySets
    module SetOperations

      # Difference (minus) operation
      # @param other_queryset [QuerySet] Other QuerySet
      # @return [Babik::QuerySet::Except] Except set operation between this queryset and the other queryset.
      def difference(other_queryset)
        Babik::QuerySet::Except.new(self.model, self, other_queryset)
      end

      # Intersection (except) operation
      # @param other_queryset [QuerySet] Other QuerySet
      # @return [Babik::QuerySet::Intersect] Intersection set operation between this queryset and the other queryset.
      def intersection(other_queryset)
        Babik::QuerySet::Intersect.new(self.model, self, other_queryset)
      end

      # Union operation
      # @param other_queryset [QuerySet] Other QuerySet
      # @return [Babik::QuerySet::Union] Union set operation between this queryset and the other queryset.
      def union(other_queryset)
        Babik::QuerySet::Union.new(self.model, self, other_queryset)
      end

    end
  end
end

