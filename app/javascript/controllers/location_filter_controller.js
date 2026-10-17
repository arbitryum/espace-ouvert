import { Controller } from "@hotwired/stimulus"

// Location box of the space filters: autocomplete from the geocoder,
// and an "Autour de moi" option using the browser's geolocation.
export default class extends Controller {
  static targets = [
    "dropdown", "input", "panel", "radius", "suggestions", "searchStatus", "status",
    "aroundMeChip", "aroundMeLabel", "latitude", "longitude", "mode",
  ]
  static values = { suggestionsUrl: String }

  connect() {
    this.refreshAroundMe()
  }

  open() {
    this.panelTarget.classList.remove("hidden")
    this.renderSuggestions([])
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
    if (query.length < 2) {
      this.searchStatusTarget.textContent = "Tapez au moins 2 caractères"
      return
    }

    this.searchTimer = setTimeout(() => this.fetchSuggestions(query), 250)
  }

  async fetchSuggestions(query) {
    this.searchStatusTarget.textContent = "Recherche…"
    try {
      const response = await fetch(`${this.suggestionsUrlValue}?q=${encodeURIComponent(query)}`)
      if (!response.ok) throw new Error("Suggestion request failed")
      const payload = await response.json()
      this.renderSuggestions(payload.results || [])
    } catch {
      this.clearSuggestions()
      this.searchStatusTarget.textContent = "Service de suggestions indisponible."
    }
  }

  renderSuggestions(items) {
    this.suggestionsTarget.replaceChildren(
      this.suggestionButton("Autour de moi", "Utiliser ma position actuelle", () => this.activateAroundMe()),
      ...items.map((item) => {
        const subtitle = [item.type, item.city, item.postcode].filter(Boolean).join(" • ")
        return this.suggestionButton(item.label || item.name || "", subtitle, () => this.select(item))
      }),
    )
    this.suggestionsTarget.classList.remove("hidden")
    this.searchStatusTarget.textContent = items.length ? `${items.length} suggestion(s)` : "Aucune suggestion."
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
    this.inputTarget.value = item.label || item.name || ""
    if (item.latitude != null && item.longitude != null) {
      this.setCoordinates(item.latitude, item.longitude, "location")
    } else {
      this.clearCoordinates()
    }
    this.clearSuggestions()
    this.refreshAroundMe()
  }

  activateAroundMe() {
    if (!navigator.geolocation) {
      this.statusTarget.textContent = "La géolocalisation n'est pas disponible sur ce navigateur."
      return
    }

    this.statusTarget.textContent = "Localisation en cours…"
    navigator.geolocation.getCurrentPosition(
      (position) => {
        this.setCoordinates(position.coords.latitude, position.coords.longitude, "around_me")
        this.statusTarget.textContent = ""
        this.refreshAroundMe()
        this.clearSuggestions()
      },
      (error) => {
        const messages = {
          1: "Vous avez refusé la géolocalisation.",
          2: "Position introuvable.",
          3: "La géolocalisation a expiré.",
        }
        this.statusTarget.textContent = messages[error?.code] || "Impossible de récupérer votre position."
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

  setCoordinates(latitude, longitude, mode) {
    this.latitudeTarget.value = String(latitude)
    this.longitudeTarget.value = String(longitude)
    this.modeTarget.value = mode
  }

  clearCoordinates() {
    this.setCoordinates("", "", "")
  }

  get aroundMeText() {
    return `Autour de moi (${this.radiusTarget.value}km)`
  }
}
