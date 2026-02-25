import SwiftUI
import Combine
import AppKit

enum BreakType: String {
    case eye = "eye"
    case stretch = "stretch"
}

class BreakManager: ObservableObject {
    // MARK: - Published State
    @Published var isRunning = false
    @Published var isOnBreak = false
    @Published var currentBreakType: BreakType = .eye
    @Published var countdownRemaining: TimeInterval = 0
    @Published var eyeBreakElapsed: TimeInterval = 0
    @Published var stretchBreakElapsed: TimeInterval = 0

    // MARK: - Settings (UserDefaults-backed)
    var eyeBreakInterval: TimeInterval {
        get { val("eyeBreakInterval", default: 20 * 60) }
        set { UserDefaults.standard.set(newValue, forKey: "eyeBreakInterval") }
    }
    var eyeBreakDuration: TimeInterval {
        get { val("eyeBreakDuration", default: 20) }
        set { UserDefaults.standard.set(newValue, forKey: "eyeBreakDuration") }
    }
    var stretchBreakInterval: TimeInterval {
        get { val("stretchBreakInterval", default: 60 * 60) }
        set { UserDefaults.standard.set(newValue, forKey: "stretchBreakInterval") }
    }
    var stretchBreakDuration: TimeInterval {
        get { val("stretchBreakDuration", default: 5 * 60) }
        set { UserDefaults.standard.set(newValue, forKey: "stretchBreakDuration") }
    }
    var eyeBreakEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "eyeBreakEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "eyeBreakEnabled") }
    }
    var stretchBreakEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "stretchBreakEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "stretchBreakEnabled") }
    }

    // MARK: - Computed Display Strings
    var timeUntilNextEyeBreak: String {
        formatTime(max(0, eyeBreakInterval - eyeBreakElapsed))
    }
    var timeUntilNextStretchBreak: String {
        formatTime(max(0, stretchBreakInterval - stretchBreakElapsed))
    }
    var countdownText: String {
        formatTime(ceil(countdownRemaining))
    }
    var countdownProgress: Double {
        let total = currentBreakType == .eye ? eyeBreakDuration : stretchBreakDuration
        guard total > 0 else { return 0 }
        // Smoothly sweep between second marks, arriving at each position
        // exactly when the text ticks over (both use ceil).
        let ceiled = ceil(countdownRemaining)
        let frac = ceiled - countdownRemaining          // 0 → 1 within each second
        let from = ceiled / total
        let to   = max(0, (ceiled - 1)) / total
        return from + (to - from) * frac
    }

    // MARK: - Private
    private var mainTimer: Timer?
    private var countdownTimer: Timer?
    private let overlayController = OverlayWindowController()

    // MARK: - Public Actions
    func start() {
        isRunning = true
        eyeBreakElapsed = 0
        stretchBreakElapsed = 0
        startMainTimer()
    }

    func pause() {
        isRunning = false
        mainTimer?.invalidate()
        mainTimer = nil
    }

    func skipBreak() {
        endBreak()
    }


    // MARK: - Internal (testable) Logic
    internal func startMainTimer() {
        mainTimer?.invalidate()
        mainTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.tick() }
        }
    }

    internal func tick() {
        guard isRunning, !isOnBreak else { return }
        eyeBreakElapsed += 1
        stretchBreakElapsed += 1

        // Stretch break has higher priority
        if stretchBreakEnabled && stretchBreakElapsed >= stretchBreakInterval {
            triggerBreak(.stretch)
        } else if eyeBreakEnabled && eyeBreakElapsed >= eyeBreakInterval {
            triggerBreak(.eye)
        }
    }

    internal func triggerBreak(_ type: BreakType) {
        mainTimer?.invalidate()
        mainTimer = nil

        currentBreakType = type
        isOnBreak = true
        countdownRemaining = (type == .eye) ? eyeBreakDuration : stretchBreakDuration

        overlayController.showOverlays(breakManager: self)

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.countdownTick() }
        }
    }

    private func countdownTick() {
        countdownRemaining -= 1.0 / 60.0
        if countdownRemaining <= 0 {
            // Play a gentle chime to signal the break is over
            NSSound(named: "Glass")?.play()
            endBreak()
        }
    }

    internal func endBreak() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        isOnBreak = false

        overlayController.dismissOverlays()

        if currentBreakType == .eye {
            eyeBreakElapsed = 0
        } else {
            stretchBreakElapsed = 0
            eyeBreakElapsed = 0 // also reset eye timer after stretch
        }

        if isRunning {
            startMainTimer()
        }
    }

    // MARK: - Helpers
    private func val(_ key: String, default d: Double) -> Double {
        let v = UserDefaults.standard.double(forKey: key)
        return v > 0 ? v : d
    }

    internal func formatTime(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}
