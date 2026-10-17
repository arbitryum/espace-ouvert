require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "home offers both products" do
    get root_path

    assert_response :success
    assert_select "a[href=?]", spaces_path
    assert_select "a[href=?]", coworking_path
  end
end
