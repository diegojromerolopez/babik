# frozen_string_literal: true

module Babik
  module QuerySet
    # Join between two tables
    module Join
      # Class whose mission is to catch an association path and construct all the sequence of LEFT JOINS
      # that lies behind this set of associations.
      class AssociationJoiner
        attr_reader :left_joins_by_alias, :target_alias

        # Read an Array of associations an construct a list of joins.
        # @param associations [Array<ActiveRecord::Associations::Association>] Array of associations.
        def initialize(associations)
          @left_joins_by_alias = {}
          last_table_alias = nil
          associations.each_with_index do |association, association_path_index|
            # Important, this variable will take the last joined table to chain the join, in the first loop, will take
            # the association origin table name.
            last_table_alias ||= association.active_record.table_name
            left_join = Babik::QuerySet::Join.new_from_association(association, association_path_index, last_table_alias)

            @left_joins_by_alias[left_join.target_alias] = left_join
            last_table_alias = left_join.target_alias
          end
          @target_alias = last_table_alias
        end

        # Table alias will be another way of calling target alias,
        #   i.e. the alias of the target table in the join,
        #   i.e. the alias of the last table in the join,
        # @return [String] Target table alias
        def table_alias
          @target_alias
        end
      end
    end
  end
end
