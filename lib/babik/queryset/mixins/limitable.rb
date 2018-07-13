# frozen_string_literal: true

module Babik
  module QuerySet
    # Limit functionality of QuerySet
    module Limitable

      # Configure a limit this QuerySet
      # @param param [Range, Integer]
      #        If it is a range, first_element..last_element will be selected.
      #        If it is an integer, the element in that position will be returned. No negative number is allowed.
      # @return [QuerySet, ActiveRecord::Base] QuerySet if a slice was passe as parameter,
      #         otherwise an ActiveRecord model.
      def [](param)
        self.send("limit_#{param.class.to_s.downcase}", param)
      rescue NoMethodError
        raise "Invalid limit passed to query: #{param}"
      end

      # Return an element at an index, otherwise:
      # - Return a default value if it has been passed as second argument.
      # - Raise an IndexError exception
      # @param index [Integer] Position of the element want to return. No negative number is allowed.
      # @param default_value [Object] Anything that will be returned if no record is found at the index position.
      # @raise [IndexError] When there is no default value
      def fetch(index, default_value = nil)
        element = self.[](index)
        return element if element
        return default_value if default_value
        raise IndexError, "Index #{index} outside of QuerySet bounds"
      end

      # Configure a limit this QuerySet
      # @param size [Integer] Number of elements to be selected.
      # @param offset [Integer] Position where the selection will start. By default is 0. No negative number is allowed.
      # @return [QuerySet] Reference to this QuerySet.
      def limit(size, offset = 0)
        @_limit = Babik::QuerySet::Limit.new(size, offset)
        self
      end

      private

      # Get one element at a determined position
      # @param position [Integer] Position of the element to be returned.
      # @api private
      # @return [ActiveRecord::Base, nil] ActiveRecord::Base if exists a record in that position, nil otherwise.
      def limit_integer(position)
        limit(1, position).first
      end

      # Get a QuerySet with a slice of the original QuerySet
      # @param param [Range] first_element..last_element will be selected.
      # @api private
      # @return [QuerySet] QuerySet with a slice of the caller QuerySet.
      def limit_range(param)
        offset = param.min
        size = param.max.to_i - param.min.to_i
        limit(size, offset)
      end
    end
  end
end
