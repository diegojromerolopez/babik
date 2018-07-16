# frozen_string_literal: true

require 'babik/queryset/lib/association/foreign_association_chain'

module Babik
  module Association

    # Association chain for association paths
    # An association chain is a chain of associations
    # where the target model of association i is the origin model of association i + 1
    # Remember, an association path is of the form: zone::parent_zone, category::posts::tags
    class SelectRelatedAssociationChain < ForeignAssociationChain

      # Each one of the association
      # @param association_i [AssociationReflection] ith association.
      # @return [ActiveRecord::Base] target model of ith association.
      def _association_pass(association_i)
        # To one relationship
        if association_i.belongs_to? || association_i.has_one?
          @associations << association_i
          associated_model_i = association_i.klass
          @target_model = associated_model_i
          return @target_model
        end
        raise "Bad association path: #{association_i.name} in model #{association_i.klass} " \
              "is not belongs_to or has_one when constructing select_related for #{@model} objects"
      end

    end

  end
end