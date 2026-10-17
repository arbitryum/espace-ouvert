require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup { @user = users(:approved) }

  test "the sign-in page links to the reset form" do
    get new_session_path

    assert_select "a[href=?]", new_password_path
  end

  test "requesting a reset emails the user" do
    post passwords_path, params: {email_address: " Approved@Example.com "}

    assert_enqueued_email_with PasswordsMailer, :reset, args: [@user]
    assert_redirected_to new_session_path
  end

  test "an unknown email gets the same answer and no email" do
    post passwords_path, params: {email_address: "nobody@example.com"}

    assert_no_enqueued_emails
    assert_redirected_to new_session_path
    assert_match "Si un compte existe", flash[:notice]
  end

  test "the emailed link lets the user choose a new password and signs them out elsewhere" do
    @user.sessions.create!
    token = @user.password_reset_token

    get edit_password_path(token)
    assert_response :success

    put password_path(token), params: {password: "Nouveau-mot-de-passe-1", password_confirmation: "Nouveau-mot-de-passe-1"}

    assert_redirected_to new_session_path
    assert @user.reload.authenticate("Nouveau-mot-de-passe-1")
    assert_empty @user.sessions
  end

  test "an invalid password shows the errors" do
    put password_path(@user.password_reset_token), params: {password: "12345678", password_confirmation: "12345678"}

    assert_response :unprocessable_entity
    assert_match "ne doit pas être uniquement numérique", response.body
    assert @user.reload.authenticate("password")
  end

  test "an empty password is refused" do
    put password_path(@user.password_reset_token), params: {password: "", password_confirmation: ""}

    assert_response :unprocessable_entity
    assert @user.reload.authenticate("password")
  end

  test "the link stops working once used" do
    token = @user.password_reset_token
    put password_path(token), params: {password: "Nouveau-mot-de-passe-1", password_confirmation: "Nouveau-mot-de-passe-1"}

    get edit_password_path(token)

    assert_redirected_to new_password_path
  end

  test "an expired link is refused" do
    token = @user.password_reset_token

    travel User::PASSWORD_RESET_VALIDITY + 1.minute do
      get edit_password_path(token)
    end

    assert_redirected_to new_password_path
    assert_match "plus valable", flash[:alert]
  end
end
