# frozen_string_literal: true

module Babik
  module QuerySet
    # Each one of the conditions that can appear in a SQL WHERE.
    module Condition

      # Return the Disjunction or Conjunction according to what class the filters parameter is.
      # @param model [ActiveRecord::Base] Model owner of this condition.
      # @param filter [Array, Hash] if it is an Array, it would be a disjunction.
      #        If a Hash, it would be a conjunction.
      # @raise [RuntimeError] if the class of filters is not an Array or a Hash.
      def self.factory(model, filter)
        if filter.instance_of?(Array)
          return Disjunction.new(model, filter.map { |filter_i| Conjunction.new(model, filter_i) })
        end
        if filter.instance_of?(Hash)
          return Conjunction.new(model, filter)
        end
        raise '`filter\' parameter must be an Array for OR-based AND-conditions or a hash for a lone AND-condition'
      end

      # AND-based condition, also known as conjunction
      class Conjunction
        attr_reader :model, :selections

        # Construct a conjunction condition.
        # @param model [ActiveRecord::Base] Model owner of this condition.
        # @param filter [Hash] a hash where the key identify field paths and the values the values they must take.
        def initialize(model, filter)
          @model = model
          @selections = []
          # filter is a Hash composed by :selection_path => value
          filter.each do |selection_path, value|
            @selections << Babik::Selection::Base.factory(@model, selection_path, value)
          end
        end

        # Return a hash with the joins grouped by alias
        # @return [Hash] alias: SQL::Join object
        def left_joins_by_alias
          left_joins_by_alias_ = {}
          @selections.each do |selection|
            left_joins_by_alias_.merge!(selection.left_joins_by_alias)
          end
          left_joins_by_alias_
        end

        # Return SQL code for this conjunction.
        # e.g
        #   (first_name = 'Julius' AND last_name = 'Caesar' AND zone = 'Rome')
        # @return [String] SQL code that will be used in the WHERE part of SQL SELECT statements.
        def sql
          @selections.map(&:sql_where_condition).join(" AND\n")
        end
      end

    end

    # Disjunction in Disjunctive Normal Form
    # i.e OR-based condition of AND-based conditions (disjunction of conjunctions)
    #
    # See https://en.wikipedia.org/wiki/Disjunctive_normal_form
    #
    # e.g.
    #   (users.filter_name = 'Julius' AND posts.title = 'Stabbed to death: My story') OR
    #   (users.filter_name = 'Marcus Antonius' AND posts.title = 'A sword in my belly button')
    #
    class Disjunction
      attr_reader :model, :conjunctions

      # Construct a conjunction condition.
      # @param model [ActiveRecord::Base] Model owner of this condition.
      # @param conjunctions [Array] array of conjunctions that will be
      #        joined in a disjunction (hence the name Disjunctive Normal Form).
      def initialize(model, conjunctions)
        @model = model
        @conjunctions = conjunctions
      end

      # Return a hash with the joins grouped by alias
      # @return [Hash] alias: SQL::Join object
      def left_joins_by_alias
        left_joins_by_alias_ = {}
        @conjunctions.each do |conjunction|
          left_joins_by_alias_.merge!(conjunction.left_joins_by_alias)
        end
        left_joins_by_alias_
      end

      # Return SQL code for this disjunction.
      # e.g
      #   (first_name = 'Julius' AND last_name = 'Caesar') OR (zone.name = 'Rome')
      # @return [String] SQL code that will be used in the WHERE part of SQL SELECT statements.
      def sql
        "(\n#{@conjunctions.map(&:sql).join(" OR\n")}\n)"
      end
    end

  end
end
