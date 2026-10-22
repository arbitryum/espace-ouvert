import { Controller } from "@hotwired/stimulus"

// The hosting request form: shows the questions of the chosen kind (coworking
// or association) and disables the others, so they're neither required nor
// sent; lists the slots of the chosen space only.
export default class extends Controller {
  static targets = ["kind", "section", "space", "slot"]

  connect() {
    this.update()
  }

  update() {
    const kind = this.kindTargets.find((radio) => radio.checked)?.value
    this.sectionTargets.forEach((section) => {
      const active = section.dataset.kind === kind
      section.hidden = !active
      section.querySelectorAll("input, select, textarea").forEach((field) => { field.disabled = !active })
    })
    this.filterSlots()
  }

  filterSlots() {
    const spaceId = this.hasSpaceTarget ? this.spaceTarget.value : ""
    this.slotTargets.forEach((slot) => {
      const shown = !spaceId || slot.dataset.spaceId === spaceId
      slot.hidden = !shown
      if (!shown) slot.querySelector("input").checked = false
    })
  }
}
