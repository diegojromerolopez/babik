# frozen_string_literal: true

module Babik
  module QuerySet
    # select_related functionality of QuerySet
    module RelatedSelector
      # Load the related objects of each model object specified by the association_paths
      #
      # e.g.
      # - User.objects.filter(first_name: 'Julius').select_related(:group)
      # - User.objects.filter(first_name: 'Cassius').select_related([:group, :zone])
      # - Post.objects.select_related(:author)
      #
      # @param association_paths [Array<Symbol>, Symbol] Array of association paths
      #        of belongs_to and has_one related objects.
      #        A passed symbol will be considered as an array of one symbol.
      #        That is, select_related(:group) is equal to select_related([:group])
      def select_related!(association_paths)
        @_select_related = Babik::QuerySet::SelectRelated.new(@model, association_paths)
        self
      end
    end
  end
end
