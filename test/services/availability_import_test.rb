require "test_helper"

class AvailabilityImportTest < ActiveSupport::TestCase
  def run_import(**options)
    output = StringIO.new
    AvailabilityImport.run(output:, **options)
    output.string
  end

  def slots(space) = space.recurring_availabilities.reload.map { |slot| [slot.weekday, slot.start_time.strftime("%H:%M"), slot.end_time.strftime("%H:%M")] }

  setup do
    @space = create_space(name: "Salle", availability: "Samedi : 8h-14h et 17h-22h")
    @existing = create_space(name: "Bibliothèque", availability: "Le mardi de 9h à 12h")
    @existing.recurring_availabilities.create!(weekday: 0, start_time: "14:00", end_time: "18:00")
    @on_demand = create_space(name: "Sur demande", availability: "À la demande.")
  end

  test "a dry run only prints the proposals" do
    output = run_import

    assert_match "sam 08:00-14:00, sam 17:00-22:00", output
    assert_match "skipped, already has: lun 14:00-18:00", output
    assert_match "not understood: à la demande.", output
    assert_match "Dry run (APPLY=1 to write): 1 created, 1 skipped, 1 without_slots", output
    assert_empty slots(@space)
  end

  test "apply creates slots, leaving spaces that have some" do
    run_import(apply: true)

    assert_equal [[5, "08:00", "14:00"], [5, "17:00", "22:00"]], slots(@space)
    assert_equal [[0, "14:00", "18:00"]], slots(@existing)
    assert_empty slots(@on_demand)
  end

  test "replace overwrites existing slots" do
    run_import(apply: true, replace: true)

    assert_equal [[1, "09:00", "12:00"]], slots(@existing)
  end
end
