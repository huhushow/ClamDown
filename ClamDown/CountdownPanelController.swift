import AppKit
import SwiftUI

@MainActor
final class CountdownPanelController {
    private let panel: CountdownPanel
    private var presentationTask: Task<Void, Never>?

    init(model: ClamDownModel) {
        panel = CountdownPanel(
            contentRect: NSRect(x: 0, y: 0, width: 430, height: 300),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = NSHostingView(rootView: CountdownView(model: model))
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.level = .floating
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .canJoinAllApplications,
            .fullScreenAuxiliary
        ]
        panel.isReleasedWhenClosed = false
    }

    func show() {
        presentationTask?.cancel()
        presentPanel()

        presentationTask = Task { @MainActor [weak self] in
            for delay in [Duration.milliseconds(250), .milliseconds(750)] {
                do {
                    try await Task.sleep(for: delay)
                } catch {
                    return
                }

                self?.presentPanel()
            }
        }
    }

    private func presentPanel() {
        positionPanelOnActiveDisplay()
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
    }

    private func positionPanelOnActiveDisplay() {
        guard let screen = preferredScreen else { return }

        let visibleFrame = screen.visibleFrame
        let panelFrame = panel.frame
        let origin = NSPoint(
            x: visibleFrame.midX - panelFrame.width / 2,
            y: visibleFrame.midY - panelFrame.height / 2
        )
        panel.setFrameOrigin(origin)
    }

    private var preferredScreen: NSScreen? {
        NSScreen.screens.first(where: { screen in
            guard let screenNumber = screen.deviceDescription[
                NSDeviceDescriptionKey("NSScreenNumber")
            ] as? NSNumber else {
                return false
            }

            return CGDisplayIsBuiltin(CGDirectDisplayID(screenNumber.uint32Value)) == 0
        }) ?? NSScreen.main ?? NSScreen.screens.first
    }

    func hide() {
        presentationTask?.cancel()
        presentationTask = nil
        panel.orderOut(nil)
    }
}

private final class CountdownPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
