# frozen_string_literal: true

require 'babik/queryset/mixins/aggregatable'
require 'babik/queryset/mixins/bounded'
require 'babik/queryset/mixins/clonable'
require 'babik/queryset/mixins/countable'
require 'babik/queryset/mixins/deletable'
require 'babik/queryset/mixins/distinguishable'
require 'babik/queryset/mixins/none'
require 'babik/queryset/mixins/filterable'
require 'babik/queryset/mixins/limitable'
require 'babik/queryset/mixins/lockable'
require 'babik/queryset/mixins/projectable'
require 'babik/queryset/mixins/related_selector'
require 'babik/queryset/mixins/set_operations'
require 'babik/queryset/mixins/sql_renderizable'
require 'babik/queryset/mixins/sortable'
require 'babik/queryset/mixins/updatable'

require 'babik/queryset/components/aggregation'
require 'babik/queryset/components/limit'
require 'babik/queryset/components/order'
require 'babik/queryset/components/projection'
require 'babik/queryset/components/select_related'
require 'babik/queryset/components/sql_renderer'
require 'babik/queryset/components/where'

require 'babik/queryset/lib/condition'
require 'babik/queryset/lib/selection/config'
require 'babik/queryset/lib/selection/local_selection'
require 'babik/queryset/lib/selection/foreign_selection'
require 'babik/queryset/lib/field'
require 'babik/queryset/lib/update/assignment'

# Represents a new type of query result set
module Babik
  module QuerySet
    # Abstract Base class for QuerySet, implements a container for database results.
    class AbstractBase
      include Enumerable
      include Babik::QuerySet::Aggregatable
      include Babik::QuerySet::Bounded
      include Babik::QuerySet::Clonable
      include Babik::QuerySet::Countable
      include Babik::QuerySet::Deletable
      include Babik::QuerySet::NoneQuerySet
      include Babik::QuerySet::Distinguishable
      include Babik::QuerySet::Filterable
      include Babik::QuerySet::Limitable
      include Babik::QuerySet::Lockable
      include Babik::QuerySet::Projectable
      include Babik::QuerySet::SQLRenderizable
      include Babik::QuerySet::RelatedSelector
      include Babik::QuerySet::SetOperations
      include Babik::QuerySet::Sortable
      include Babik::QuerySet::Updatable

      attr_reader :model, :_aggregation, :_count, :_distinct, :_limit, :_lock_type, :_order, :_projection,
                  :_where, :_select_related

      alias aggregation? _aggregation
      alias count? _count
      alias distinct? _distinct
      alias select_related? _select_related
      alias reverse! invert_order!
      alias select_for_update! for_update!
      alias exist? exists?

      def initialize(model_class)
        @model = model_class
        @_count = false
        @_distinct = false
        @_order = nil
        @_lock_type = nil
        @_where = Babik::QuerySet::Where.new(@model)
        @_aggregation = nil
        @_limit = nil
        @_projection = nil
        @_select_related = nil
      end

      # Return a ResultSet with the ActiveRecord objects that match the condition given by the filters.
      # @return [ResultSet] ActiveRecord objects that match the condition given by the filters.
      def all
        sql_select = self.sql.select
        return @_projection.apply_transforms(self.class._execute_sql(sql_select)) if @_projection
        return @_select_related.all_with_related(self.class._execute_sql(sql_select)) if @_select_related
        @model.find_by_sql(sql_select)
      end

      # Loop through the results with a block
      # @param block [Proc] Proc that will be applied to each object.
      def each(&block)
        self.all.each(&block)
      end

      # Get the left joins grouped by alias in a hash.
      # @return [Hash] Return a hash with the format :table_alias => SQL::Join
      def left_joins_by_alias
        left_joins_by_alias = {}
        # Merge where
        left_joins_by_alias.merge!(@_where.left_joins_by_alias)
        # Merge order
        left_joins_by_alias.merge!(@_order.left_joins_by_alias) if @_order
        # Merge aggregation
        left_joins_by_alias.merge!(@_aggregation.left_joins_by_alias) if @_aggregation
        # Merge prefetchs
        left_joins_by_alias.merge!(@_select_related.left_joins_by_alias) if @_select_related
        # Return the left joins by alias
        left_joins_by_alias
      end

      # Execute SQL code
      # @param [String] sql SQL code
      # @return SQL result set.
      def self._execute_sql(sql)
        ActiveRecord::Base.connection.exec_query(sql)
      end
    end

    class Base < AbstractBase

    end

    # Each one of the set operations that can be executed in SQL
    class SetOperation < AbstractBase

      attr_reader :left_operand, :right_operand

      def initialize(model, left_operand, right_operand)
        @left_operand = left_operand
        @right_operand = right_operand
        super(model)
      end

      def operation
        db_adapter = Babik::Database.config[:adapter]
        operation_name = self.class.to_s.split('::').last.upcase
        if %w[postgresql sqlite3].include?(db_adapter) || (%w[mysql2].include?(db_adapter) && operation_name == 'UNION')
          return operation_name
        end
        raise "#{db_adapter} does not support operation #{operation_name}"
      end

    end

    class Except < SetOperation; end

    class Intersect < SetOperation; end

    class Union < SetOperation; end

  end
end
