# frozen_string_literal: true

require 'babik/queryset/mixins/aggregatable'
require 'babik/queryset/mixins/clonable'
require 'babik/queryset/mixins/countable'
require 'babik/queryset/mixins/deletable'
require 'babik/queryset/mixins/distinguishable'
require 'babik/queryset/mixins/filterable'
require 'babik/queryset/mixins/limitable'
require 'babik/queryset/mixins/lockable'
require 'babik/queryset/mixins/projectable'
require 'babik/queryset/mixins/sortable'
require 'babik/queryset/mixins/sql_renderer'
require 'babik/queryset/mixins/updatable'

require 'babik/queryset/components/aggregation'
require 'babik/queryset/components/limit'
require 'babik/queryset/components/order'
require 'babik/queryset/components/projection'
require 'babik/queryset/components/select_related'
require 'babik/queryset/components/where'

require 'babik/queryset/lib/condition'
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
      include Babik::QuerySet::Clonable
      include Babik::QuerySet::Countable
      include Babik::QuerySet::Deletable
      include Babik::QuerySet::Distinguishable
      include Babik::QuerySet::Filterable
      include Babik::QuerySet::Limitable
      include Babik::QuerySet::Lockable
      include Babik::QuerySet::Projectable
      include Babik::QuerySet::Sortable
      include Babik::QuerySet::Updatable

      attr_reader :model, :_aggregation, :_count, :_distinct, :_limit, :_lock_type, :_order, :_projection,
                  :_where, :_select_related, :_update

      alias aggregation? _aggregation
      alias count? _count
      alias distinct? _distinct
      alias projection? _projection
      alias select_related? _select_related

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
        sql_select = sql.select
        return self.class._execute_sql(sql_select) if @_projection
        return @_select_related.all_with_related(self.class._execute_sql(sql_select)) if @_select_related
        @model.find_by_sql(sql_select)
      end

      # Loop through the results with a block
      # @param block [Proc] Proc that will be applied to each object.
      def each(&block)
        self.all.each(&block)
      end

      # Return the first element of the QuerySet.
      # @return [ActiveRecord::Base] First element of the QuerySet.
      def first
        self.all.first
      end

      # Return the last element of the QuerySet.
      # @return [ActiveRecord::Base] Last element of the QuerySet.
      def last
        self.invert_order.all.first
      end

      # Return an empty ActiveRecord ResultSet
      # @return [ResultSet] Empty result set.
      def none
        @model.find_by_sql("SELECT * FROM #{@model.table_name} WHERE 1 = 0")
      end

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

      # Get the SQL renderer for this QuerySet.
      # @return [QuerySet] SQL Renderer for this QuerySet.
      def sql
        renderer = SQLRenderer.new(self)
        renderer
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