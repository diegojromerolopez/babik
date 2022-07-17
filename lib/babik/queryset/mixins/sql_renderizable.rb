# frozen_string_literal: true

module Babik
  module QuerySet
    # Enumerable functionality for QuerySet
    module SQLRenderizable
      # Get the SQL renderer for this QuerySet.
      # @return [QuerySet::SQLRenderer] SQL Renderer for this QuerySet.
      def sql
        SQLRenderer.new(self)
      end
    end
  end
end
