# frozen_string_literal: true

require 'babik/queryset/lib/selection/path/foreign_path'

module Babik
  module Selection
    # Foreign selection
    class ForeignSelection < Babik::Selection::Path::ForeignPath

      attr_reader :model, :selection_path, :selected_field,
                  :sql_where_condition,
                  :value, :operator

      # Create a foreign selection, that is, a filter that is based on a foreign field condition.
      # @param model [ActiveRecord::Base] Model
      # @param selection_path [String, Symbol] selection path used only to raise errors. e.g.:
      #        posts::category__in
      #        author::posts::tags
      #        creation_at__date__gte
      # @param value [String, Integer, ActiveRecord::Base] value that will be used in the filter
      def initialize(model, selection_path, value)
        super(model, selection_path)
        # If the value is an ActiveRecord model, get its id
        @value = value
        @value = @value.id if @value.is_a?(ActiveRecord::Base)
        _init_sql_where_condition
      end

      # Initialize the SQL condition that will be used on the SQL SELECT
      def _init_sql_where_condition
        last_association_model = @association_chain.target_model
        actual_field = Babik::Table::Field.new(last_association_model, @selected_field).real_field
        @sql_where_condition = Babik::Selection::Operation::Base.factory(
          "#{target_alias}.#{actual_field}", @operator, @value
        )
      end
    end
  end
end