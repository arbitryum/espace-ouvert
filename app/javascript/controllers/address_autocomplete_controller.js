import { Controller } from "@hotwired/stimulus"

// Address of the registration form: suggests French addresses as the street is
// typed, and fills the street, postal code and city when one is chosen. The
// street input is an ARIA combobox (arrows, Enter, Escape).
export default class extends Controller {
  static targets = ["street", "postalCode", "city", "listbox", "status"]
  // messages: texts from config/locales/accounts.fr.yml (registrations.new.address)
  static values = { url: String, messages: Object }

  connect() {
    this.results = []
    this.active = -1
  }

  disconnect() {
    clearTimeout(this.searchTimer)
  }

  search() {
    clearTimeout(this.searchTimer)
    const query = this.streetTarget.value.trim()
    if (query.length < 3) {
      this.close()
      return
    }

    // Responses can arrive out of order: only the latest search may render.
    const request = (this.latestRequest = (this.latestRequest || 0) + 1)
    this.searchTimer = setTimeout(() => this.fetchResults(query, request), 250)
  }

  async fetchResults(query, request) {
    try {
      const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, { headers: { Accept: "application/json" } })
      if (!response.ok) throw new Error("Address request failed")
      const payload = await response.json()
      if (request === this.latestRequest) this.render(payload.results || [])
    } catch {
      if (request !== this.latestRequest) return
      this.close()
      this.statusTarget.textContent = this.messagesValue.unavailable
    }
  }

  render(results) {
    this.results = results
    this.active = -1
    this.listboxTarget.replaceChildren(...results.map((result, index) => this.option(result, index)))
    this.toggle(results.length > 0)
    this.statusTarget.textContent = results.length
      ? this.messagesValue.suggestions.replace("%{count}", results.length)
      : this.messagesValue.no_suggestions
  }

  option(result, index) {
    const option = document.createElement("li")
    option.id = `${this.listboxTarget.id}-${index}`
    option.setAttribute("role", "option")
    option.setAttribute("aria-selected", "false")
    option.className = "cursor-pointer px-3 py-2 hover:bg-base-200 aria-selected:bg-base-200"

    const label = document.createElement("div")
    label.className = "font-medium"
    label.textContent = result.label
    option.appendChild(label)
    if (result.context) {
      const context = document.createElement("div")
      context.className = "text-xs text-base-content/70"
      context.textContent = result.context
      option.appendChild(context)
    }

    // On mousedown, before the input's blur closes the list.
    option.addEventListener("mousedown", (event) => {
      event.preventDefault()
      this.select(index)
    })
    return option
  }

  navigate(event) {
    if (this.listboxTarget.hidden) return

    const count = this.results.length
    switch (event.key) {
      case "ArrowDown":
        this.highlight((this.active + 1) % count)
        break
      case "ArrowUp":
        this.highlight((this.active - 1 + count) % count)
        break
      case "Enter":
        if (this.active < 0) return
        this.select(this.active)
        break
      case "Escape":
        this.close()
        break
      default:
        return
    }
    event.preventDefault()
  }

  highlight(index) {
    this.active = index
    Array.from(this.listboxTarget.children).forEach((option, position) => {
      option.setAttribute("aria-selected", String(position === index))
    })
    const option = this.listboxTarget.children[index]
    this.streetTarget.setAttribute("aria-activedescendant", option.id)
    option.scrollIntoView({ block: "nearest" })
  }

  select(index) {
    const result = this.results[index]
    this.streetTarget.value = result.street
    this.postalCodeTarget.value = result.postal_code
    this.cityTarget.value = result.city
    this.close()
    this.statusTarget.textContent = this.messagesValue.filled
  }

  close() {
    clearTimeout(this.searchTimer)
    // A response still on its way must not reopen the list.
    this.latestRequest = (this.latestRequest || 0) + 1
    this.results = []
    this.active = -1
    this.listboxTarget.replaceChildren()
    this.toggle(false)
  }

  toggle(open) {
    this.listboxTarget.hidden = !open
    this.streetTarget.setAttribute("aria-expanded", String(open))
    this.streetTarget.removeAttribute("aria-activedescendant")
  }
}
