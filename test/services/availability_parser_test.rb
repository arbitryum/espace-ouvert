require "test_helper"

class AvailabilityParserTest < ActiveSupport::TestCase
  def slots(text) = AvailabilityParser.parse(text).slots

  def every(days, from, to) = days.map { |weekday| [weekday, from, to] }

  test "reads day ranges, lists and lines" do
    assert_equal every(0..1, "09:00", "15:00") + every(2..4, "09:00", "19:00") + every(5..6, "09:30", "17:00"),
      slots("- Lundi et mardi de 9h à 15h, \n- Du mercredi au vendredi de 9h à 19h, \n- Samedi et dimanche de 9h30 à 17h.")
    assert_equal every([1, 3, 4], "17:30", "18:30"), slots("Le mardi, le jeudi et le vendredi à partir de 17h30 jusqu'à 18h30")
  end

  test "reads several clauses and several ranges a day" do
    assert_equal [[5, "10:30", "18:00"], [6, "10:30", "12:30"]], slots("Disponible le samedi de 10h30 à 18h et le dimanche de 10h30 à 12h30.")
    assert_equal [[5, "08:00", "14:00"], [5, "17:00", "22:00"]], slots("Samedi : 8h-14h et 17h-22h")
  end

  test "excludes days, the weekend and hours" do
    assert_equal every([0, 1, 2, 3, 6], "17:00", "22:00"), slots("Tous les jours de la semaine à partir de 17h sauf le vendredi et le samedi.")
    assert_equal every(0..4, "16:30", "18:30"), slots("Tout les jours sauf week-end de 16h30 à 18h30")
    assert_equal [[0, "09:00", "12:00"], [0, "14:00", "18:00"]], slots("Tous les jours, toute la journée sauf entre 12h et 14h.").first(2)
    assert_equal [[0, "09:00", "18:00"], [1, "09:00", "12:00"]], slots("Disponible tous les jours de 9h à 18h, sauf le mardi après-midi.").first(2)
  end

  test "la semaine is Monday to Friday, with hours shared across clauses" do
    assert_equal every(0..4, "17:00", "19:30") + every(5..6, "09:00", "19:30"),
      slots("La semaine à partir de 17h à 19h30 et les weekend la journée (jusqu'à 19h30).")
    assert_equal every(0..6, "18:30", "22:00"), slots("Disponible tous les jours de la semaine et le weekend à partir de 18h30")
  end

  test "lists the conventional hours it assumed" do
    result = AvailabilityParser.parse("Lundi : avant 14h, puis 18h-22h\nSamedi : toute la journée")
    assert_equal [[0, "09:00", "14:00"], [0, "18:00", "22:00"], [5, "09:00", "18:00"]], result.slots
    assert_equal %i[open_start moment_hours], result.assumptions

    result = AvailabilityParser.parse("Du lundi au dimanche de 17h00 à 19h45-20h.")
    assert_equal every(0..6, "17:00", "20:00"), result.slots
    assert_equal [:approximate_time], result.assumptions

    assert_equal [:no_hours], AvailabilityParser.parse("Disponible tous les jours.").assumptions
  end

  test "merges moments of the same day" do
    assert_equal every([1, 2, 5, 6], "09:00", "22:00"), slots("Disponible le mardi, mercredi, samedi et dimanche la journée et en soirée.")
  end

  test "reports what it doesn't understand" do
    result = AvailabilityParser.parse("Disponible à la demande.")
    assert_empty result.slots
    assert_equal ["à la demande."], result.unparsed
  end
end
