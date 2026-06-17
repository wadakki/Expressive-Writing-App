import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "progress"]
  static values = {
    duration: { type: Number, default: 480 }
  }

  connect() {
    this.remainingSeconds = this.durationValue
    this.render()
    this.interval = window.setInterval(() => {
      this.tick()
    }, 1000)
  }

  disconnect() {
    if (this.interval) {
      window.clearInterval(this.interval)
    }
  }

  tick() {
    if (this.remainingSeconds <= 0) {
      window.clearInterval(this.interval)
      return
    }

    this.remainingSeconds -= 1
    this.render()
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
}
