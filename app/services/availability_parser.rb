# Reads the free-text availability of a space ("Du lundi au vendredi de 14h à
# 19h", "Samedi : 8h-14h et 17h-22h") into weekly slots, for the
# spaces:parse_availability task. Vague phrases get conventional hours, and
# every such guess is listed in the result's assumptions for an admin to check.
class AvailabilityParser
  Result = Data.define(:slots, :assumptions, :unparsed)

  DAYS = %w[lundi mardi mercredi jeudi vendredi samedi dimanche].freeze
  ALL_DAYS = (0..6).to_a.freeze
  WEEKDAYS = (0..4).to_a.freeze
  WEEKEND = [5, 6].freeze

  # Minutes since midnight.
  DAY_START = 9 * 60
  DAY_END = 18 * 60
  EVENING_END = 22 * 60
  MOMENTS = {
    "matin" => [DAY_START, 12 * 60],
    "après-midi" => [12 * 60, DAY_END],
    "journée" => [DAY_START, DAY_END],
    "soir" => [DAY_END, EVENING_END]
  }.freeze

  DAY = "(?:#{DAYS.join("|")})s?"
  ARTICLE = "(?:le |la |les )?"
  DAY_LIST = "#{DAY}(?:\\s*,\\s*#{ARTICLE}#{DAY})*"
  TIME = "\\d{1,2}\\s*h(?:\\d{2})?"
  MOMENT = "toute la journée|la journée|journée|après-midi|matin|soirée|soir"

  def self.parse(text) = new(text).parse

  def initialize(text)
    @text = text.to_s
    @assumptions = []
    @unparsed = []
  end

  # slots: [[weekday, "HH:MM", "HH:MM"], …], weekday 0 = Monday, sorted and merged.
  def parse
    slots = Hash.new { |hash, weekday| hash[weekday] = [] }
    segments(normalize(@text)).each do |segment|
      parse_segment(segment).each { |weekday, range| slots[weekday] << range }
    end

    Result.new(slots: format_slots(slots), assumptions: @assumptions.uniq, unparsed: @unparsed)
  end

  private

  def normalize(text)
    text = text.downcase.unicode_normalize(:nfc)
      .gsub(/\btout les\b/, "tous les").gsub(/\bweek-?ends?\b/, "weekend")
      .gsub(/\bdisponibles?\b/, " ").gsub(/[()]/, " ")
    # "à 19h45-20h", "19h30/20h": an approximate time, not a range.
    text = text.gsub(/(à\s+)(#{TIME})\s*-\s*(#{TIME})/o) { assume(:approximate_time, "#{$1}#{$3}") }
    text = text.gsub(/(#{TIME})\s*\/\s*#{TIME}/o) { assume(:approximate_time, $1) }
    text = text.gsub(/entre\s+(#{TIME})\s+et\s+(#{TIME})/o) { "#{$1}-#{$2}" }
    # "lundi et le mardi" is one list of days, not two clauses.
    text.gsub(/(#{DAY})\s+et\s+#{ARTICLE}(?=#{DAY})/o) { "#{$1}, " }
  end

  # Clauses, each with its days and hours. A clause with days but no hours
  # takes the hours of the next one ("la semaine et le weekend à partir de
  # 18h"); one with hours but no days adds them to the previous one
  # ("Samedi : 8h-14h et 17h-22h").
  def segments(text)
    segments = []
    pending = ""
    text.split("\n").each do |line|
      line.sub(/\A\s*-\s*/, "").split(/\s+et\s+|,\s*puis\s+/).each do |part|
        days = days?(part)
        hours = hours?(part)
        if days && !hours
          pending += " #{part}"
        elsif !days && pending.empty? && segments.any?
          segments.last << " #{part}"
        else
          segments << "#{pending} #{part}"
          pending = ""
        end
      end
    end
    segments << pending if pending.present?
    segments.map(&:squish).compact_blank
  end

  def days?(text) = text.match?(/#{DAY}|tous les jours|\bsemaine\b|\bweekend\b/o)

  def hours?(text) = text.match?(/#{TIME}|#{MOMENT}/o)

  def parse_segment(segment)
    text, excluded_days, removed_by_day, removed = take_exclusions(segment)
    days = take_days(text) - excluded_days
    if days.empty?
      @unparsed << segment
      return []
    end

    ranges = take_ranges(text)
    days.flat_map do |weekday|
      day_ranges = subtract(ranges, removed + removed_by_day.fetch(weekday, []))
      day_ranges.map { |range| [weekday, range] }
    end
  end

  # "sauf le mardi", "sauf weekend", "sauf le mardi après-midi", "sauf 12h-14h".
  def take_exclusions(text)
    excluded_days = []
    removed_by_day = {}
    removed = []
    text = text.gsub(/sauf\s+(?:le\s+)?weekend/) do
      excluded_days.concat(WEEKEND)
      " "
    end
    text = text.gsub(/sauf\s+#{ARTICLE}(#{DAY_LIST})(?:\s+(#{MOMENT}))?/o) do
      days = day_names($1)
      if $2
        days.each { |weekday| (removed_by_day[weekday] ||= []) << moment_range($2) }
      else
        excluded_days.concat(days)
      end
      " "
    end
    text = text.gsub(/sauf\s+(#{TIME})\s*-\s*(#{TIME})/o) do
      removed << [minutes($1), minutes($2)]
      " "
    end
    [text, excluded_days, removed_by_day, removed]
  end

  def take_days(text)
    days = []
    text = text.gsub(/du\s+(#{DAY})\s+au\s+(#{DAY})/o) do
      first, last = day_names($1).first, day_names($2).first
      days.concat((first <= last) ? (first..last).to_a : (first..6).to_a + (0..last).to_a)
      " "
    end
    text = text.gsub(/tous les jours(?: de la semaine)?/) do
      days.concat(ALL_DAYS)
      " "
    end
    days.concat(WEEKDAYS) if text.match?(/\bsemaine\b/)
    days.concat(WEEKEND) if text.match?(/\bweekend\b/)
    days.concat(day_names(text))
    days.uniq.sort
  end

  def take_ranges(text)
    ranges = []
    text.scan(/(?:à partir de|de|après)\s+(#{TIME})\s*(?:à|jusqu'à|-)\s*(#{TIME})|(#{TIME})\s*-\s*(#{TIME})|(?:à partir de|après)\s+(#{TIME})|avant\s+(#{TIME})/o) do
      from, to, range_from, range_to, open_from, before = $~.captures
      if from
        ranges << [minutes(from), minutes(to)]
      elsif range_from
        ranges << [minutes(range_from), minutes(range_to)]
      elsif open_from
        assume(:open_end)
        ranges << [minutes(open_from), [EVENING_END, minutes(open_from) + 60].max]
      else
        assume(:open_start)
        ranges << [DAY_START, minutes(before)]
      end
    end
    return ranges if ranges.any?

    moments = text.scan(/#{MOMENT}/o).map { |moment| moment_range(moment) }
    if moments.empty?
      assume(:no_hours)
      moments = [MOMENTS.fetch("journée")]
    else
      assume(:moment_hours)
    end
    until_time = text[/jusqu'à\s+(#{TIME})/o, 1]
    moments = moments.map { |from, _| [from, minutes(until_time)] } if until_time
    moments
  end

  def moment_range(moment)
    key = MOMENTS.keys.find { |name| moment.include?(name) }
    MOMENTS.fetch(key || "soir")
  end

  def day_names(text) = text.scan(/(#{DAY})/o).flatten.map { |name| DAYS.index(name.delete_suffix("s")) }

  def minutes(time)
    hours, minutes = time.delete(" ").split("h")
    hours.to_i * 60 + minutes.to_i
  end

  # Ranges minus the removed ones ("tous les jours sauf entre 12h et 14h").
  def subtract(ranges, removed)
    removed.reduce(ranges) do |remaining, (cut_from, cut_to)|
      remaining.flat_map do |from, to|
        [[from, [to, cut_from].min], [[from, cut_to].max, to]].select { |start, finish| start < finish }
      end
    end
  end

  def format_slots(slots)
    slots.sort.flat_map do |weekday, ranges|
      merge(ranges).map { |from, to| [weekday, format_time(from), format_time(to)] }
    end
  end

  def merge(ranges)
    ranges.sort.each_with_object([]) do |(from, to), merged|
      if merged.any? && from <= merged.last[1]
        merged.last[1] = [merged.last[1], to].max
      else
        merged << [from, to]
      end
    end
  end

  def format_time(minutes) = format("%02d:%02d", minutes / 60, minutes % 60)

  def assume(assumption, replacement = nil)
    @assumptions << assumption
    replacement
  end
end
