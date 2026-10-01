import AppKit
import Observation

@MainActor
@Observable
final class ClamDownModel {
    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: DefaultsKey.isEnabled)
            if !isEnabled {
                cancelCountdown()
            }
        }
    }

    private(set) var countdownDuration: Int {
        didSet {
            UserDefaults.standard.set(countdownDuration, forKey: DefaultsKey.countdownDuration)
        }
    }

    private(set) var lidClosed = false
    private(set) var hasExternalDisplay = false
    private(set) var isCountdownActive = false
    private(set) var remainingSeconds = 0
    private(set) var errorMessage: LocalizedStringResource?

    var menuBarIconName: String {
        isCountdownActive ? "moon.zzz.fill" : "laptopcomputer"
    }

    private let systemMonitor = SystemMonitor()
    private var panelController: CountdownPanelController?
    private var monitorTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private var keyMonitor: Any?
    private var previousLidClosed: Bool?
    private var previouslyHadPressedKey = false

    init(startsMonitoring: Bool = true) {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: DefaultsKey.isEnabled) == nil {
            isEnabled = true
        } else {
            isEnabled = defaults.bool(forKey: DefaultsKey.isEnabled)
        }

        let storedDuration = defaults.integer(forKey: DefaultsKey.countdownDuration)
        countdownDuration = storedDuration == 0 ? 10 : min(max(storedDuration, 3), 60)

        if startsMonitoring {
            Task { @MainActor [weak self] in
                self?.startMonitoring()
            }
        }
    }

    func startTestCountdown() {
        Task { @MainActor [weak self] in
            await Task.yield()
            self?.beginCountdown()
        }
    }

    func setCountdownDuration(_ duration: Int) {
        countdownDuration = min(max(duration, 3), 60)
    }

    func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
        isCountdownActive = false
        removeKeyMonitor()
        panelController?.hide()
    }

    private func startMonitoring() {
        guard monitorTask == nil else { return }

        refreshHardwareState(triggerCountdown: false)
        monitorTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                self?.refreshHardwareState(triggerCountdown: true)
            }
        }
    }

    private func refreshHardwareState(triggerCountdown: Bool) {
        let newLidClosed = systemMonitor.isLidClosed
        let newHasExternalDisplay = systemMonitor.hasExternalDisplay
        let hasPressedKey = systemMonitor.isAnyKeyPressed
        let lidJustClosed = previousLidClosed == false && newLidClosed
        let keyWasHeldDuringClosure = previouslyHadPressedKey || hasPressedKey

        lidClosed = newLidClosed
        hasExternalDisplay = newHasExternalDisplay
        previousLidClosed = newLidClosed
        previouslyHadPressedKey = hasPressedKey

        if triggerCountdown
            && isEnabled
            && lidJustClosed
            && newHasExternalDisplay
            && !keyWasHeldDuringClosure {
            beginCountdown()
        }
    }

    private func beginCountdown() {
        guard !isCountdownActive else { return }

        errorMessage = nil
        remainingSeconds = countdownDuration
        isCountdownActive = true
        installKeyMonitor()
        showCountdownPanel()

        countdownTask = Task { @MainActor [weak self] in
            guard let self else { return }

            while remainingSeconds > 0 {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
                remainingSeconds -= 1
            }

            finishCountdownAndSleep()
        }
    }

    private func finishCountdownAndSleep() {
        countdownTask = nil
        isCountdownActive = false
        removeKeyMonitor()
        panelController?.hide()

        if let error = systemMonitor.requestSystemSleep() {
            errorMessage = error
        }
    }

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .flagsChanged]
        ) { [weak self] _ in
            self?.cancelCountdown()
            return nil
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    private func showCountdownPanel() {
        if panelController == nil {
            panelController = CountdownPanelController(model: self)
        }
        panelController?.show()
    }

    private enum DefaultsKey {
        static let isEnabled = "isEnabled"
        static let countdownDuration = "countdownDuration"
    }
}
