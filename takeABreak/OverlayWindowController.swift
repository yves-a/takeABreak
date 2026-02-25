import AppKit
import SwiftUI

/// Custom NSWindow subclass that can become key even though it is borderless,
/// allowing the SwiftUI Skip button to receive clicks.
class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class OverlayWindowController {
    private var windows: [NSWindow] = []

    func showOverlays(breakManager: BreakManager) {
        dismissOverlays()

        for screen in NSScreen.screens {
            // 80% of the screen, centered
            let scale: CGFloat = 0.80
            let w = screen.frame.width * scale
            let h = screen.frame.height * scale
            let x = screen.frame.origin.x + (screen.frame.width - w) / 2
            let y = screen.frame.origin.y + (screen.frame.height - h) / 2
            let overlayRect = NSRect(x: x, y: y, width: w, height: h)

            let window = OverlayWindow(
                contentRect: overlayRect,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            // CGShieldingWindowLevel is guaranteed above fullscreen apps
            window.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
            window.hidesOnDeactivate = false  // stay visible when app loses focus
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = true
            window.ignoresMouseEvents = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            // Round the window corners
            window.contentView = NSHostingView(rootView: OverlayView(breakManager: breakManager))
            window.contentView?.wantsLayer = true
            window.contentView?.layer?.cornerRadius = 20
            window.contentView?.layer?.masksToBounds = true

            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }

        // Bring our app to front so the overlay is interactive
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func dismissOverlays() {
        let toClose = windows
        windows.removeAll()
        guard !toClose.isEmpty else { return }

        for window in toClose {
            window.ignoresMouseEvents = true
            window.contentView = nil
            window.orderOut(nil)
        }
        // Do NOT call window.close() — NSWindow's internal teardown
        // accesses the responder chain and causes EXC_BAD_ACCESS.
        // Dropping all references is sufficient for cleanup.

        // Give focus back to whatever app was frontmost before us.
        // Delay slightly so the windows are fully gone first.
        DispatchQueue.main.async {
            if let frontApp = NSWorkspace.shared.runningApplications.first(where: {
                $0.isActive == false && $0.activationPolicy == .regular
            }) {
                frontApp.activate()
            }
        }
    }
}
