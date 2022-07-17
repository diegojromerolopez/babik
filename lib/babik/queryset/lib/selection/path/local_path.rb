# frozen_string_literal: true

require 'babik/queryset/lib/selection/config'

module Babik
  module Selection
    module Path
      # Local path
      class LocalPath
        OPERATOR_SEPARATOR = Babik::Selection::Config::OPERATOR_SEPARATOR

        attr_reader :model, :selection_path, :selected_field, :operator, :secondary_operator

        # Construct a local field path
        # @param model [ActiveRecord::Base] model whose field will be used.
        # @param selection_path [String] selection path. Of the form <field>__<operator>.
        #        e.g. first_name__equal, stars__gt.
        #        If no operator is given (first_name), 'equal' will be used.
        def initialize(model, selection_path)
          @model = model
          @selection_path = selection_path.dup
          @selected_field, @operator, @secondary_operator = @selection_path.to_s.split(OPERATOR_SEPARATOR)
          # By default, if no operator is given, 'equal' will be used
          @operator ||= 'equal'
        end

        # Return the target table alias.
        # That is alias of the model table.
        # For the moment, actually, return the name of this model's table.
        # @return [String] alias of the model table.
        def target_alias
          @model.table_name
        end

        # A local selection has no related left joins
        # @return [Hash] Empty hash.
        def left_joins_by_alias
          {}
        end
      end
    end
  end
end
