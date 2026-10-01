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

            HStack {
                Button("Test countdown") {
                    model.startTestCountdown()
                }
                .disabled(model.isCountdownActive)

                Spacer()

                SettingsLink {
                    Label("Settings", systemImage: "gearshape")
                }
            }

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
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

struct SettingsView: View {
    let model: ClamDownModel

    var body: some View {
        Form {
            Toggle("Monitor lid closure", isOn: Binding(
                get: { model.isEnabled },
                set: { model.isEnabled = $0 }
            ))

            Stepper(value: Binding(
                get: { model.countdownDuration },
                set: { model.setCountdownDuration($0) }
            ), in: 3...60) {
                LabeledContent("Sleep delay") {
                    Text("\(model.countdownDuration) seconds")
                }
            }

            Text("When the lid closes while an external display is connected, Clam Down warns you before putting the Mac to sleep.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .frame(width: 430)
        .padding()
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
