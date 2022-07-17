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

      # Clone this QuerySet and apply the 'mutator_method' to it.
      # @param mutator_method [Symbol] Name of the method.
      # @param parameters [Array] Parameters passed to the method
      # @return [QuerySet::Clonable] The resultant QuerySet of applying the mutator to the clone of the caller object.
      def mutate_clone(mutator_method, parameters = [])
        clone_ = clone
        if parameters.empty?
          clone_.send(mutator_method)
        else
          clone_.send(mutator_method, *parameters)
        end
        clone_
      end

      # Check if the called method has a modifying version (a bang method). If that is the case
      # it will be called on a clone of this instance. Otherwise, super will be called.
      # @param name [String] method name
      # @param args [String] method arguments
      # @param _block [Proc] Proc that could be passed to the method. Not used.
      # @return [QuerySet::Clonable] Clone of this QuerySet (with method 'name' called on ), an empty QuerySet.
      def method_missing(name, *args, &)
        modifying_method = "#{name}!"
        return mutate_clone(modifying_method.to_sym, args) if self.respond_to?(modifying_method)
        super
      end

      # Check if the called method has a modifying version (a bang method).
      # @return [Boolean] True if  there is a modifying method with the requested method name
      #         in that case, return true, otherwise, return false.
      def respond_to_missing?(name, *_args, &)
        modifying_method = "#{name}!"
        self.respond_to?(modifying_method)
      end
    end
  end
end
