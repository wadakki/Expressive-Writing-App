import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "display", "progress", "timeoutMessage"]
  static values = {
    alertMessage: String,
    duration: { type: Number, default: 480 }
  }

  connect() {
    this.remainingSeconds = this.durationValue
    this.hasFinished = false
    this.render()
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
    this.progressTarget.style.width = `${this.progressPercentage()}%`
  }

  progressPercentage() {
    if (this.durationValue === 0) {
      return 0
    }

    return (this.remainingSeconds / this.durationValue) * 100
  }

  finish() {
    if (this.hasFinished) {
      return
    }

    this.hasFinished = true
    this.clearTimer()
    this.showTimeoutMessage()
    this.updateFinishedStyle()

    if (this.hasAlertMessageValue) {
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
}
