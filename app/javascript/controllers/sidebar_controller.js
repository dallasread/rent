import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    event.preventDefault()
    const layout = this.element.querySelector("[data-sidebar-layout]")
    if (!layout) return
    if (layout.hasAttribute("data-sidebar-open")) {
      layout.removeAttribute("data-sidebar-open")
    } else {
      layout.setAttribute("data-sidebar-open", "")
    }
  }
}
