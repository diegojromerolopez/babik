# frozen_string_literal: true

require 'babik/combinator'

module Babik
  module QuerySet
    # set operations over QuerySets
    module SetOperations

      def difference(other_queryset)
        Babik::QuerySet::Combinator::Difference.new(self.model, self).difference(other_queryset)
      end

      def intersection(other_queryset)
        Babik::QuerySet::Combinator::Intersection.new(self.model, self).intersection(other_queryset)
      end

      def union(other_queryset)
        Babik::QuerySet::Combinator::Union.new(self.model, self, other_queryset)
      end

    end
  end
end

