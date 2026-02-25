import SwiftUI

@main
struct TakeABreakApp: App {
    @StateObject private var breakManager = BreakManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(breakManager: breakManager)
        } label: {
            Label("Take a Break", systemImage: breakManager.isOnBreak ? "leaf.fill" : "leaf")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(breakManager: breakManager)
        }
    }
}

struct MenuBarContentView: View {
    @ObservedObject var breakManager: BreakManager

    var body: some View {
        if breakManager.isRunning {
            if breakManager.isOnBreak {
                let typeLabel = breakManager.currentBreakType == .eye ? "Eye" : "Stretch"
                Text("\(typeLabel) break — \(breakManager.countdownText) left")
            } else {
                if breakManager.eyeBreakEnabled {
                    Text("Eye break in \(breakManager.timeUntilNextEyeBreak)")
                }
                if breakManager.stretchBreakEnabled {
                    Text("Stretch in \(breakManager.timeUntilNextStretchBreak)")
                }
            }
            Divider()
            if breakManager.isOnBreak {
                Button("Skip Break") { breakManager.skipBreak() }
            } else {
                Button("Pause") { breakManager.pause() }
            }
        } else {
            Button("Start") { breakManager.start() }
        }
        Divider()
        SettingsLink {
            Text("Settings…")
        }
        Divider()
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
