# frozen_string_literal: true

module Babik
  module QuerySet
    # Project functionality of QuerySet
    module Projectable
      # Prepares a projection of only some attributes
      # @param *attributes [Array] Attributes that will be projected.
      #        Each one of these can be a local field, or a foreign entity field.
      #        Babik will take care of joins.
      # @return [QuerySet::Projectable] Reference to this QuerySet.
      def project!(*attributes)
        @_projection = Babik::QuerySet::Projection.new(@model, attributes)
        self
      end

      # Removes the projection.
      # @return [QuerySet::Projectable] Reference to this QuerySet.
      def unproject!
        @_projection = nil
        self
      end

      # Inform if there is the QuerySet is configured with a projection
      # @return [Boolean] True if there is a projection configured, false otherwise.
      def projection?
        return true if @_projection
        false
      end
    end
  end
end
