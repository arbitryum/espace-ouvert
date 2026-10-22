import { Controller } from "@hotwired/stimulus"
import L from "leaflet"
import "@maplibre/maplibre-gl-leaflet"
import { setWorkerUrl } from "maplibre-gl"

const PARIS = [48.8566, 2.3522]

// MapLibre looks for its worker next to its own file, but assets have
// fingerprinted names: give it the worker's URL from the import map.
setWorkerUrl(import.meta.resolve("maplibre-gl-worker"))

// Leaflet map beside the cards of a directory (spaces, coworking projects).
// Hovering a card highlights its marker. See shared/_directory.html.erb.
export default class extends Controller {
  static targets = ["map", "noMarkers"]
  // markers: {id, title, subtitle, address, distance_km, text, image_url, image_alt, url, full, tag, latitude, longitude}
  // messages: texts from config/locales/fr.yml (shared.directory.popup)
  static values = { markers: Array, messages: Object }

  connect() {
    this.map = L.map(this.mapTarget).setView(PARIS, 12)
    // VersaTiles' muted style (open source, no key): much calmer than
    // OpenStreetMap's own, so the markers stand out. Vector tiles, drawn by
    // MapLibre inside Leaflet.
    L.maplibreGL({
      style: "https://tiles.versatiles.org/assets/styles/muted/style.json",
      // The plugin would otherwise replace it with the style's own credits once
      // loaded, which sometimes come back empty.
      attributionControl: {
        customAttribution: '&copy; <a href="https://versatiles.org" target="_blank">VersaTiles</a> &copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap contributors</a>',
      },
    }).addTo(this.map)

    this.markers = new Map()
    this.bounds = this.markersValue.map((marker) => {
      const leafletMarker = L.marker([marker.latitude, marker.longitude], { title: marker.title })
        .addTo(this.map)
        .on("click", () => { this.viewBeforePopup = { center: this.map.getCenter(), zoom: this.map.getZoom() } })
        .bindPopup(this.popupContent(marker), { maxWidth: 320, minWidth: 240, autoPan: true, className: "directory-map-popup" })
      if (marker.full) leafletMarker.getElement()?.classList.add("is-full")
      this.markers.set(String(marker.id), leafletMarker)
      return [marker.latitude, marker.longitude]
    })
    this.noMarkersTarget.classList.toggle("hidden", this.bounds.length > 0)

    // Return to where the visitor was once they close a popup.
    this.map.on("popupclose", () => {
      if (!this.viewBeforePopup) return
      this.map.setView(this.viewBeforePopup.center, this.viewBeforePopup.zoom, { animate: true })
      this.viewBeforePopup = null
    })

    // The map is hidden on phones in list mode: fit it once it has a size.
    this.fitted = false
    this.resizeObserver = new ResizeObserver(() => this.resize())
    this.resizeObserver.observe(this.mapTarget)
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    this.map?.remove()
  }

  resize() {
    if (this.mapTarget.clientWidth === 0) return
    this.map.invalidateSize()
    if (this.fitted) return

    this.fitted = true
    if (this.bounds.length === 1) {
      this.map.setView(this.bounds[0], 14)
    } else if (this.bounds.length > 1) {
      this.map.fitBounds(this.bounds, { padding: [30, 30] })
    }
  }

  highlight({ params: { id } }) {
    const marker = this.markers.get(String(id))
    if (!marker) return
    marker.getElement()?.classList.add("is-active")
    marker.setZIndexOffset(1000)
  }

  unhighlight({ params: { id } }) {
    const marker = this.markers.get(String(id))
    if (!marker) return
    marker.getElement()?.classList.remove("is-active")
    marker.setZIndexOffset(0)
  }

  popupContent(marker) {
    const wrapper = this.element.ownerDocument.createElement("div")
    wrapper.className = "w-64 bg-base-100 text-base-content p-3 rounded-box"

    if (marker.image_url) {
      const image = this.append(wrapper, "img", "w-full h-32 object-cover rounded-box mb-3")
      image.src = marker.image_url
      image.alt = marker.image_alt || marker.title
    }
    if (marker.tag) this.append(wrapper, "div", "badge badge-neutral badge-sm mb-2", marker.tag)
    this.append(wrapper, "h3", "font-semibold text-base mb-1", marker.title)
    if (marker.subtitle) this.append(wrapper, "p", "text-sm text-base-content mb-2", marker.subtitle)
    if (marker.address) this.append(wrapper, "p", "text-xs text-base-content/90 mb-2", marker.address)
    if (marker.distance_km != null) {
      const distance = Number(marker.distance_km).toFixed(1).replace(".", ",")
      this.append(wrapper, "div", "badge badge-outline badge-sm rounded-sm! mb-2", this.messagesValue.distance.replace("%{distance}", distance))
    }
    if (marker.text) this.append(wrapper, "p", "text-xs text-base-content/90 mb-3 whitespace-pre-wrap", marker.text)
    if (marker.url) {
      const link = this.append(wrapper, "a", "btn btn-sm btn-outline w-full", this.messagesValue.more)
      link.href = marker.url
    }

    return wrapper
  }

  append(parent, tagName, className, text) {
    const element = parent.ownerDocument.createElement(tagName)
    element.className = className
    if (text !== undefined) element.textContent = text
    parent.appendChild(element)
    return element
  }
}
