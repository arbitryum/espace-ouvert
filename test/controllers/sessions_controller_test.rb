require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "login page has the password toggle and a registration link" do
    get new_session_path

    assert_response :success
    assert_select "[data-controller=password-visibility] input[name=password]"
    assert_select "a[href=?]", new_registration_path
    assert_select "div.mx-auto.max-w-2xl"
  end

  test "approved establishment signs in" do
    post session_path, params: { username: "approved", password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "pending establishment cannot sign in" do
    post session_path, params: { username: "pending", password: "password" }

    assert_response :unprocessable_entity
    assert_match "Votre compte est en attente de validation.", response.body
    assert_nil cookies[:session_id]
  end

  test "wrong password" do
    post session_path, params: { username: "approved", password: "wrong" }

    assert_response :unprocessable_entity
    assert_match "Identifiant ou mot de passe incorrect.", response.body
  end

  test "sign out" do
    sign_in_as users(:approved)

    delete destroy_session_path

    assert_redirected_to root_path
    assert_empty cookies[:session_id]
  end
end
