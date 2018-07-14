# frozen_string_literal: true

module Babik
  module QuerySet
    # Functionality related to the DELETE operation
    module Deletable
      # Delete the selected records
      def delete
        @model.connection.execute(sql.delete)
      end
    end
  end
end