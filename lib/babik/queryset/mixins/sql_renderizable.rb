# frozen_string_literal: true

module Babik
  module QuerySet
    # Enumerable functionality for QuerySet
    module SQLRenderizable

      # Get the SQL renderer for this QuerySet.
      # @return [QuerySet] SQL Renderer for this QuerySet.
      def sql
        renderer = SQLRenderer.new(self)
        renderer
      end

    end
  end
end