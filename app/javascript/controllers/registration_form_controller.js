import { Controller } from "@hotwired/stimulus"

// The establishment registration form: shows the coworking and association
// sections for the ticked modules (fields of hidden sections are disabled, so
// not sent), Mathilde's message for the coworking answer, and lets
// establishments add or remove association spaces.
export default class extends Controller {
  static targets = ["module", "section", "spaces", "space", "template"]

  connect() {
    this.update()
  }

  update() {
    const modules = this.moduleTargets.filter((box) => box.checked).map((box) => box.value)
    this.sectionTargets.forEach((section) => {
      const shown = modules.includes(section.dataset.module)
      section.hidden = !shown
      section.querySelectorAll("input, select, textarea").forEach((field) => { field.disabled = !shown })
    })

    const answer = this.element.querySelector("input[name$='[coworking_space]']:checked")?.value
    this.element.querySelectorAll("[data-answer]").forEach((message) => { message.hidden = message.dataset.answer !== answer })
  }

  addSpace() {
    const html = this.templateTarget.innerHTML.replaceAll("__INDEX__", Date.now().toString())
    this.spacesTarget.insertAdjacentHTML("beforeend", html)
  }

  // Keeps at least one space: the association section needs one.
  removeSpace(event) {
    if (this.spaceTargets.length <= 1) return
    event.target.closest("[data-registration-form-target='space']").remove()
  }
}
