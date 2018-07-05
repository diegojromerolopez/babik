# frozen_string_literal: true

module SQL

  # Implements an abstract join
  class AbstractJoin
    JOIN_TYPE = nil
    attr_reader :alias, :sql

    def initialize(association, association_position, earlier_table_alias = nil)
      @target_table = association.table_name
      owner_table = association.active_record.table_name
      join_keys = association.join_keys
      @foreign_key = join_keys.foreign_key
      @local_key = join_keys.key
      @alias = "#{owner_table}__#{association.name}_#{association_position}"

      @earlier_table_alias = earlier_table_alias
      @earlier_table_alias ||= owner_table

      @join = join
      @where = where
    end

    def join
      raise NotImplementedError, 'Implement this method in your join'
    end

    def where
      raise NotImplementedError, 'Implement this method in your join'
    end
  end

  # Implements a join
  class Join < AbstractJoin
    def join
      %(
      #{self.class::JOIN_TYPE} #{@target_table} #{@alias}
          ON #{@alias}.#{@local_key} = #{@earlier_table_alias}.#{@foreign_key}
      ).delete("\n").gsub(/\s{2,}/, ' ').strip
    end

    def where
      ''
    end
  end

  # Implements a left join
  class LeftJoin < Join
    JOIN_TYPE = 'LEFT JOIN'
  end

  # Implements a from join
  class FromJoin < AbstractJoin
    JOIN_TYPE = nil
    def join
      ''
    end

    def where
      "#{@alias}.#{@local_key} = #{@earlier_table_alias}.#{@foreign_key}"
    end
  end
end