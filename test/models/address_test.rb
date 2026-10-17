require "test_helper"

class AddressTest < ActiveSupport::TestCase
  test "OpenStreetMap embed is focused on the address" do
    address = create_address(latitude: 48.8301, longitude: 2.3202)

    assert_equal "https://www.openstreetmap.org/export/embed.html?bbox=2.310200,48.820100,2.330200,48.840100&layer=mapnik&marker=48.8301%2C2.3202",
      address.osm_embed_url
    assert_equal "https://www.openstreetmap.org/?mlat=48.8301&mlon=2.3202#map=16/48.8301/2.3202", address.osm_map_url
  end

  test "no map without coordinates" do
    assert_equal "", create_address.osm_embed_url
  end

  test "search text is normalized" do
    address = create_address(city: "Saint-Étienne", region_name: "Île-de-France")

    assert_includes address.search_text, "saint etienne"
    assert_includes address.search_text, "ile de france"
  end

  test "concise label uses street, postcode and city" do
    address = create_address(
      raw_address: "117 Av. du 8 Mai 1945, 94170 Le Perreux-sur-Marne",
      label: "117, Avenue du 8 Mai 1945, Les Joncs Marins, Parc du Perreux, Le Perreux-sur-Marne, Nogent-sur-Marne, " \
             "Val-de-Marne, Île-de-France, France métropolitaine, 94170, France"
    )

    assert_equal "117 Av. du 8 Mai 1945, 94170 Le Perreux-sur-Marne", address.concise_label
  end

  test "concise label preserves the original house number" do
    address = create_address(
      raw_address: "32 Rue des Bruyères, 93260 Les Lilas",
      label: "32-36, Rue des Bruyères, Les Lilas, Bobigny, Seine-Saint-Denis, Île-de-France, France métropolitaine, 93260, France",
      city: "Les Lilas", postal_code: "93260"
    )

    assert_equal "32 Rue des Bruyères, 93260 Les Lilas", address.concise_label
  end
end
