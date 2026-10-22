import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

const PARIS = [48.8566, 2.3522]
const MARKER_SIZE = 22

// Leaflet map next to the list of spaces on the index page. Hovering a card
// highlights its marker.
export default class extends Controller {
  static targets = ["map", "noMarkers"]
  // messages: texts from config/locales/spaces.fr.yml (spaces.map.popup)
  static values = { markers: Array, messages: Object }

  connect() {
    this.map = L.map(this.mapTarget, { scrollWheelZoom: false }).setView(PARIS, 12)
    // Grayed out in CSS (.spaces-map) so the markers stand out.
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    }).addTo(this.map)

    this.markers = new Map()
    this.bounds = this.markersValue.map((marker) => {
      const leafletMarker = L.marker([marker.latitude, marker.longitude], { icon: this.icon(), title: marker.name })
        .addTo(this.map)
        .on("click", () => { this.viewBeforePopup = { center: this.map.getCenter(), zoom: this.map.getZoom() } })
        .bindPopup(this.popupContent(marker), { maxWidth: 320, minWidth: 240, autoPan: true, className: "spaces-map-popup" })
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

  icon() {
    return L.divIcon({
      className: "spaces-map-marker",
      html: "<span></span>",
      iconSize: [MARKER_SIZE, MARKER_SIZE],
      popupAnchor: [0, -MARKER_SIZE / 2],
    })
  }

  popupContent(marker) {
    const wrapper = this.element.ownerDocument.createElement("div")
    wrapper.className = "w-64 bg-base-100 text-base-content p-3 rounded-box"

    if (marker.image_url) {
      const image = this.append(wrapper, "img", "w-full h-32 object-cover rounded-box mb-3")
      image.src = marker.image_url
      image.alt = marker.image_alt || marker.name
    }
    this.append(wrapper, "h3", "font-semibold text-base mb-1", marker.name)
    this.append(wrapper, "p", "text-sm text-base-content mb-2", marker.care_home_name)
    if (marker.address) this.append(wrapper, "p", "text-xs text-base-content/90 mb-2", marker.address)
    if (marker.distance_km != null) {
      const distance = Number(marker.distance_km).toFixed(1).replace(".", ",")
      this.append(wrapper, "div", "badge badge-outline badge-sm rounded-sm! mb-2", this.messagesValue.distance.replace("%{distance}", distance))
    }
    if (marker.availability) this.append(wrapper, "p", "text-xs text-base-content/90 mb-3 whitespace-pre-wrap", marker.availability)
    const link = this.append(wrapper, "a", "btn btn-sm btn-outline w-full", this.messagesValue.more)
    link.href = marker.detail_url

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
