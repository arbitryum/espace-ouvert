require "test_helper"

class GuideReaderTest < ActiveSupport::TestCase
  test "normalizes and validates the email address" do
    assert_equal "lea@example.org", GuideReader.create!(email_address: "  Lea@Example.org ").email_address
    assert_not GuideReader.new(email_address: "not-an-email").valid?
    assert_not GuideReader.new(email_address: "LEA@example.org").valid?
  end

  test "access tokens expire" do
    reader = GuideReader.create!(email_address: "lea@example.org")
    token = reader.generate_token_for(:access)

    assert_equal reader, GuideReader.find_by_token_for(:access, token)
    travel GuideReader::ACCESS_LINK_VALIDITY + 1.minute do
      assert_nil GuideReader.find_by_token_for(:access, token)
    end
  end
end
