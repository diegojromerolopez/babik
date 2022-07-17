# frozen_string_literal: true

require 'babik/queryset/lib/selection/config'
require 'babik/queryset/lib/selection/path/foreign_path'
require 'babik/queryset/lib/selection/path/local_path'

module Babik
  module Selection
    module Path
      # Represents a factory class for ForeignPath & LocalPath
      class Factory
        # Factory Method used to create local and foreign selections
        def self.build(model, selection_path)
          is_foreign = selection_path.match?(Babik::Selection::Config::RELATIONSHIP_SEPARATOR)
          return Babik::Selection::Path::ForeignPath.new(model, selection_path) if is_foreign
          Babik::Selection::Path::LocalPath.new(model, selection_path)
        end
      end
    end
  end
end
