# Imports the coworking guide from a Notion "HTML" export: the home page lists
# the sections and their pages, each page is an HTML file next to a folder of
# images. Replaces every GuidePage.
class GuideImport
  ALLOWED_TAGS = %w[p br h2 h3 h4 strong em u s mark a ul ol li table thead tbody tr th td
    figure figcaption img details summary aside div blockquote hr code].freeze
  ALLOWED_ATTRIBUTES = %w[href src alt class open target rel].freeze
  # Notion classes kept for styling (see app/assets/tailwind/application.css).
  ALLOWED_CLASSES = %w[callout column-list column to-do-list toggle highlight-purple block-color-purple].freeze

  # Paths from ENV come as binary strings; Notion names are UTF-8 (accents).
  def self.run(dir, output: $stdout) = new(Pathname(dir.dup.force_encoding("UTF-8")), output).run

  def initialize(dir, output)
    @dir = dir
    @output = output
  end

  def run
    index = @dir.glob("*.html").first or raise ArgumentError, "No Notion export in #{@dir}"
    entries = table_of_contents(index)

    GuidePage.transaction do
      GuidePage.destroy_all
      entries.each { |entry| import_page(**entry) }
    end
    @output.puts "Imported #{GuidePage.count} guide pages in #{entries.pluck(:section).uniq.size} sections."
  end

  private

  def table_of_contents(index)
    document = Nokogiri::HTML5(index.read)
    document.css(".collection-content").select { it.at_css(".collection-title") }.each_with_index.flat_map do |collection, section_position|
      section = collection.at_css(".collection-title").text.squish
      collection.css("td.cell-title a").each_with_index.map do |link, position|
        {
          section:, section_position:, position:,
          path: index.dirname.join(CGI.unescape(link["href"])),
          title: link.text.squish,
          icon: link.at_css(".icon")&.[]("data-emoji").to_s
        }
      end
    end
  end

  def import_page(section:, section_position:, position:, path:, title:, icon:)
    document = Nokogiri::HTML5(path.read)
    page = GuidePage.create!(section:, section_position:, position:, title:, icon:, slug: title.parameterize)

    if (cover = document.at_css("header img.page-cover-image"))
      page.cover.attach(image_upload(path.dirname.join(CGI.unescape(cover["src"]))))
    end

    body = document.at_css(".page-body")
    body.css("img").each do |img|
      page.images.attach(image_upload(path.dirname.join(CGI.unescape(img["src"]))))
      img.replace(%(<img data-guide-image="#{page.images.attachments.last.id}" alt="">))
    end
    clean(body)
    page.update!(body: sanitize(body.inner_html).squish)
    @output.puts "  ✓ #{section} / #{title} (#{page.images.count} images)"
  end

  def clean(body)
    # The sanitizer would keep their text.
    body.css("script, style").remove
    # Notion wraps images in links to the image file itself.
    body.css("a").each { |link| link.replace(link.children) unless link["href"].to_s.start_with?("http") }
    body.css("a").each do |link|
      link["target"] = "_blank"
      link["rel"] = "noopener"
    end
    body.css("input[type=checkbox]").each { it.replace("☐ ") }
    body.css("[class]").each do |element|
      classes = element["class"].split & ALLOWED_CLASSES
      classes.empty? ? element.remove_attribute("class") : element["class"] = classes.join(" ")
    end
  end

  def sanitize(html)
    Rails::HTML5::SafeListSanitizer.new.sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES + %w[data-guide-image])
  end

  # Browsers can't display HEIC photos: convert them to JPEG.
  def image_upload(file)
    if file.extname.casecmp?(".heic")
      jpeg = Vips::Image.new_from_file(file.to_s).autorot.jpegsave_buffer(Q: 85)
      {io: StringIO.new(jpeg), filename: "#{file.basename(".*")}.jpg", content_type: "image/jpeg"}
    else
      {io: file.open, filename: file.basename.to_s}
    end
  end
end
