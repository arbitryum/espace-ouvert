require "test_helper"

class SharedDocumentTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  test "needs a title and a PDF or text document" do
    document = SharedDocument.new(file: fixture_file_upload("photo.jpg", "image/jpeg"))

    assert_not document.valid?
    assert document.errors[:title].any?
    assert_includes document.errors[:file], "doit être un PDF, un document Word ou OpenDocument"
    assert SharedDocument.new(title: "Contrat d'accueil", file: fixture_file_upload("document.pdf", "application/pdf")).valid?
  end

  test "lists published documents in order" do
    file = -> { fixture_file_upload("document.pdf", "application/pdf") }
    guide = SharedDocument.create!(title: "Guide du bien vivre ensemble", position: 2, published: true, file: file.call)
    contract = SharedDocument.create!(title: "Contrat d'accueil", position: 1, published: true, file: file.call)
    SharedDocument.create!(title: "Brouillon", published: false, file: file.call)

    assert_equal [contract, guide], SharedDocument.visible.to_a
  end
end
