# frozen_string_literal: true

require 'babik/queryset/mixins/countable'
require 'babik/queryset/order'
require 'babik/queryset/select_related'
require 'babik/query/aggregation'
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
      include Babik::QuerySet::Countable

      attr_reader :model, :is_count, :has_distinct, :number_of_rows_limit, :offset, :lock_type, :projection,
                  :inclusion_filters, :exclusion_filters, :aggregations, :update_command, :_select_related, :_order

      def initialize(model_class)
        @db_conf = ActiveRecord::Base.connection_config
        @model = model_class
        @is_count = false
        @has_distinct = false
        @number_of_rows_limit = nil
        @offset = nil
        @_order = nil
        @lock_type = nil
        @inclusion_filters = []
        @exclusion_filters = []
        @aggregations = []
        @projection = false
        @update_command = nil
        @_select_related = nil
      end

      # Aggregate a set of objects.
      # @param aggregations [Hash{symbol: Babik.agg}] hash with the different aggregations that will be computed.
      # @return [Hash{symbol: float}] Result of computing each one of the aggregations.
      def aggregate(aggregations)
        aggregations.each do |aggregation_field_name, aggregation|
          @aggregations << aggregation.prepare(@model, aggregation_field_name)
        end
        self.class._execute_sql(self.select_sql).first.symbolize_keys
      end

      # Delete the selected records
      def delete
        @model.connection.execute(self.delete_sql)
      end

      # Exclude objects according to some criteria.
      # @return [QuerySet] Reference to self.
      def exclude(filters)
        _filter(filters, @exclusion_filters)
      end

      # Select objects according to some criteria.
      # @param filters [Array, Hash] if array, it is considered an disjunction (OR clause),
      #        if a hash, it is considered a conjunction (AND clause).
      # @return [QuerySet] Reference to self.
      def filter(filters)
        _filter(filters, @inclusion_filters)
      end

      # Select the objects according to some criteria.
      def _filter(filters, applied_filters)
        if filters.class == Array
          disjunctions = filters.map do |filter|
            Conjunction.new(@model, filter)
          end
          applied_filters << disjunctions
        elsif filters.class == Hash
          applied_filters << Conjunction.new(@model, filters)
        end
        self
      end

      # @!method all
      # Return a ResultSet with the ActiveRecord objects that match the condition given by the filters.
      # @return [ResultSet] ActiveRecord objects that match the condition given by the filters.
      def all
        return self.class._execute_sql(self.select_sql) if @projection
        return @_select_related.all_with_related(self.class._execute_sql(self.select_sql)) if @_select_related
        @model.find_by_sql(self.select_sql)
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

      def project(*params)
        @projection = params
        self
      end

      def unproject
        @projection = nil
        self
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

      def distinct
        @has_distinct = true
        self
      end

      def order_by(*order)
        @_order = Babik::QuerySet::Order.new(@model, *order)
        self
      end

      def order(*order)
        order_by(*order)
      end

      def for_update
        @lock_type = 'FOR UPDATE'
        self
      end

      def lock
        self.for_update
      end

      def fetch(index, default_value = nil)
        element = self.[](index)
        return element if element
        return default_value if default_value
        raise IndexError, "Index #{index} outside of QuerySet bounds"
      end

      def [](param)
        # Section selection
        if param.class == Range
          offset_ = param.min
          size_ = param.max.to_i - param.min.to_i
          return limit(size: size_, offset: offset_)
        end

        # Element selection
        return limit(size: 1, offset: param).first if param.class == Integer

        raise "Invalid limit passed to query: #{param}"
      end

      def limit(size: nil, offset: 0)
        @offset = offset.to_i
        @number_of_rows_limit = size.to_i
        self
      end

      def update(update_command)
        @update_command = update_command
        @model.connection.execute(self.update_sql)
      end

      def update_sql
        self.project(['id'])
        sql = self._render_sql('update/main.sql.erb')
        self.unproject
        sql
      end

      def delete_sql
        self.project(['id'])
        sql = self._render_sql('delete/main.sql.erb')
        self.unproject
        sql
      end

      def select_sql
        self._render_sql('select/main.sql.erb')
      end

      def to_s
        select_sql
      end

      def self._execute_sql(sql)
        ActiveRecord::Base.connection.exec_query(sql)
      end

      def _sql_left_joins
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
        @aggregations.each do |aggregation|
          left_joins_by_alias.merge!(aggregation.left_joins_by_alias)
        end
        # Merge prefetchs
        left_joins_by_alias.merge!(@_select_related.left_joins_by_alias) if @_select_related
        # Join all left joins and return a string with the SQL code
        left_joins_by_alias.values.map(&:sql).join("\n")
      end

      def _render_sql(template_path)
        render = lambda do |partial_template_path, replacements|
          _base_render_sql(partial_template_path, **replacements)
        end
        _base_render_sql(template_path, queryset: self, render: render)
      end

      def _base_render_sql(template_path, replacements)
        dbms_adapter = @db_conf[:adapter]
        parent_templates_path = "#{__dir__}/templates/"
        dbms_adapter_template_path = "#{parent_templates_path}/#{dbms_adapter}#{template_path}"
        template_path = if File.exist?(dbms_adapter_template_path)
                          dbms_adapter_template_path
                        else
                          "#{parent_templates_path}/default/#{template_path}"
                        end
        template_content = File.read(template_path)
        ERB.new(template_content).result_with_hash(**replacements)
      end
    end
  end
end