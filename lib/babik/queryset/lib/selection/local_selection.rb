# frozen_string_literal: true

require 'babik/queryset/lib/selection/selection'
require 'babik/queryset/lib/selection/operation'

module Babik
  module Selection
    # Selection by a local field
    class LocalSelection < Babik::Selection::Base

      attr_reader :model, :selection_path, :selected_field, :operator, :value

      # Construct a local field selector
      # @param model [ActiveRecord::Base] model whose field will be used.
      # @param selection_path [String] selection path. Of the form <field>__<operator>. e.g. first_name__equal, stars__gt
      #        If no operator is given (first_name), 'equal' will be used.
      # @param value [String,Integer,Float,ActiveRecord::Base,Babik::QuerySet::Base] anything that can be used
      #        to select objects.
      def initialize(model, selection_path, value)
        super
        @selected_field, @operator = @selection_path.to_s.split(OPERATOR_SEPARATOR)
        # By default, if no operator is given, 'equal' will be used
        @operator ||= 'equal'
      end

      # Return the SQL where condition
      # @return [Babik::Selection::Operation::Base] Condition obtained from the selection path and value.
      def sql_where_condition
        field = Babik::Table::Field.new(model, @selected_field)
        actual_field = field.real_field
        # Return the condition
        Babik::Selection::Operation::Base.factory("#{self.target_alias}.#{actual_field}", @operator, @value)
      end

      # Return the target table alias.
      # That is alias of the model table.
      # For the moment, actually, return the name of this model's table.
      # @return [String] alias of the model table.
      def target_alias
        @model.table_name
      end

    end
  end
end