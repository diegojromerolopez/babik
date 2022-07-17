# frozen_string_literal: true

module Babik
  module QuerySet
    # Join between two tables
    module Join
      # Construct a new Join from an association
      # @param association Association between two ActiveRecord::Base objects.
      # @param association_position Association position. Used when the relationship is a many-to-many through.
      # @param origin_table_alias Alias of table that is the origin of the join.
      # @param join [LeftJoin] Join class.
      # @return [LeftJoin] object with the join for this association.
      def self.new_from_association(association, association_position, origin_table_alias, join = LeftJoin)
        owner_table = association.active_record.table_name
        target_table_alias = "#{owner_table}__#{association.name}_#{association_position}"
        join_keys = association.join_keys

        target_table = TargetTable.new(association.table_name, target_table_alias, join_keys.key)
        origin_table = OriginTable.new(origin_table_alias, join_keys.foreign_key)

        join.new(target_table, origin_table)
      end

      # A table join
      class AbstractJoin
        attr_reader :target_table, :origin_table, :sql

        # Construct a Join
        # @param target_table [Babik::QuerySet::Join::TargetTable] target table of the join.
        # @param origin_table [Babik::QuerySet::Join::OriginTable] origin table of the join.
        def initialize(target_table, origin_table)
          @target_table = target_table
          @origin_table = origin_table
          _init_sql
        end

        # Initialize SQL of the JOIN
        def _init_sql
          # Create the SQL code of the join
          @sql = %(
          #{self.class::JOIN_TYPE} JOIN #{@target_table.name} #{@target_table.table_alias}
              ON #{@target_table.table_alias}.#{@target_table.key} = #{@origin_table.table_alias}.#{@origin_table.key}
          ).delete("\n").gsub(/\s{2,}/, ' ').strip
        end

        # Return the target table alias.
        # @return [String] Target table alias.
        def target_alias
          @target_table.table_alias
        end
      end

      # Left join between tables
      class LeftJoin < AbstractJoin
        JOIN_TYPE = 'LEFT'
      end

      # Target table of the join
      class TargetTable
        attr_reader :name, :table_alias, :key

        # Constructor
        # @param name [String] target table name
        # @param table_alias [String] target table alias
        # @param key [String] field that serves as key in the target table.
        def initialize(name, table_alias, key)
          @name = name
          @table_alias = table_alias
          @key = key
        end
      end

      # Origin table of the join
      class OriginTable
        attr_reader :table_alias, :key

        # Constructor
        # @param table_alias [String] origin table alias
        # @param key [String] field that serves as key.
        def initialize(table_alias, key)
          @table_alias = table_alias
          @key = key
        end
      end
    end
  end
end
