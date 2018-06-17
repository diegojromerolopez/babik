# frozen_string_literal: true

module SQL

  class Join
    attr_reader :alias, :sql

    def initialize(join_type, association, earlier_table_alias=nil)
      @join_type = join_type

      target_table = association.table_name
      owner_table = association.active_record.table_name
      join_keys = association.join_keys
      foreign_key = join_keys.foreign_key
      key = join_keys.key
      target_table_alias = "#{owner_table}__#{association.name}"

      if earlier_table_alias.nil?
        earlier_table_alias = owner_table
      end

      @sql = %[
        #{@join_type} #{target_table} #{target_table_alias}
          ON #{target_table_alias}.#{key} = #{earlier_table_alias}.#{foreign_key}
      ].gsub("\n", "").gsub(/\s{2,}/, " ").strip()

      @alias = target_table_alias
    end
  end

end