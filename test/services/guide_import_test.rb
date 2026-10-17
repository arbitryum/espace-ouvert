require "test_helper"

class GuideImportTest < ActiveSupport::TestCase
  setup { GuideImport.run(file_fixture("notion_guide").to_s, output: StringIO.new) }

  test "imports sections and pages in order" do
    assert_equal({"Section A" => ["Première page"], "Section B" => ["Seconde page ?"]},
      GuidePage.sections.transform_values { |pages| pages.map(&:title) })
    page = GuidePage.find_by!(slug: "premiere-page")
    assert_equal "💜", page.icon
    assert page.cover.attached?
  end

  test "keeps safe content and Notion styling hooks" do
    body = GuidePage.find_by!(slug: "premiere-page").body

    assert_includes body, "<strong>tout le monde</strong>"
    assert_includes body, %(<a href="https://example.org/doc" target="_blank" rel="noopener">un document</a>)
    assert_includes body, %(<aside class="callout">)
    assert_includes body, "☐"
  end

  test "drops scripts, inline styles and event handlers" do
    body = GuidePage.find_by!(slug: "premiere-page").body

    assert_no_match(/<script|alert|style=|onclick|id=|dir=/, body)
  end

  test "attaches images and points to them with a placeholder" do
    page = GuidePage.find_by!(slug: "premiere-page")

    assert_equal 1, page.images.count
    assert_includes page.body, %(<img data-guide-image="#{page.images.attachments.first.id}" alt="">)
    assert_no_match(/href="Premi/, page.body)
  end

  test "importing again replaces the pages" do
    GuideImport.run(file_fixture("notion_guide").to_s, output: StringIO.new)

    assert_equal 2, GuidePage.count
  end
end
