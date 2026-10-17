# Who may read the coworking guide: signed-in users, and readers who followed
# the link emailed to them (remembered with a signed cookie).
module GuideAccess
  extend ActiveSupport::Concern

  included do
    helper_method :guide_access?
  end

  private

  def guide_access?
    authenticated? || current_guide_reader.present?
  end

  def current_guide_reader
    @current_guide_reader ||= GuideReader.find_by(id: cookies.signed[:guide_reader_id]) if cookies.signed[:guide_reader_id]
  end

  def grant_guide_access(reader)
    cookies.signed.permanent[:guide_reader_id] = {value: reader.id, httponly: true, same_site: :lax}
    reader.touch(:last_accessed_at)
  end
end
