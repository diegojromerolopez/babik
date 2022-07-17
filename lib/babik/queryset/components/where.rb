# frozen_string_literal: true

# Common module for Babik library
module Babik
  # QuerySet module
  module QuerySet
    # Where conditions
    class Where

      attr_reader :model, :inclusion_filters, :exclusion_filters

      def initialize(model)
        @model = model
        @inclusion_filters = []
        @exclusion_filters = []
      end

      def exclusion_filters?
        @exclusion_filters.length.positive?
      end

      def inclusion_filters?
        @inclusion_filters.length.positive?
      end

      def add_exclusion_filter(filter)
        @exclusion_filters << Babik::QuerySet::Condition.factory(@model, filter)
      end

      def add_inclusion_filter(filter)
        @inclusion_filters << Babik::QuerySet::Condition.factory(@model, filter)
      end

      def left_joins_by_alias
        left_joins_by_alias = {}
        [@inclusion_filters, @exclusion_filters].flatten.each do |filter|
          left_joins_by_alias.merge!(filter.left_joins_by_alias)
        end
        left_joins_by_alias
      end
    end
  end
end
