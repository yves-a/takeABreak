import SwiftUI

struct SettingsView: View {
    @ObservedObject var breakManager: BreakManager

    @AppStorage("eyeBreakInterval")     private var eyeInterval: Double = 20 * 60
    @AppStorage("eyeBreakDuration")     private var eyeDuration: Double = 20
    @AppStorage("stretchBreakInterval") private var stretchInterval: Double = 60 * 60
    @AppStorage("stretchBreakDuration") private var stretchDuration: Double = 5 * 60
    @AppStorage("eyeBreakEnabled")      private var eyeEnabled: Bool = true
    @AppStorage("stretchBreakEnabled")  private var stretchEnabled: Bool = true

    var body: some View {
        Form {
            // ── Eye Break ──────────────────────────────
            Section {
                Toggle("Enable eye breaks", isOn: $eyeEnabled)

                HStack {
                    Text("Remind every")
                    Spacer()
                    Stepper(
                        "\(Int(eyeInterval / 60)) min",
                        value: minuteBinding($eyeInterval),
                        in: 1...120, step: 5
                    )
                    .monospacedDigit()
                }
                .disabled(!eyeEnabled)

                HStack {
                    Text("Break length")
                    Spacer()
                    Stepper(
                        "\(Int(eyeDuration)) sec",
                        value: $eyeDuration,
                        in: 5...120, step: 5
                    )
                    .monospacedDigit()
                }
                .disabled(!eyeEnabled)
            } header: {
                Label("Eye Break  (20-20-20 Rule)", systemImage: "eye.fill")
            }

            // ── Stretch Break ──────────────────────────
            Section {
                Toggle("Enable stretch breaks", isOn: $stretchEnabled)

                HStack {
                    Text("Remind every")
                    Spacer()
                    Stepper(
                        "\(Int(stretchInterval / 60)) min",
                        value: minuteBinding($stretchInterval),
                        in: 5...180, step: 5
                    )
                    .monospacedDigit()
                }
                .disabled(!stretchEnabled)

                HStack {
                    Text("Break length")
                    Spacer()
                    Stepper(
                        "\(Int(stretchDuration / 60)) min",
                        value: minuteBinding($stretchDuration),
                        in: 1...15, step: 1
                    )
                    .monospacedDigit()
                }
                .disabled(!stretchEnabled)
            } header: {
                Label("Stretch Break", systemImage: "figure.walk")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 380)
    }

    /// Converts a seconds-based binding into a minutes-based binding.
    private func minuteBinding(_ base: Binding<Double>) -> Binding<Double> {
        Binding(
            get: { base.wrappedValue / 60 },
            set: { base.wrappedValue = $0 * 60 }
        )
    }
}
