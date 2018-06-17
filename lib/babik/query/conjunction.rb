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

  def sql_left_joins
    left_joins_by_alias = {}
    @selections.each do |selection|
      if selection.respond_to?('left_joins_by_alias')
        left_joins_by_alias.merge!(selection.left_joins_by_alias)
      end
    end
    left_joins_by_alias.values.map{ |join| join.sql }.join("\n")
  end

  def sql_where_condition
    @selections.map {|selection| selection.sql_where_condition}.join(" AND\n")
  end

end