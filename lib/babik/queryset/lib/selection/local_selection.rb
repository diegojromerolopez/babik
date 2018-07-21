# frozen_string_literal: true

require 'babik/queryset/lib/selection/selection'
require 'babik/queryset/lib/selection/operation/operations'
require 'babik/queryset/lib/selection/path/local_path'

module Babik
  module Selection
    # Selection by a local field
    class LocalSelection < Babik::Selection::Path::LocalPath

      attr_reader :model, :selection_path, :selected_field, :operator, :secondary_operator, :value

      # Construct a local field selector
      # @param model [ActiveRecord::Base] model whose field will be used.
      # @param selection_path [String] selection path. Of the form <field>__<operator>. e.g. first_name__equal, stars__gt
      #        If no operator is given (first_name), 'equal' will be used.
      # @param value [String,Integer,Float,ActiveRecord::Base,Babik::QuerySet::Base] anything that can be used
      #        to select objects.
      def initialize(model, selection_path, value)
        super(model, selection_path)
        @value = value
      end

      # Return the SQL where condition
      # @return [Babik::Selection::Operation::Base] Condition obtained from the selection path and value.
      def sql_where_condition
        actual_field = Babik::Table::Field.new(model, @selected_field).real_field
        # Return the condition
        operator = if @secondary_operator
                     [@operator, @secondary_operator]
                   else
                     @operator
                   end
        Babik::Selection::Operation::Base.factory("#{self.target_alias}.#{actual_field}", operator, @value)
      end

    end
  end
end