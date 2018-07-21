# frozen_string_literal: true

require 'babik/queryset/lib/selection/config'
require 'babik/queryset/lib/join/association_joiner'
require 'babik/queryset/lib/association/foreign_association_chain'

module Babik
  module Selection
    module Path
      # Foreign path
      # A foreign path is a succession of associations ending optionally in an operator
      # if operator is not present, equal is supposed.
      class ForeignPath
        RELATIONSHIP_SEPARATOR = Babik::Selection::Config::RELATIONSHIP_SEPARATOR
        OPERATOR_SEPARATOR = Babik::Selection::Config::OPERATOR_SEPARATOR

        attr_reader :model, :selection_path, :selected_field

        delegate :left_joins_by_alias, to: :@association_joiner
        delegate :target_alias, to: :@association_joiner
        delegate :associations, to: :@association_chain

        # Construct a foreign path
        # A foreign path will be used with a value as a foreign selection to filter
        # a model with foreign conditions
        # @param model [ActiveRecord::Base] model that is the object of the foreign path.
        # @param selection_path [String, Symbol] Association path with an operator. e.g.:
        #        posts::category__in
        #        author::posts::tags
        #        creation_at__date__gte
        #
        def initialize(model, selection_path)
          @model = model
          @selection_path = selection_path.dup
          @association_path = selection_path.to_s.split(RELATIONSHIP_SEPARATOR)
          selection_path = @association_path.pop
          @selected_field, @operator = selection_path.split(OPERATOR_SEPARATOR)
          @operator ||= 'equal'
          _initialize_associations
        end

        # Initialize associations
        def _initialize_associations
          @association_chain = Babik::Association::ForeignAssociationChain.new(@model, @association_path, @selection_path)
          @association_joiner = Babik::QuerySet::Join::AssociationJoiner.new(@association_chain.associations)
        end
      end
    end
  end
end