import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track"]

  prev() { this.scrollByOne(-1) }
  next() { this.scrollByOne(1) }

  scrollByOne(direction) {
    const track = this.trackTarget
    const slide = track.firstElementChild
    if (!slide) return
    track.scrollBy({ left: direction * slide.offsetWidth, behavior: "smooth" })
  }
}
