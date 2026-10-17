import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

const PARIS = [48.8566, 2.3522]

// Leaflet map of the spaces listed on the index page.
export default class extends Controller {
  static values = { markers: Array }

  connect() {
    this.map = L.map(this.element).setView(PARIS, 12)
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap contributors",
    }).addTo(this.map)

    const bounds = this.markersValue.map((marker) => {
      L.marker([marker.latitude, marker.longitude])
        .addTo(this.map)
        .on("click", () => { this.viewBeforePopup = { center: this.map.getCenter(), zoom: this.map.getZoom() } })
        .bindPopup(this.popupContent(marker), { maxWidth: 320, minWidth: 240, autoPan: true, className: "spaces-map-popup" })
      return [marker.latitude, marker.longitude]
    })

    // Return to where the visitor was once they close a popup.
    this.map.on("popupclose", () => {
      if (!this.viewBeforePopup) return
      this.map.setView(this.viewBeforePopup.center, this.viewBeforePopup.zoom, { animate: true })
      this.viewBeforePopup = null
    })

    if (bounds.length === 1) {
      this.map.setView(bounds[0], 14)
    } else if (bounds.length > 1) {
      this.map.fitBounds(bounds, { padding: [30, 30] })
    }
  }

  disconnect() {
    this.map?.remove()
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
      this.append(wrapper, "div", "badge badge-outline badge-sm rounded-sm! mb-2", `à ${distance} km`)
    }
    if (marker.availability) this.append(wrapper, "p", "text-xs text-base-content/90 mb-3 whitespace-pre-wrap", marker.availability)
    const link = this.append(wrapper, "a", "btn btn-sm btn-outline w-full", "Plus d'infos")
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
