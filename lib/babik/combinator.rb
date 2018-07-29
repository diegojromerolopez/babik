# frozen_string_literal: true

require 'babik/queryset/mixins/aggregatable'
require 'babik/queryset/mixins/bounded'
require 'babik/queryset/mixins/clonable'
require 'babik/queryset/mixins/countable'
require 'babik/queryset/mixins/deletable'
require 'babik/queryset/mixins/distinguishable'
require 'babik/queryset/mixins/none'
require 'babik/queryset/mixins/filterable'
require 'babik/queryset/mixins/limitable'
require 'babik/queryset/mixins/lockable'
require 'babik/queryset/mixins/projectable'
require 'babik/queryset/mixins/related_selector'
require 'babik/queryset/mixins/set_operations'
require 'babik/queryset/mixins/sql_renderizable'
require 'babik/queryset/mixins/sortable'
require 'babik/queryset/mixins/updatable'

require 'babik/queryset/components/aggregation'
require 'babik/queryset/components/limit'
require 'babik/queryset/components/order'
require 'babik/queryset/components/projection'
require 'babik/queryset/components/select_related'
require 'babik/queryset/components/sql_renderer'
require 'babik/queryset/components/where'

require 'babik/queryset/lib/condition'
require 'babik/queryset/lib/selection/config'
require 'babik/queryset/lib/selection/local_selection'
require 'babik/queryset/lib/selection/foreign_selection'
require 'babik/queryset/lib/field'
require 'babik/queryset/lib/update/assignment'

module Babik
  module QuerySet
    module Combinator

      class Operation
        include NoneQuerySet
        include Babik::QuerySet::Aggregatable
        include Babik::QuerySet::Bounded
        include Babik::QuerySet::Clonable
        include Babik::QuerySet::Countable
        include Babik::QuerySet::Deletable
        include Babik::QuerySet::NoneQuerySet
        include Babik::QuerySet::Distinguishable
        include Babik::QuerySet::Filterable
        include Babik::QuerySet::Limitable
        include Babik::QuerySet::Projectable
        include Babik::QuerySet::RelatedSelector
        #include Babik::QuerySet::SetOperations
        include Babik::QuerySet::Sortable
        include Babik::QuerySet::Updatable

        attr_reader :model, :left_node, :right_node, :_count, :_order

        alias count? _count

        def initialize(model, left_node, right_node)
          @model = model
          @_count = false
          @_distinct = false
          @_order = nil
          @_limit = nil
          @_where = Babik::QuerySet::Where.new(@model)
          @left_node = left_node
          @right_node = right_node
        end

        def operation
          self.class.to_s.split('::').last.upcase
        end

      end

      class Difference < Operation

      end

      class Intersection < Operation

      end

      class Union < Operation

      end

    end
  end
end