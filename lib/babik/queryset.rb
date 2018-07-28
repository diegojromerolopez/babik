# frozen_string_literal: true

require 'babik/queryset/mixins/aggregatable'
require 'babik/queryset/mixins/bounded'
require 'babik/queryset/mixins/clonable'
require 'babik/queryset/mixins/countable'
require 'babik/queryset/mixins/deletable'
require 'babik/queryset/mixins/distinguishable'
require 'babik/queryset/mixins/enumerable'
require 'babik/queryset/mixins/filterable'
require 'babik/queryset/mixins/limitable'
require 'babik/queryset/mixins/lockable'
require 'babik/queryset/mixins/projectable'
require 'babik/queryset/mixins/related_selector'
#require 'babik/queryset/mixins/set_operations'
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
    # Base class for QuerySet, implements a container for database results.
    class Base
      include Enumerable
      include Babik::QuerySet::Aggregatable
      include Babik::QuerySet::Bounded
      include Babik::QuerySet::Clonable
      include Babik::QuerySet::Countable
      include Babik::QuerySet::Deletable
      include Babik::QuerySet::Enumerable
      include Babik::QuerySet::Distinguishable
      include Babik::QuerySet::Filterable
      include Babik::QuerySet::Limitable
      include Babik::QuerySet::Lockable
      include Babik::QuerySet::Projectable
      include Babik::QuerySet::RelatedSelector
      #include Babik::QuerySet::SetOperations
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
  end
end