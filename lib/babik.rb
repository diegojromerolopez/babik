# frozen_string_literal: true

require 'active_record'
require_relative 'babik/queryset'

# Babik module
module Babik

  def self.included(base)
    base.send :include, InstanceMethods
    base.extend ClassMethods
  end

  # All instance methods that are injected to ActiveRecord models
  module InstanceMethods
    # Get a queryset that contains the foreign model filtered by the current instance
    # @param [String] association_name Association name whose objects we want to return.
    # @return [QuerySet] QuerySet with the foreign objects filtered by this instance.
    def objects(association_name)
      association = self.class.reflect_on_association(association_name.to_sym)
      # If the relationship is belongs_to or has_one, return a lone ActiveRecord model
      return self.send(association_name.to_sym) if association.belongs_to? || association.has_one?

      # has_many relationship
      target = Object.const_get(association.class_name)
      begin
        inverse_relationship = association.options.fetch(:inverse_of)
      rescue KeyError => _exception
        raise "Relationship #{association.name} of model #{self.class} has no inverse_of option."
      end
      target.objects.filter("#{inverse_relationship}::id": self.id)
    end
  end

  # All class methods that are injceted to ActiveRecord models
  module ClassMethods
    def objects
      QuerySet.new(self)
    end

  end

end


# Include mixin into parent of all active record models (ActiveRecord::Base)
ActiveRecord::Base.send(:include, Babik)
