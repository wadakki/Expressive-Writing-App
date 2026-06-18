import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["completedButton", "container", "display", "progress", "remainingField", "timeoutMessage"]
  static values = {
    alertMessage: String,
    duration: { type: Number, default: 480 },
    initialRemaining: { type: Number, default: 480 }
  }

  connect() {
    this.remainingSeconds = this.normalizedInitialRemainingSeconds()
    this.hasFinished = false
    this.render()

    if (this.remainingSeconds <= 0) {
      this.finish({ showAlert: false })
      return
    }

    this.disableCompletedButton()

    this.interval = window.setInterval(() => {
      this.tick()
    }, 1000)
  }

  disconnect() {
    this.clearTimer()
  }

  tick() {
    if (this.remainingSeconds <= 0) {
      window.clearInterval(this.interval)
      return
    }

    this.remainingSeconds -= 1
    this.render()

    if (this.remainingSeconds === 0) {
      this.finish()
    }
  }

  render() {
    const minutes = Math.floor(this.remainingSeconds / 60)
    const seconds = this.remainingSeconds % 60

    this.displayTarget.textContent = `${minutes}:${seconds.toString().padStart(2, "0")}`
    this.remainingFieldTarget.value = this.remainingSeconds
    this.progressTarget.style.width = `${this.progressPercentage()}%`
  }

  progressPercentage() {
    if (this.durationValue === 0) {
      return 0
    }

    return (this.remainingSeconds / this.durationValue) * 100
  }

  finish({ showAlert = true } = {}) {
    if (this.hasFinished) {
      return
    }

    this.hasFinished = true
    this.clearTimer()
    this.showTimeoutMessage()
    this.updateFinishedStyle()
    this.enableCompletedButton()

    if (showAlert && this.hasAlertMessageValue) {
      window.alert(this.alertMessageValue)
    }
  }

  clearTimer() {
    if (this.interval) {
      window.clearInterval(this.interval)
    }
  }

  showTimeoutMessage() {
    this.timeoutMessageTarget.classList.remove("hidden")
  }

  updateFinishedStyle() {
    this.containerTarget.classList.add("border-amber-300", "bg-amber-50/95")
    this.progressTarget.classList.remove("bg-blue-600")
    this.progressTarget.classList.add("bg-amber-500")
  }

  disableCompletedButton() {
    this.completedButtonTarget.disabled = true
    this.completedButtonTarget.classList.add("cursor-not-allowed", "opacity-50")
  }

  enableCompletedButton() {
    this.completedButtonTarget.disabled = false
    this.completedButtonTarget.classList.remove("cursor-not-allowed", "opacity-50")
  }

  normalizedInitialRemainingSeconds() {
    if (this.initialRemainingValue < 0) {
      return 0
    }

    if (this.initialRemainingValue > this.durationValue) {
      return this.durationValue
    }

    return this.initialRemainingValue
  }
}
