# frozen_string_literal: true

module Babik
  module QuerySet
    # Functionality related to the UPDATE operation
    module Updatable
      # Runs the update
      # @param update_command [Hash{field: value}] Runs the update query.
      def update!(update_command)
        clone_ = self.clone
        clone_.project!(:id)
        clone_._update = update_command
        clone_.model.connection.execute(sql.update)
        clone_.unproject!(:id)
        result
      end
    end
  end
end