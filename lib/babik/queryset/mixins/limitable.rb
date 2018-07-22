# frozen_string_literal: true

module Babik
  module QuerySet
    # Limit functionality of QuerySet
    module Limitable

      # Configure a limit this QuerySet
      # @param param [Range, Integer]
      #        If it is a range, first_element..last_element will be selected.
      #        If it is an integer, the element in that position will be returned. No negative number is allowed.
      # @raise RuntimeError 'Invalid limit passed to query: <VALUE>' If param is not a Range or Integer.
      # @return [QuerySet, ActiveRecord::Base] QuerySet if a slice was passe as parameter,
      #         otherwise an ActiveRecord model.
      def [](param)
        raise "Invalid limit passed to query: #{param}" unless [Range, Integer].include?(param.class)
        self.clone.send("limit_#{param.class.to_s.downcase}!", param)
      end

      # Inform if at least one record is matched by this QuerySet
      # @return [Boolean] True if at least one record matches the conditions of the QuerySet, false otherwise.
      def exists?
        element = self.fetch(0, false)
        return true if element
        false
      end

      # Return an element at an index, otherwise:
      # - Return a default value if it has been passed as second argument.
      # - Raise an IndexError exception
      # @param index [Integer] Position of the element want to return. No negative number is allowed.
      # @param default_value [Object] Anything that will be returned if no record is found at the index position.
      #        By default it takes a nil value (in that case, it will raise the IndexError exception).
      # @raise [IndexError] When there is no default value
      def fetch(index, default_value = nil)
        element = self.[](index)
        return element if element
        return default_value unless default_value.nil?
        raise IndexError, "Index #{index} outside of QuerySet bounds"
      end

      # Configure a limit this QuerySet
      # @param size [Integer] Number of elements to be selected.
      # @param offset [Integer] Position where the selection will start. By default is 0. No negative number is allowed.
      # @return [QuerySet] Reference to this QuerySet.
      def limit!(size, offset = 0)
        @_limit = Babik::QuerySet::Limit.new(size, offset)
        self
      end

      # Destroy the current limit of this QuerySet
      # @return [QuerySet] Reference to this QuerySet.
      def unlimit!
        @_limit = nil
        self
      end

      private

      # Get one element at a determined position
      # @param position [Integer] Position of the element to be returned.
      # @api private
      # @return [ActiveRecord::Base, nil] ActiveRecord::Base if exists a record in that position, nil otherwise.
      def limit_integer!(position)
        @_limit = Babik::QuerySet::Limit.new(1, position)
        self.first
      end

      # Get a QuerySet with a slice of the original QuerySet
      # @param param [Range] first_element..last_element will be selected.
      # @api private
      # @return [QuerySet] QuerySet with a slice of the caller QuerySet.
      def limit_range!(param)
        offset = param.min
        size = param.max.to_i - param.min.to_i
        @_limit = Babik::QuerySet::Limit.new(size, offset)
        self
      end

    end
  end
end
