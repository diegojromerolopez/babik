# frozen_string_literal: true

require 'babik/queryset/lib/join/association_joiner'
require 'babik/queryset/lib/join/join'
require 'babik/queryset/lib/selection/selection'
require 'babik/queryset/lib/association/select_related_association_chain'

module Babik
  module Selection

    # Abstraction of a selection used in select_related operation
    class SelectRelatedSelection
      RELATIONSHIP_SEPARATOR = Babik::Selection::Base::RELATIONSHIP_SEPARATOR
      attr_reader :model, :selection_path, :association_path, :associations, :target_model, :id

      delegate :left_joins_by_alias, to: :@association_joiner
      delegate :target_alias, to: :@association_joiner

      def initialize(model, selection_path)
        @model = model
        @selection_path = selection_path.dup
        @association_path = selection_path.to_s.split(RELATIONSHIP_SEPARATOR)
        @id = @association_path.join('__')

        _initialize_associations
        @target_model = @association_chain.target_model
      end

      def _initialize_associations
        @association_chain = Babik::Association::SelectRelatedAssociationChain.new(@model, @association_path, @selection_path)
        @association_joiner = Babik::QuerySet::Join::AssociationJoiner.new(@association_chain.associations)
      end

    end
  end
end