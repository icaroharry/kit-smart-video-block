import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  copy() {
    const htmlEl = document.getElementById("generated-html")
    if (!htmlEl) return

    navigator.clipboard.writeText(htmlEl.textContent).then(() => {
      const originalText = this.element.textContent
      this.element.textContent = "Copied!"
      setTimeout(() => {
        this.element.textContent = originalText
      }, 2000)
    })
  }
}
