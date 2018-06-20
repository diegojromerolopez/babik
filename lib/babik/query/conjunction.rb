# frozen_string_literal: true

require 'erb'

class Conjunction

  attr_reader :model, :selections

  def initialize(model, filters)
    @model = model
    @selections = []
    filters.each do |selection_path, value|
      @selections << Selection.factory(@model, selection_path, value)
    end
  end

  def left_joins_by_alias
    left_joins_by_alias_ = {}
    @selections.each do |selection|
      if selection.respond_to?('left_joins_by_alias')
        left_joins_by_alias_.merge!(selection.left_joins_by_alias)
      end
    end
    left_joins_by_alias_
  end

  def sql_where_condition
    @selections.map(&:sql_where_condition).join(" AND\n")
  end

end