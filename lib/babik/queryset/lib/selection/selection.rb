# frozen_string_literal: true

require 'babik/queryset/lib/selection/config'

module Babik
  module Selection
    # Represents a filter selection (that can be filtered in WHERE)
    class Base
      # Factory Method used to create local and foreign selections
      def self.factory(model, selection_path, value)
        is_foreign_selection = selection_path.match?(Babik::Selection::Config::RELATIONSHIP_SEPARATOR)
        return Babik::Selection::ForeignSelection.new(model, selection_path, value) if is_foreign_selection
        Babik::Selection::LocalSelection.new(model, selection_path, value)
      end
    end
  end
end
