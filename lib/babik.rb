require 'active_record'
require_relative 'babik/queryset'

module BabikModel

  def objects
    QuerySet.new(self.class)
  end

end


# Include mixin into parent of all active record models (ActiveRecord::Base)
ActiveRecord::Base.send(:include, BabikModel)
