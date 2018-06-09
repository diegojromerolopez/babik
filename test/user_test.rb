require 'minitest/autorun'

class UserTest < Minitest::Test

  def setup
    User.create!(first_name: "Flavio", last_name: "Josefo", email: "flaviojosefo@example.com")
  end

  def test_babik_is_loaded
    assert User.method_defined?(:objects)
    assert Post.method_defined?(:objects)
    assert Tag.method_defined?(:objects)
  end

  def test_find
    user = User.find(1)
    assert user != nil
    assert_equal user.first_name, "Flavio"
  end

end