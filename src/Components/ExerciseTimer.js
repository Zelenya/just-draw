export const nowMillis = () => Date.now()

export const setTimerInterval = tick => () =>
  window.setInterval(() => tick(), 250)

export const clearTimerInterval = intervalId => () =>
  window.clearInterval(intervalId)

export const requestNotificationPermission = () => {
  const NotificationApi = globalThis.Notification

  if (NotificationApi?.permission === "default") {
    void NotificationApi.requestPermission()
  }
}

// No idea how this works
const playDoneSound = () => {
  const AudioContext = globalThis.AudioContext ?? globalThis.webkitAudioContext

  if (!AudioContext) {
    return
  }

  const context = new AudioContext()
  const oscillator = context.createOscillator()
  const gain = context.createGain()
  const now = context.currentTime

  oscillator.type = "sine"
  oscillator.frequency.setValueAtTime(660, now)
  oscillator.frequency.setValueAtTime(880, now + 0.32)
  oscillator.frequency.setValueAtTime(660, now + 0.66)
  gain.gain.setValueAtTime(0.001, now)
  gain.gain.exponentialRampToValueAtTime(0.26, now + 0.03)
  gain.gain.exponentialRampToValueAtTime(0.001, now + 0.38)
  gain.gain.setValueAtTime(0.001, now + 0.46)
  gain.gain.exponentialRampToValueAtTime(0.24, now + 0.5)
  gain.gain.exponentialRampToValueAtTime(0.001, now + 0.95)
  oscillator.connect(gain)
  gain.connect(context.destination)
  oscillator.addEventListener("ended", () => {
    context.close().catch(() => undefined)
  })
  oscillator.start()
  oscillator.stop(now + 1.05)
}

export const notifyDone = exerciseTitle => () => {
  const NotificationApi = globalThis.Notification

  try {
    playDoneSound()
  } catch {}

  globalThis.navigator?.vibrate?.([220, 90, 220])

  if (NotificationApi?.permission === "granted") {
    try {
      new NotificationApi("Time's up", {
        body: `${exerciseTitle || "Your exercise"} is done.`,
      })
    } catch {}
  }
}
