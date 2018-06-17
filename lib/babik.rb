require 'active_record'
require_relative 'babik/queryset'

module Babik

  def self.included(base)
    base.extend Babik::Model
  end

  module Model
    def objects
      QuerySet.new(self)
    end

  end

end


# Include mixin into parent of all active record models (ActiveRecord::Base)
ActiveRecord::Base.send(:include, Babik)
