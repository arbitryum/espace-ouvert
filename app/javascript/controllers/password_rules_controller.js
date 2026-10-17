import { Controller } from "@hotwired/stimulus"

// Live checklist of the password rules enforced by the User model.
export default class extends Controller {
  static targets = ["password", "passwordConfirmation", "rule"]

  connect() {
    this.passwordTarget.addEventListener("input", this.update)
    this.passwordConfirmationTarget.addEventListener("input", this.update)
    this.update()
  }

  disconnect() {
    this.passwordTarget.removeEventListener("input", this.update)
    this.passwordConfirmationTarget.removeEventListener("input", this.update)
  }

  update = () => {
    const password = this.passwordTarget.value
    const checks = {
      length: password.length >= 8,
      numeric: password.length > 0 && !/^\d+$/.test(password),
      match: password.length > 0 && password === this.passwordConfirmationTarget.value,
    }

    this.ruleTargets.forEach((rule) => {
      const valid = checks[rule.dataset.rule]
      rule.classList.toggle("text-success", valid)
      rule.classList.toggle("text-error", !valid)
      rule.querySelector("span").textContent = valid ? "✓" : "○"
    })
  }
}
