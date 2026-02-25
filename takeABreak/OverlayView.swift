import SwiftUI

struct OverlayView: View {
    @ObservedObject var breakManager: BreakManager
    @State private var appear = false
    @State private var pulse = false
    @State private var randomMessage: String = ""

    private var isEye: Bool { breakManager.currentBreakType == .eye }
    private var accent: Color { isEye ? .cyan : .orange }
    private var gradient: [Color] { isEye ? [.cyan, .blue] : [.orange, .pink] }

    private static let eyeMessages = [
        "Look at something 20 feet away",
        "Give your eyes a well-deserved rest",
        "Focus on something in the distance",
        "Your eyes work hard — let them breathe",
        "Blink slowly and relax your gaze",
        "Stare out a window for a moment",
        "Let your vision soften and rest",
        "Close your eyes and take a deep breath",
    ]

    private static let stretchMessages = [
        "Stand up, move around, and stretch",
        "Roll your shoulders and loosen up",
        "Your body needs a change of position",
        "Take a short walk, even just around the room",
        "Stretch your arms above your head",
        "Do a few neck rolls — you've earned it",
        "Get some water while you're up",
        "Shake out your hands and wrists",
    ]

    var body: some View {
        ZStack {
            // Dark background
            Color.black.opacity(0.88)

            // Subtle radial glow behind content
            RadialGradient(
                colors: [accent.opacity(0.15), .clear],
                center: .center,
                startRadius: 40,
                endRadius: 400
            )

            // Main content
            VStack(spacing: 28) {
                // Icon
                Image(systemName: isEye ? "eye" : "figure.walk")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundColor(accent)
                    .scaleEffect(pulse ? 1.08 : 1.0)

                // Title
                Text(isEye ? "Time to rest your eyes" : "Time to stretch!")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Random subtitle
                Text(randomMessage)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))

                // Progress ring + countdown
                ZStack {
                    // Track
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 8)
                        .frame(width: 200, height: 200)

                    // Progress arc
                    Circle()
                        .trim(from: 0, to: breakManager.countdownProgress)
                        .stroke(
                            LinearGradient(colors: gradient,
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        // Smooth 60fps updates, no animation needed

                    // Inner glow
                    Circle()
                        .fill(accent.opacity(pulse ? 0.12 : 0.06))
                        .frame(width: 170, height: 170)
                        .blur(radius: 24)

                    // Countdown text
                    Text(breakManager.countdownText)
                        .font(.system(size: 52, weight: .ultraLight, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
                .padding(.vertical, 8)

                // Skip button
                Button {
                    breakManager.skipBreak()
                } label: {
                    Text("Skip Break")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(.ultraThinMaterial)
                                .environment(\.colorScheme, .dark)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .scaleEffect(appear ? 1.0 : 0.85)
            .opacity(appear ? 1.0 : 0.0)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onAppear {
            randomMessage = (isEye ? Self.eyeMessages : Self.stretchMessages).randomElement() ?? ""
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                appear = true
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
