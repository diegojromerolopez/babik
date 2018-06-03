require 'minitest/autorun'

class UserTest < Minitest::Test

  def setup
    User.create!(first_name: "Flavio", last_name: "Josefo", email: "flaviojosefo@example.com")
  end

  def test_find
    user = User.find(1)
    assert user != nil
    assert_equal user.first_name, "Flavio"
  end

end