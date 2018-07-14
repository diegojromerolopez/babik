# frozen_string_literal: true

module Babik
  module QuerySet
    # Functionality related to the UPDATE operation
    module Updatable
      # Runs the update
      # @param update_command [Hash{field: value}] Runs the update query.
      def update(update_command)
        @_update = update_command
        @model.connection.execute(sql.update)
      end
    end
  end
end