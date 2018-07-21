# frozen_string_literal: true

module Babik
  module Selection
    # Selection configuration
    class Config
      # Relationship separator string
      # e.g.
      #  - author::first_name__iregex where author is the association, first_name is the field and iregex the operator
      #  - posts::tags::name__contains where posts is related with tags and (tag) name is the field
      #    and contains the operator.
      RELATIONSHIP_SEPARATOR = '::'

      # Operator separator string
      # e.g. first_name__iregex where first_name is the field an iregex the operator
      OPERATOR_SEPARATOR = '__'
    end
  end
end