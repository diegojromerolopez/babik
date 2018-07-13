# frozen_string_literal: true

module Babik
  module QuerySet
    # Lock functionality of QuerySet
    module Lockable

      # Lock the table for writes
      # This must be inside a transaction
      def for_update
        @_lock_type = 'FOR UPDATE'
        self
      end

      # Lock the table for writes
      # This must be inside a transaction
      # @see #for_update Alias of for_update method
      def lock
        self.for_update
      end

      # Check if there is a lock
      # @return [Boolean] True if there is a lock, false otherwise.
      def lock?
        return true if @_lock_type
        false
      end

    end
  end
end