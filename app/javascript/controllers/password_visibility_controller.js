import { Controller } from "@hotwired/stimulus"

// Shows or hides the characters of a password input.
export default class extends Controller {
  static targets = ["input", "button", "shownIcon", "hiddenIcon"]
  static values = { showLabel: String, hideLabel: String }

  toggle() {
    const willShow = this.inputTarget.type === "password"
    const label = willShow ? this.hideLabelValue : this.showLabelValue

    this.inputTarget.type = willShow ? "text" : "password"
    this.buttonTarget.setAttribute("aria-label", label)
    this.buttonTarget.setAttribute("title", label)
    this.shownIconTarget.classList.toggle("hidden", willShow)
    this.hiddenIconTarget.classList.toggle("hidden", !willShow)
  }
}
