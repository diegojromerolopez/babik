# frozen_string_literal: true

require 'babik/queryset/lib/selection/selection'

module Babik
  # QuerySet module
  module QuerySet
    # Manages the order of the QuerySet
    class Order

      attr_reader :order_fields

      # Construct the order manager
      # @param model [ActiveRecord::Base] base model.
      # @param ordering [Array, String, Hash] ordering that will be applied to the QuerySet.
      # @raise [RuntimeError] Invalid type of order
      def initialize(model, *ordering)
        @model = model
        # Convert the types of each order field
        order_as_array_or_pairs = ordering.map do |order|
          if [Hash, String, Symbol].include?(order.class)
            self.send("_order_from_#{order.class.to_s.downcase}", order)
          elsif order.class == Array
            order
          else
            raise "Invalid type of order: #{order}"
          end
        end
        _initialize_field_orders(order_as_array_or_pairs)
      end

      # Get order from string
      # @param order [String] The string of the form 'field1'
      # @api private
      # @return [Array] Conversion of order as string to array.
      def _order_from_string(order)
        [order, :ASC]
      end

      # Get order from symbol
      # @param order [Symbol] The symbol of the form :field1
      # @api private
      # @return [Array] Conversion of order as symbol to array.
      def _order_from_symbol(order)
        _order_from_string(order.to_s)
      end

      # Get order from a hash
      # @param order [Hash] The string of the form <field>: <ORD> (where <ORD> is :ASC or :DESC)
      # @return [Array] Conversion of order as hash to array.
      def _order_from_hash(order)
        raise "More than one key found in order by for class #{self.class}" if order.keys.length > 1
        order_field = order.keys[0]
        order_value = order[order_field]
        [order_field, order_value]
      end

      # Initialize the order paths
      # @api private
      # @return [Array] Conversion of order as hash to array.
      def _initialize_field_orders(order)
        # Check
        @order_fields = []
        order.each_with_index do |order_field_direction, _order_field_index|
          order_field_path = order_field_direction[0]
          order_direction = order_field_direction[1]
          @order_fields << OrderField.new(@model, order_field_path, order_direction)
        end
      end

      # Return an direction inversion of this order
      # e.g.
      #   User, first_name, ASC => invert => User, first_name, DESC
      # @return [Array<OrderField>] Inverted order.
      def invert
        @order_fields.map(&:invert)
      end

      # Invert actual order direction
      def invert!
        @order_fields = self.invert
      end

      # Return the left joins this order include, grouped by alias
      # @return [Hash] Hash with the key equal to alias and the value equals to a Join.
      def left_joins_by_alias
        left_joins_by_alias = {}
        @order_fields.each do |order_field|
          left_joins_by_alias.merge!(order_field.left_joins_by_alias)
        end
        left_joins_by_alias
      end

      # Return sql of the fields to order.
      # Does not include ORDER BY.
      # @return [SQL] SQL code for fields to order.
      def sql
        @order_fields.map(&:sql).join(', ')
      end
    end

    # Each one of the fields that appear in the order statement
    class OrderField
      attr_reader :selection, :direction, :model

      delegate :left_joins_by_alias, to: :selection

      # Construct the OrderField
      # @param model [ActiveRecord::Base] base model.
      # @param field_path [String, Symbol, Selection] field path. If local, it will be one of the attributes,
      #        otherwise will be an association path.
      # @param direction [String, Symbol] :ASC or :DESC (a string will be converted to symbol).
      def initialize(model, field_path, direction)
        direction_sym = direction.to_sym
        unless %i[ASC DESC].include?(direction_sym)
          raise "Invalid order type #{direction} in #{field_path}: Expecting :ASC or :DESC"
        end
        @model = model
        if [String, Symbol].include?(field_path.class)
          @selection = Babik::Selection::Base.factory(@model, field_path, '_')
        elsif field_path.is_a?(Babik::Selection::Base)
          @selection = field_path
        else
          raise "field_path of class #{field_path.class} not valid. A Symbol/String/Babik::Selection::Base expected"
        end
        @direction = direction_sym
      end

      # Return a new OrderField with the direction inverted
      # @return [OrderField] Order field with inverted direction.
      def invert
        inverted_direction = if @direction.to_sym == :ASC
                               :DESC
                             else
                               :ASC
                             end
        OrderField.new(@model, @selection, inverted_direction)
      end

      # Return sql of the field to order.
      # i.e. something like this:
      #   <table_alias>.<field> ASC
      #   <table_alias>.<field> DESC
      # e.g.
      #   users_0.first_name ASC
      #   posts_0.title DESC
      # @return [SQL] SQL code for field to order.
      def sql
        "#{@selection.target_alias}.#{@selection.selected_field} #{@direction}"
      end
    end
  end
end
