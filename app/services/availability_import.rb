# Turns the free-text availability of spaces into weekly slots (see
# AvailabilityParser), for bin/rails spaces:parse_availability. Prints what it
# would create, and writes only with apply. Spaces that already have slots are
# left alone unless replace is set.
class AvailabilityImport
  DAY_LABELS = %w[lun mar mer jeu ven sam dim].freeze
  GUESSES = {
    open_end: "no end time, ends at 22:00",
    open_start: "no start time, starts at 09:00",
    moment_hours: "journée 09:00-18:00, matin until 12:00, soirée 18:00-22:00",
    no_hours: "no hours, the whole day (09:00-18:00)",
    approximate_time: "approximate time, kept the later one"
  }.freeze

  def self.run(...) = new(...).run

  def initialize(apply: false, replace: false, output: $stdout)
    @apply = apply
    @replace = replace
    @output = output
  end

  def run
    counts = Hash.new(0)
    Space.includes(:recurring_availabilities).order(:id).each do |space|
      counts[import(space)] += 1
    end
    @output.puts
    @output.puts "#{@apply ? "Applied" : "Dry run (APPLY=1 to write)"}: " + counts.map { |status, count| "#{count} #{status}" }.join(", ")
  end

  private

  def import(space)
    result = AvailabilityParser.parse(space.availability)
    existing = space.recurring_availabilities.to_a

    @output.puts "##{space.id} #{space.name}: #{space.availability.squish}"
    @output.puts "  proposed: #{describe(result.slots)}"
    @output.puts "  guesses: #{result.assumptions.map { |assumption| GUESSES.fetch(assumption) }.join("; ")}" if result.assumptions.any?
    @output.puts "  not understood: #{result.unparsed.join(" | ")}" if result.unparsed.any?

    if result.slots.empty?
      :without_slots
    elsif existing.any? && !@replace
      @output.puts "  skipped, already has: #{describe(existing.map { |slot| [slot.weekday, slot.start_time.strftime("%H:%M"), slot.end_time.strftime("%H:%M")] })}"
      :skipped
    else
      save(space, result.slots) if @apply
      existing.any? ? :replaced : :created
    end
  end

  def save(space, slots)
    Space.transaction do
      space.recurring_availabilities.destroy_all
      slots.each { |weekday, start_time, end_time| space.recurring_availabilities.create!(weekday:, start_time:, end_time:) }
    end
  end

  def describe(slots)
    return "-" if slots.empty?

    slots.map { |weekday, start_time, end_time| "#{DAY_LABELS[weekday]} #{start_time}-#{end_time}" }.join(", ")
  end
end
