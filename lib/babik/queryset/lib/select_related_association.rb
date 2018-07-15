# frozen_string_literal: true

require 'babik/queryset/lib/join'
require 'babik/queryset/lib/selection'
require 'babik/queryset/lib/association_joiner'

class SelectRelatedAssociation
  RELATIONSHIP_SEPARATOR = ::Selection::RELATIONSHIP_SEPARATOR
  attr_reader :model, :association_path, :associations, :target_model, :id

  delegate :left_joins_by_alias, to: :@association_joiner
  delegate :target_alias, to: :@association_joiner

  def initialize(model, association_path)
    @model = model
    @association_path = association_path
    @association_path_parts = association_path.to_s.split(RELATIONSHIP_SEPARATOR)
    @id = @association_path_parts.join('__')
    @target_model = nil

    _initialize_associations
    _initialize_association_joins
  end

  def _initialize_associations
    @associations = []
    associated_model_i = @model
    @association_path_parts.each do |association_i_name|
      association_i = associated_model_i.reflect_on_association(association_i_name.to_sym)
      unless association_i
        raise "Bad association path: #{association_i_name} not found " \
              "in model #{associated_model_i} when constructing select_related for #{@model} objects"
      end

      # To one relationship
      if association_i.belongs_to? || association_i.has_one?
        @associations << association_i
        associated_model_i = association_i.klass
        @target_model = associated_model_i
      else
        raise "Bad association path: #{association_i_name} in model #{associated_model_i} " \
              "is not belongs_to or has_one when constructing select_related for #{@model} objects"
      end
    end
  end

  def _initialize_association_joins
    @association_joiner = Babik::QuerySet::AssociationJoiner.new(@associations)
  end

end