# frozen_string_literal: true

module Babik
  module Selection
    # Represents a filter selection (that can be filtered in WHERE)
    class Base
      RELATIONSHIP_SEPARATOR = '::'
      OPERATOR_SEPARATOR = '__'

      def self.factory(model, selection_path, value)
        is_foreign_selection = selection_path.match?(RELATIONSHIP_SEPARATOR)
        return Babik::Selection::ForeignSelection.new(model, selection_path, value) if is_foreign_selection
        Babik::Selection::LocalSelection.new(model, selection_path, value)
      end

      def initialize(model, selection_path, value)
        @model = model
        @selection_path = selection_path
        @value = value
      end

      def left_joins_by_alias
        {}
      end

    end
  end
end