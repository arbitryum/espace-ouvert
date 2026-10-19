require "test_helper"

class SignOutTest < ActionDispatch::IntegrationTest
  test "a signed-in user signs out from the account bar" do
    user = users(:approved)
    sign_in_as user

    get root_path
    assert_select "form[action='#{destroy_session_path}'] button", text: I18n.t("shared.account_bar.sign_out")
    assert_select "a[href='#{madmin_root_path}']", count: 0

    assert_difference -> { user.sessions.count }, -1 do
      delete destroy_session_path
    end
    assert_redirected_to root_path

    get madmin_root_path
    assert_redirected_to new_session_path
  end

  test "visitors see no account bar" do
    get root_path

    assert_select "form[action='#{destroy_session_path}']", count: 0
  end

  test "admins get a link to the back office" do
    sign_in_as users(:admin)

    get root_path

    assert_select "a[href='#{madmin_root_path}']", text: I18n.t("shared.account_bar.back_office")
  end

  test "admins sign out from the back office" do
    admin = users(:admin)
    sign_in_as admin

    get madmin_root_path
    assert_select "#sidebar footer form[action='#{destroy_session_path}'] button", text: I18n.t("admin.account.sign_out")

    assert_difference -> { admin.sessions.count }, -1 do
      delete destroy_session_path
    end

    get madmin_root_path
    assert_redirected_to new_session_path
  end
end
