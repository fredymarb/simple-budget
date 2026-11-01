import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "kind",
    "regularFields",
    "transferFields",
    "account",
    "categoryFields",
    "category",
    "sourceAccount",
    "destinationAccount"
  ]

  static values = { kind: String }

  connect() {
    this.update()
  }

  update() {
    const isTransfer = (this.hasKindTarget ? this.kindTarget.value : this.kindValue) === "transfer"

    this.regularFieldsTarget.hidden = isTransfer
    this.transferFieldsTarget.hidden = !isTransfer
    this.accountTarget.required = !isTransfer
    this.categoryTarget.required = !isTransfer
    this.sourceAccountTarget.required = isTransfer
    this.destinationAccountTarget.required = isTransfer
  }
}
