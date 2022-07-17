# frozen_string_literal: true

class GroupUser < ActiveRecord::Base
  belongs_to :group, inverse_of: :group_users
  belongs_to :user, inverse_of: :group_users
end
