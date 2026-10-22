module HostingRequestsHelper
  # A request's answers as [label, text] pairs, blank ones left out, for the
  # establishment's account and the emails. Includes the message and schedule
  # of requests sent before the questions split.
  def hosting_request_details(request)
    t_label = ->(key) { t("hosting_requests.details.#{key}") }
    details = [
      [t_label[:contact], request.contact_name],
      [t_label[:email], request.email],
      [t_label[:phone], request.phone],
      [t_label[:activity], request.activity],
      [t_label[:website], request.website]
    ]
    details += if request.coworking?
      [
        [t_label[:team_size], request.team_size],
        [t_label[:days_per_week], request.days_per_week],
        [t_label[:weekdays], hosting_request_days(request)],
        [t_label[:needs], hosting_request_needs(request)],
        [t_label[:compensation], request.compensation && request.human_enum_name(:compensation)]
      ]
    else
      [
        [t_label[:space], request.space&.name],
        [t_label[:activity_type], request.activity_type],
        [t_label[:attendees], request.attendees],
        [t_label[:slots], request.slots.join(" ; ")],
        [t_label[:contribution], request.contribution]
      ]
    end
    details += [
      [t_label[:message], request.message],
      [t_label[:schedule], request.schedule],
      [t_label[:extra], request.extra]
    ]
    details.filter_map { |label, value| [label, value.to_s] if value.present? }
  end

  private

  def hosting_request_days(request)
    days = request.weekdays.map { |day| RecurringAvailability.weekday_name(day) }
    days << HostingRequest.human_attribute_name(:flexible_days) if request.flexible_days?
    days.join(", ")
  end

  def hosting_request_needs(request)
    needs = (request.needs - ["other"]).map { |need| t("activerecord.enums.hosting_request.needs.#{need}") }
    needs << request.needs_other if request.needs_other.present?
    needs << t("activerecord.enums.hosting_request.needs.other") if request.needs.include?("other") && request.needs_other.blank?
    needs.join(", ")
  end
end
