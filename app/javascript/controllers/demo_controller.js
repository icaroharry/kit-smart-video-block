import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitBtn", "btnText", "urlInput", "form"]

  connect() {
    this.boundStart = this.handleStart.bind(this)
    this.boundEnd = this.handleEnd.bind(this)
    this.formTarget.addEventListener("turbo:submit-start", this.boundStart)
    this.formTarget.addEventListener("turbo:submit-end", this.boundEnd)
  }

  disconnect() {
    this.formTarget.removeEventListener("turbo:submit-start", this.boundStart)
    this.formTarget.removeEventListener("turbo:submit-end", this.boundEnd)
  }

  handleStart() {
    this.submitBtnTarget.classList.add("opacity-75", "cursor-wait")
    this.btnTextTarget.textContent = "Generating..."
  }

  handleEnd() {
    this.submitBtnTarget.classList.remove("opacity-75", "cursor-wait")
    this.btnTextTarget.textContent = "Generate"
  }
}
