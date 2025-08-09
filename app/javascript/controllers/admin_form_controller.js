import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="admin-form"
export default class extends Controller {
  static targets = ["autoSubmit"]

  connect() { }

  submit() {
    if (!this.hasAutoSubmitTarget) return
    clearTimeout(this._t)
    this._t = setTimeout(() => {
      this.autoSubmitTarget.form?.requestSubmit()
    }, 300)
  }
}


