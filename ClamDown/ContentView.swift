import AppKit
import SwiftUI

struct MenuBarContentView: View {
    let model: ClamDownModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StatusHeaderView(
                isEnabled: model.isEnabled,
                lidClosed: model.lidClosed,
                hasExternalDisplay: model.hasExternalDisplay
            )

            Divider()

            Toggle("Monitor lid closure", isOn: Binding(
                get: { model.isEnabled },
                set: { model.isEnabled = $0 }
            ))

            Toggle("Launch at Login", isOn: Binding(
                get: { model.launchAtLoginEnabled },
                set: { model.setLaunchAtLogin($0) }
            ))

            if model.launchAtLoginRequiresApproval {
                HStack {
                    Text("Approval is required in System Settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Open Login Items") {
                        model.openLoginItemsSettings()
                    }
                    .buttonStyle(.link)
                }
            }

            Stepper(value: Binding(
                get: { model.countdownDuration },
                set: { model.setCountdownDuration($0) }
            ), in: 5...120) {
                LabeledContent("Sleep delay") {
                    Text("\(model.countdownDuration) seconds")
                        .monospacedDigit()
                }
            }

            Button("Sleep Now…") {
                model.startTestCountdown()
            }
            .disabled(model.isCountdownActive)
            .help("Starts the sleep countdown using the selected delay.")

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if let launchAtLoginErrorMessage = model.launchAtLoginErrorMessage {
                Text(launchAtLoginErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Divider()

            Button("Quit Clam Down") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 300)
        .onAppear {
            model.refreshLaunchAtLoginStatus()
        }
    }
}

private struct StatusHeaderView: View {
    let isEnabled: Bool
    let lidClosed: Bool
    let hasExternalDisplay: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isEnabled ? "laptopcomputer" : "pause.circle")
                .font(.title2)
                .foregroundStyle(isEnabled ? .primary : .secondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(isEnabled ? "Monitoring" : "Monitoring paused")
                    .font(.headline)
                Text(statusDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statusDescription: LocalizedStringResource {
        if lidClosed {
            return "Lid closed"
        }
        if hasExternalDisplay {
            return "Lid open · External display connected"
        }
        return "Lid open · No external display"
    }
}

struct CountdownView: View {
    let model: ClamDownModel

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 42))
                .foregroundStyle(.indigo)

            VStack(spacing: 6) {
                Text("Your Mac will sleep")
                    .font(.title2.weight(.semibold))
                Text("Sleeping in \(model.remainingSeconds) seconds")
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text("Press any key or select Cancel to keep using the external display.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Cancel Sleep") {
                model.cancelCountdown()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.cancelAction)
        }
        .padding(32)
        .frame(width: 430)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

#Preview("Menu") {
    MenuBarContentView(model: ClamDownModel(startsMonitoring: false))
}

#Preview("Countdown") {
    CountdownView(model: ClamDownModel(startsMonitoring: false))
}
