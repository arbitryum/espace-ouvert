import { Controller } from "@hotwired/stimulus"

// Scroll-snap carousel with looping arrows and dot indicators.
export default class extends Controller {
  static targets = ["track", "slide", "dot"]

  connect() {
    this.sync()
  }

  previous(event) {
    event.preventDefault()
    this.show((this.currentIndex - 1 + this.slideTargets.length) % this.slideTargets.length)
  }

  next(event) {
    event.preventDefault()
    this.show((this.currentIndex + 1) % this.slideTargets.length)
  }

  goTo(event) {
    event.preventDefault()
    this.show(event.params.index)
  }

  // Keeps the dots in step with native scrolling, including touch swipes.
  sync() {
    if (this.frame) return
    this.frame = requestAnimationFrame(() => {
      this.frame = null
      this.highlight(this.currentIndex)
    })
  }

  show(index) {
    this.trackTarget.scroll({ left: index * this.trackTarget.offsetWidth, behavior: "smooth" })
    this.highlight(index)
  }

  get currentIndex() {
    const width = this.trackTarget.offsetWidth
    return width ? Math.round(this.trackTarget.scrollLeft / width) : 0
  }

  highlight(activeIndex) {
    this.dotTargets.forEach((dot, index) => {
      const active = index === activeIndex
      dot.classList.toggle("bg-primary", active)
      dot.classList.toggle("w-6", active)
      dot.classList.toggle("bg-base-100/60", !active)
      dot.classList.toggle("hover:bg-base-100/80", !active)
      dot.classList.toggle("w-2", !active)
      dot.setAttribute("aria-current", active ? "true" : "false")
    })
  }
}
