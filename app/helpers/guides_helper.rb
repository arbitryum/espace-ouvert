module GuidesHelper
  # The page body, with its image placeholders pointing to GuideImagesController.
  # Sanitized again here because admins can edit it.
  def guide_body(page)
    html = page.body.gsub(GuidePage::IMAGE_PLACEHOLDER) { %(src="#{guide_image_path(Regexp.last_match(1))}") }
    sanitize html, tags: GuideImport::ALLOWED_TAGS, attributes: GuideImport::ALLOWED_ATTRIBUTES
  end
end
