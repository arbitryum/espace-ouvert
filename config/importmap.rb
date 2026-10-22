# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@maplibre/maplibre-gl-leaflet", to: "@maplibre--maplibre-gl-leaflet.js" # @0.1.4
pin "maplibre-gl" # @6.13.0
# Not managed by bin/importmap: download dist/maplibre-gl-worker.mjs again when
# updating maplibre-gl. directory_map_controller.js hands its URL to MapLibre.
pin "maplibre-gl-worker", preload: false # @6.13.0
pin "leaflet" # @1.9.4
