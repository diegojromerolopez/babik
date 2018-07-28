# frozen_string_literal: true

module Babik
  module QuerySet
    # Enumerable functionality for QuerySet
    module Enumerable

      # Return a ResultSet with the ActiveRecord objects that match the condition given by the filters.
      # @return [ResultSet] ActiveRecord objects that match the condition given by the filters.
      def all
        sql_select = sql.select
        return @_projection.apply_transforms(self.class._execute_sql(sql_select)) if @_projection
        return @_select_related.all_with_related(self.class._execute_sql(sql_select)) if @_select_related
        @model.find_by_sql(sql_select)
      end

      # Loop through the results with a block
      # @param block [Proc] Proc that will be applied to each object.
      def each(&block)
        self.all.each(&block)
      end

      # Return an empty ActiveRecord ResultSet
      # @return [ResultSet] Empty result set.
      def none
        @model.find_by_sql("SELECT * FROM #{@model.table_name} WHERE 1 = 0")
      end

    end
  end
end