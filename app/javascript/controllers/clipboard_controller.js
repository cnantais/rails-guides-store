import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  statis values = { test: String }

  copy() {
    navigator.clipboard.writeText(this.textValue)
  }
}
