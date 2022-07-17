# frozen_string_literal: true

module Babik
  module QuerySet
    # None functionality for QuerySet
    module NoneQuerySet
      # Return an empty ActiveRecord ResultSet
      # @return [ResultSet] Empty result set.
      def none
        @model.find_by_sql("SELECT * FROM #{@model.table_name} WHERE 1 = 0")
      end
    end
  end
end
