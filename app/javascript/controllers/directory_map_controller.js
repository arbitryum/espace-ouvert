import { Controller } from "@hotwired/stimulus"
import L from "leaflet"
import "@maplibre/maplibre-gl-leaflet"
import { setWorkerUrl } from "maplibre-gl"

const PARIS = [48.8566, 2.3522]

// MapLibre looks for its worker next to its own file, but assets have
// fingerprinted names: give it the worker's URL from the import map.
setWorkerUrl(import.meta.resolve("maplibre-gl-worker"))

// Asked once per page: each test creates a WebGL context, which browsers cap.
let webgl2 = null
function webgl2Available() {
  if (webgl2 === null) {
    const gl = document.createElement("canvas").getContext("webgl2")
    gl?.getExtension("WEBGL_lose_context")?.loseContext()
    webgl2 = Boolean(gl)
  }
  return webgl2
}

// Leaflet map beside the cards of a directory (spaces, coworking projects).
// Hovering a card highlights its marker. See shared/_directory.html.erb.
export default class extends Controller {
  static targets = ["map", "noMarkers"]
  // markers: {id, title, subtitle, address, distance_km, text, image_url, image_alt, url, full, tag, latitude, longitude}
  // messages: texts from config/locales/fr.yml (shared.directory.popup)
  static values = { markers: Array, messages: Object }

  connect() {
    this.map = L.map(this.mapTarget).setView(PARIS, 12)
    this.backgroundLayer().addTo(this.map)

    // Spaces of one care home share its coordinates: pins on top of each other
    // would hide all but one, so each place gets one pin listing them all.
    // this.markers maps every card's id to its place's pin, for highlighting.
    this.markers = new Map()
    this.bounds = this.groupByPlace(this.markersValue).map((group) => {
      const [first] = group
      const leafletMarker = L.marker([first.latitude, first.longitude], { title: (group.length > 1) ? first.subtitle : first.title })
        .addTo(this.map)
        .on("click", () => { this.viewBeforePopup = { center: this.map.getCenter(), zoom: this.map.getZoom() } })
        .bindPopup((group.length > 1) ? this.groupPopupContent(group) : this.popupContent(first),
          { maxWidth: 320, minWidth: 240, autoPan: true, className: "directory-map-popup" })
      if (group.every((marker) => marker.full)) leafletMarker.getElement()?.classList.add("is-full")
      group.forEach((marker) => this.markers.set(String(marker.id), leafletMarker))
      return [first.latitude, first.longitude]
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
    // Removing the map right away breaks callbacks it already queued, which
    // neither Leaflet nor the plugin cancels: the MapLibre layer redraws on the
    // next frame after a resize, and Leaflet ends a zoom animation 250 ms after
    // the frame that starts it. Both read the map, so remove it once they ran.
    const map = this.map
    requestAnimationFrame(() => setTimeout(() => map?.remove(), 300))
  }

  // VersaTiles' muted style (open source, no key): much calmer than
  // OpenStreetMap's own, so the markers stand out. Vector tiles, drawn by
  // MapLibre inside Leaflet. MapLibre needs WebGL2, which some browsers turn off
  // (Firefox without its GPU process, remote desktops): they get OpenStreetMap's
  // image tiles instead of a grey map.
  backgroundLayer() {
    if (!webgl2Available()) {
      return L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap contributors</a>',
      })
    }

    return L.maplibreGL({
      style: "https://tiles.versatiles.org/assets/styles/muted/style.json",
      // The plugin would otherwise replace it with the style's own credits once
      // loaded, which sometimes come back empty.
      attributionControl: {
        customAttribution: '&copy; <a href="https://versatiles.org" target="_blank">VersaTiles</a> &copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap contributors</a>',
      },
    })
  }

  resize() {
    if (this.mapTarget.clientWidth === 0) return
    this.map.invalidateSize()
    if (this.fitted) return

    // Without animation: the MapLibre layer stops drawing from a zoomstart until
    // its zoomend, and a first view needn't zoom in from Paris anyway.
    this.fitted = true
    if (this.bounds.length === 1) {
      this.map.setView(this.bounds[0], 14, { animate: false })
    } else if (this.bounds.length > 1) {
      this.map.fitBounds(this.bounds, { padding: [30, 30], animate: false })
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

  // Markers grouped by coordinates, in the cards' order.
  groupByPlace(markers) {
    const groups = new Map()
    markers.forEach((marker) => {
      const key = `${marker.latitude},${marker.longitude}`
      if (!groups.has(key)) groups.set(key, [])
      groups.get(key).push(marker)
    })
    return Array.from(groups.values())
  }

  // The place once, then each of its spaces with its own link.
  groupPopupContent(group) {
    const [first] = group
    const wrapper = this.element.ownerDocument.createElement("div")
    wrapper.className = "w-64 bg-base-100 text-base-content p-3 rounded-box"

    if (first.subtitle) this.append(wrapper, "h3", "font-semibold text-base mb-1", first.subtitle)
    if (first.address) this.append(wrapper, "p", "text-xs text-base-content/90 mb-2", first.address)
    if (first.distance_km != null) this.appendDistance(wrapper, first.distance_km)
    this.append(wrapper, "p", "text-sm font-medium mb-2", this.messagesValue.spaces_here.replace("%{count}", group.length))

    const list = this.append(wrapper, "ul", "max-h-72 overflow-y-auto divide-y divide-base-300 -mx-1 px-1")
    group.forEach((marker) => {
      const item = this.append(list, "li", "flex gap-3 py-2")
      if (marker.image_url) {
        const image = this.append(item, "img", "size-14 shrink-0 object-cover rounded-box")
        image.src = marker.image_url
        image.alt = marker.image_alt || marker.title
      }
      const details = this.append(item, "div", "min-w-0 flex-1")
      if (marker.tag) this.append(details, "div", "badge badge-neutral badge-sm mb-1", marker.tag)
      this.append(details, "p", "font-semibold text-sm leading-snug", marker.title)
      if (marker.url) {
        const link = this.append(details, "a", "link link-primary text-xs", this.messagesValue.more)
        link.href = marker.url
      }
    })

    return wrapper
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
    if (marker.distance_km != null) this.appendDistance(wrapper, marker.distance_km)
    if (marker.text) this.append(wrapper, "p", "text-xs text-base-content/90 mb-3 whitespace-pre-wrap", marker.text)
    if (marker.url) {
      const link = this.append(wrapper, "a", "btn btn-sm btn-outline w-full", this.messagesValue.more)
      link.href = marker.url
    }

    return wrapper
  }

  appendDistance(parent, distanceKm) {
    const distance = Number(distanceKm).toFixed(1).replace(".", ",")
    this.append(parent, "div", "badge badge-outline badge-sm rounded-sm! mb-2", this.messagesValue.distance.replace("%{distance}", distance))
  }

  append(parent, tagName, className, text) {
    const element = parent.ownerDocument.createElement(tagName)
    element.className = className
    if (text !== undefined) element.textContent = text
    parent.appendChild(element)
    return element
  }
}
