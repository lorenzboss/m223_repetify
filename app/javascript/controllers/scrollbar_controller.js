import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["thumb"]

  connect() {
    this.handleScroll = this.update.bind(this)
    this.handleResize = this.update.bind(this)

    window.addEventListener("scroll", this.handleScroll, { passive: true })
    window.addEventListener("resize", this.handleResize)
    this.update()
  }

  disconnect() {
    window.removeEventListener("scroll", this.handleScroll)
    window.removeEventListener("resize", this.handleResize)
  }

  update() {
    const scrollHeight = document.documentElement.scrollHeight
    const viewportHeight = window.innerHeight
    const maxScroll = scrollHeight - viewportHeight

    if (maxScroll <= 0) {
      this.thumbTarget.classList.remove("is-visible")
      return
    }

    const trackHeight = viewportHeight - 8
    const thumbHeight = Math.max(32, (viewportHeight / scrollHeight) * trackHeight)
    const travel = trackHeight - thumbHeight
    const top = 4 + (window.scrollY / maxScroll) * travel

    this.thumbTarget.style.height = `${thumbHeight}px`
    this.thumbTarget.style.transform = `translateY(${top - 4}px)`
    this.thumbTarget.classList.add("is-visible")
  }
}
