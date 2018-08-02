# frozen_string_literal: true

module Babik
  module QuerySet
    # set operations over QuerySets
    module SetOperations

      def difference(other_queryset)
        Babik::QuerySet::Except.new(self.model, self, other_queryset)
      end

      def intersection(other_queryset)
        Babik::QuerySet::Intersect.new(self.model, self, other_queryset)
      end

      def union(other_queryset)
        Babik::QuerySet::Union.new(self.model, self, other_queryset)
      end

    end
  end
end

