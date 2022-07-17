# frozen_string_literal: true

class Group < ActiveRecord::Base
  has_many :group_users, inverse_of: :group
  has_many :users, through: :group_users, inverse_of: :groups
end
