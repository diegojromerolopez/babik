# frozen_string_literal: true

require 'deep_clone'

module Babik
  module QuerySet
    # Clone operation for the QuerySet
    module Clonable

      # Clone the queryset using ruby_deep_clone {https://github.com/gmodarelli/ruby-deepclone}.
      # @return [QuerySet] Deep copy of this QuerySet.
      def clone
        DeepClone.clone(self)
      end


    end
  end
end