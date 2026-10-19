require "test_helper"

class AdminInvitationsTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "the users list links to the invitation form" do
    sign_in_as users(:admin)

    get madmin_users_path

    assert_select "a[href=?]", new_madmin_admin_invitation_path
  end

  test "is reserved to admins" do
    sign_in_as users(:approved)

    post madmin_admin_invitations_path, params: {admin_invitation: {email_address: "new@example.com"}}

    assert_redirected_to root_path
    assert_nil User.find_by(email_address: "new@example.com")
  end

  test "an admin invites someone, who chooses a password and lands in the back office" do
    sign_in_as users(:admin)
    get new_madmin_admin_invitation_path
    assert_response :success

    post madmin_admin_invitations_path, params: {admin_invitation: {email_address: " New@Example.com "}}

    invited = User.find_by!(email_address: "new@example.com")
    assert invited.admin?
    assert_enqueued_email_with AdminInvitationsMailer, :invitation, args: [invited]
    assert_redirected_to madmin_user_path(invited)

    sign_out
    token = invited.generate_token_for(:invitation)
    get edit_invitation_path(token)
    assert_response :success
    put invitation_path(token), params: {password: "Mot-de-passe-admin-1", password_confirmation: "Mot-de-passe-admin-1"}

    assert_redirected_to madmin_root_path
    assert invited.reload.authenticate("Mot-de-passe-admin-1")
    follow_redirect!
    assert_response :success
  end

  test "inviting an admin again sends a new link without changing the account" do
    sign_in_as users(:admin)
    admin = users(:admin)

    post madmin_admin_invitations_path, params: {admin_invitation: {email_address: admin.email_address}}

    assert_enqueued_email_with AdminInvitationsMailer, :invitation, args: [admin]
    assert admin.reload.authenticate("password")
  end

  test "an establishment's account can't be invited" do
    sign_in_as users(:admin)

    post madmin_admin_invitations_path, params: {admin_invitation: {email_address: "approved@example.com"}}

    assert_response :unprocessable_entity
    assert_match "compte établissement", response.body
    assert_not users(:approved).reload.admin?
    assert_no_enqueued_emails
  end

  test "an invalid email is refused" do
    sign_in_as users(:admin)

    post madmin_admin_invitations_path, params: {admin_invitation: {email_address: "pas-un-email"}}

    assert_response :unprocessable_entity
    assert_no_enqueued_emails
  end

  test "an invalid password shows the errors" do
    token = users(:admin).generate_token_for(:invitation)

    put invitation_path(token), params: {password: "", password_confirmation: ""}

    assert_response :unprocessable_entity
    assert users(:admin).reload.authenticate("password")
  end

  test "the link stops working once the password is chosen" do
    token = users(:admin).generate_token_for(:invitation)
    put invitation_path(token), params: {password: "Mot-de-passe-admin-1", password_confirmation: "Mot-de-passe-admin-1"}
    sign_out

    get edit_invitation_path(token)

    assert_redirected_to new_session_path
    assert_match "plus valable", flash[:alert]
  end

  test "an expired link is refused" do
    token = users(:admin).generate_token_for(:invitation)

    travel User::INVITATION_VALIDITY + 1.minute do
      get edit_invitation_path(token)
    end

    assert_redirected_to new_session_path
  end
end
