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

  test "is either a file or a web link" do
    link = "https://docs.google.com/document/d/abc/edit?usp=sharing"
    document = SharedDocument.new(title: "Contrat", url: " #{link} ")
    assert document.valid?
    assert_equal link, document.url

    neither = SharedDocument.new(title: "Contrat")
    assert_not neither.valid?
    assert_includes neither.errors[:base], "Ajoutez un fichier ou un lien."

    both = SharedDocument.new(title: "Contrat", url: link, file: fixture_file_upload("document.pdf", "application/pdf"))
    assert_includes both.tap(&:validate).errors[:base], "Choisissez un fichier ou un lien, pas les deux."

    %w[javascript:alert(1) docs.google.com/document mailto:x@example.org].each do |url|
      assert_includes SharedDocument.new(title: "Contrat", url:).tap(&:validate).errors[:url], "doit être une adresse web (https://…)", url
    end
  end
end
