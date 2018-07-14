# frozen_string_literal: true

require 'babik/queryset/mixins/aggregatable'
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

require 'babik/queryset/aggregation'
require 'babik/queryset/limit'
require 'babik/queryset/order'
require 'babik/queryset/projection'
require 'babik/queryset/select_related'

require 'babik/query/conjunction'
require 'babik/query/local_selection'
require 'babik/query/foreign_selection'
require 'babik/query/field'
require 'babik/query/update'

# Represents a new type of query result set
module Babik
  module QuerySet
    # Base class for QuerySet, implements a container for database results.
    class Base
      include Enumerable
      include Babik::QuerySet::Aggregatable
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
                  :inclusion_filters, :exclusion_filters, :_select_related, :_update

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
        @_lock = nil
        @inclusion_filters = []
        @exclusion_filters = []
        @_aggregation = nil
        @_limit = nil
        @_projection = nil
        @_select_related = nil
        @_update = nil
      end

      # Return a ResultSet with the ActiveRecord objects that match the condition given by the filters.
      # @return [ResultSet] ActiveRecord objects that match the condition given by the filters.
      def all
        sql_select = sql.select
        return self.class._execute_sql(sql_select) if @_projection
        return @_select_related.all_with_related(self.class._execute_sql(sql_select)) if @_select_related
        @model.find_by_sql(sql_select)
      end

      # Return the first element of the QuerySet.
      # @return [ActiveRecord::Base] First element of the QuerySet.
      def first
        self.all.first
      end

      def each(&block)
        self.all.each(&block)
      end

      def get(filters)
        result_ = self.filter(filters).all
        result_count = result_.count
        raise 'Does not exist' if result_count.zero?
        raise 'Multiple objects returned' if result_count > 1
        result_.first
      end

      # Return an empty ActiveRecord ResultSet
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
      def select_related(association_paths)
        @_select_related = Babik::QuerySet::SelectRelated.new(@model, association_paths)
        self
      end

      def sql
        SQLRenderer.new(self)
      end

      # Get the left joins grouped by alias in a hash.
      # @return [Hash] Return a hash with the format :table_alias => SQL::Join
      def left_joins_by_alias
        left_joins_by_alias = {}
        @inclusion_filters.flatten.each do |conjunction|
          left_joins_by_alias.merge!(conjunction.left_joins_by_alias)
        end
        @exclusion_filters.flatten.each do |conjunction|
          left_joins_by_alias.merge!(conjunction.left_joins_by_alias)
        end
        # Merge order
        left_joins_by_alias.merge!(@_order.left_joins_by_alias) if @_order
        # Merge aggregation
        left_joins_by_alias.merge!(@_aggregation.left_joins_by_alias) if @_aggregation
        # Merge prefetchs
        left_joins_by_alias.merge!(@_select_related.left_joins_by_alias) if @_select_related
        # Return the left joins by alias
        left_joins_by_alias
      end

      def self._execute_sql(sql)
        ActiveRecord::Base.connection.exec_query(sql)
      end

    end
  end
end