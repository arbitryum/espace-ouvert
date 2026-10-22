import { Controller } from "@hotwired/stimulus"

// Location box of the space filters: autocomplete of French communes and
// departments, and an "Autour de moi" option using the browser's geolocation.
// Picking one of them runs the search.
export default class extends Controller {
  static targets = [
    "dropdown", "input", "panel", "radius", "suggestions", "searchStatus", "status",
    "aroundMeChip", "aroundMeLabel", "latitude", "longitude", "mode", "department",
  ]
  // messages: texts from config/locales/spaces.fr.yml (spaces.index.location_filter)
  static values = { suggestionsUrl: String, messages: Object }

  connect() {
    this.refreshAroundMe()
  }

  // Keeps the current suggestions while the next ones load.
  open() {
    this.panelTarget.classList.remove("hidden")
    if (this.suggestionsTarget.childElementCount === 0) this.renderSuggestions([], this.message("type_more"))
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.clearSuggestions()
  }

  closeOnOutsideClick(event) {
    if (!this.dropdownTarget.contains(event.target)) this.close()
  }

  search() {
    this.clearCoordinates()
    if (this.inputTarget.value.trim() !== this.aroundMeText) this.refreshAroundMe()
    this.open()

    const query = this.inputTarget.value.trim()
    clearTimeout(this.searchTimer)
    // Responses can arrive out of order: only the latest search may render.
    const request = (this.latestRequest = (this.latestRequest || 0) + 1)
    if (query.length < 2) {
      this.renderSuggestions([], this.message("type_more"))
      return
    }

    this.searchStatusTarget.textContent = this.message("searching")
    this.searchTimer = setTimeout(() => this.fetchSuggestions(query, request), 250)
  }

  async fetchSuggestions(query, request) {
    try {
      const response = await fetch(`${this.suggestionsUrlValue}?q=${encodeURIComponent(query)}`)
      if (!response.ok) throw new Error("Suggestion request failed")
      const payload = await response.json()
      if (request === this.latestRequest) this.renderSuggestions(payload.results || [])
    } catch {
      if (request !== this.latestRequest) return
      this.clearSuggestions()
      this.searchStatusTarget.textContent = this.message("unavailable")
    }
  }

  renderSuggestions(items, status = null) {
    this.suggestionsTarget.replaceChildren(
      this.suggestionButton(this.message("around_me"), this.message("use_my_position"), () => this.activateAroundMe()),
      ...items.map((item) => {
        const subtitle = [this.message(item.kind), item.context].filter(Boolean).join(" • ")
        return this.suggestionButton(item.label, subtitle, () => this.select(item))
      }),
    )
    this.suggestionsTarget.classList.remove("hidden")
    this.searchStatusTarget.textContent = status ?? (items.length ? this.message("suggestions", { count: items.length }) : this.message("no_suggestions"))
  }

  suggestionButton(title, subtitle, onClick) {
    const button = document.createElement("button")
    button.type = "button"
    button.className = "block w-full text-left px-3 py-2 hover:bg-base-200"
    const titleElement = document.createElement("div")
    titleElement.className = "font-medium"
    titleElement.textContent = title
    button.appendChild(titleElement)
    if (subtitle) {
      const subtitleElement = document.createElement("div")
      subtitleElement.className = "text-xs text-base-content/70"
      subtitleElement.textContent = subtitle
      button.appendChild(subtitleElement)
    }
    button.addEventListener("click", onClick)
    return button
  }

  clearSuggestions() {
    this.suggestionsTarget.replaceChildren()
    this.suggestionsTarget.classList.add("hidden")
  }

  select(item) {
    this.inputTarget.value = item.label
    if (item.kind === "department") {
      this.clearCoordinates()
      this.departmentTarget.value = item.department_code
    } else {
      this.setCoordinates(item.latitude, item.longitude, "location")
    }
    this.close()
    this.element.requestSubmit()
  }

  activateAroundMe() {
    if (!navigator.geolocation) {
      this.statusTarget.textContent = this.message("geolocation_unsupported")
      return
    }

    this.statusTarget.textContent = this.message("locating")
    navigator.geolocation.getCurrentPosition(
      (position) => {
        this.setCoordinates(position.coords.latitude, position.coords.longitude, "around_me")
        this.statusTarget.textContent = ""
        this.refreshAroundMe()
        this.close()
        this.element.requestSubmit()
      },
      (error) => {
        const errors = { 1: "geolocation_denied", 2: "position_unavailable", 3: "geolocation_timeout" }
        this.statusTarget.textContent = this.message(errors[error?.code] || "geolocation_failed")
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 60000 },
    )
  }

  clearAroundMe() {
    this.clearCoordinates()
    if (this.inputTarget.value.trim() === this.aroundMeText) this.inputTarget.value = ""
    this.refreshAroundMe()
  }

  refreshAroundMe() {
    const active = this.latitudeTarget.value && this.longitudeTarget.value && this.modeTarget.value === "around_me"
    this.aroundMeChipTarget.classList.toggle("hidden", !active)
    this.aroundMeChipTarget.classList.toggle("flex", Boolean(active))
    if (active) {
      this.aroundMeLabelTarget.textContent = this.aroundMeText
      this.inputTarget.value = this.aroundMeText
    }
  }

  // A point and a department exclude each other: setting one clears the other.
  setCoordinates(latitude, longitude, mode) {
    this.latitudeTarget.value = String(latitude)
    this.longitudeTarget.value = String(longitude)
    this.modeTarget.value = mode
    this.departmentTarget.value = ""
  }

  clearCoordinates() {
    this.setCoordinates("", "", "")
  }

  get aroundMeText() {
    return this.message("around_me_radius", { radius: this.radiusTarget.value })
  }

  // A message with its %{placeholders} filled in.
  message(key, params = {}) {
    return Object.entries(params).reduce((text, [name, value]) => text.replace(`%{${name}}`, value), this.messagesValue[key] ?? key)
  }
}
