# frozen_string_literal: true

require 'babik/queryset/lib/selection/selection'
require 'babik/queryset/lib/selection/operation/operations'
require 'babik/queryset/lib/join/association_joiner'
require 'babik/queryset/lib/association/foreign_association_chain'

module Babik
  module Selection
    # Foreign selection
    class ForeignSelection < Babik::Selection::Base
      RELATIONSHIP_SEPARATOR = '::'
      OPERATOR_SEPARATOR = '__'

      attr_reader :model, :selection_path, :selected_field,
                  :sql_where_condition,
                  :value, :operator

      delegate :left_joins_by_alias, to: :@association_joiner
      delegate :target_alias, to: :@association_joiner
      delegate :associations, to: :@association_chain

      def initialize(model, selection_path, value)
        super
        @selection_path = selection_path.dup
        @association_path = selection_path.to_s.split(RELATIONSHIP_SEPARATOR)
        selection_path = @association_path.pop
        @selected_field, @operator = selection_path.split(OPERATOR_SEPARATOR)
        @operator ||= 'equal'
        # If the value is an ActiveRecord model, get its id
        @value = @value.id if @value.is_a?(ActiveRecord::Base)
        _initialize_associations
        _init_sql_where_condition
      end

      def _initialize_associations
        @association_chain = Babik::Association::ForeignAssociationChain.new(@model, @association_path, @selection_path)
        @association_joiner = Babik::QuerySet::Join::AssociationJoiner.new(@association_chain.associations)
      end

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