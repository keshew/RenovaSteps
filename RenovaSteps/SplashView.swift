import SwiftUI

struct SplashView: View {
    var onComplete: () -> Void

    @State private var isVisible = false
    @State private var bgGradientOffset: CGFloat = 0
    @State private var step1Scale: CGFloat = 0.3
    @State private var step2Scale: CGFloat = 0.3
    @State private var step3Scale: CGFloat = 0.3
    @State private var step4Scale: CGFloat = 0.3
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var particle1Y: CGFloat = 0
    @State private var particle2Y: CGFloat = 0
    @State private var particle3Y: CGFloat = 0
    @State private var particle1Opacity: Double = 0
    @State private var particle2Opacity: Double = 0
    @State private var particle3Opacity: Double = 0
    @State private var glowPulse: Bool = false
    @State private var exitScale: CGFloat = 1.0
    @State private var exitOpacity: Double = 1.0

    var body: some View {
        ZStack {
            // Layer 1: Animated background
            LinearGradient(
                colors: [DS.bg0, DS.bg1, DS.bg2],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Animated grid pattern
            Canvas { context, size in
                let spacing: CGFloat = 40
                let cols = Int(size.width / spacing) + 2
                let rows = Int(size.height / spacing) + 2
                for col in 0...cols {
                    for row in 0...rows {
                        let x = CGFloat(col) * spacing
                        let y = CGFloat(row) * spacing
                        let rect = CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3)
                        context.fill(Path(ellipseIn: rect), with: .color(DS.divider.opacity(0.4)))
                    }
                }
            }
            .ignoresSafeArea()

            // Layer 2: Floating particles
            GeometryReader { geo in
                ForEach(0..<8) { i in
                    Circle()
                        .fill(i % 2 == 0 ? DS.amber.opacity(0.15) : DS.orange.opacity(0.1))
                        .frame(width: CGFloat([20, 14, 18, 10, 22, 12, 16, 8][i]))
                        .position(
                            x: CGFloat([0.15, 0.8, 0.3, 0.7, 0.5, 0.2, 0.9, 0.6][i]) * geo.size.width,
                            y: CGFloat([0.2, 0.15, 0.7, 0.8, 0.4, 0.9, 0.5, 0.3][i]) * geo.size.height + (i % 2 == 0 ? particle1Y : particle2Y)
                        )
                        .opacity(i < 3 ? particle1Opacity : (i < 6 ? particle2Opacity : particle3Opacity))
                }
            }
            .ignoresSafeArea()

            // Layer 3: Main content
            VStack(spacing: 0) {
                Spacer()

                // Step icon animation
                ZStack {
                    // Glow ring
                    Circle()
                        .fill(DS.glowYellow)
                        .frame(width: glowPulse ? 160 : 130, height: glowPulse ? 160 : 130)
                        .blur(radius: 30)
                        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: glowPulse)

                    // Steps icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(LinearGradient(colors: [DS.amber, DS.orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 100, height: 100)
                            .shadow(color: DS.glowOrange, radius: 20, x: 0, y: 8)

                        // Staircase shape
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                Spacer()
                                Rectangle().fill(Color.white.opacity(0.9))
                                    .frame(width: 22, height: 8)
                                    .scaleEffect(x: step4Scale, y: 1, anchor: .trailing)
                            }
                            HStack(spacing: 0) {
                                Spacer()
                                Rectangle().fill(Color.white.opacity(0.85))
                                    .frame(width: 32, height: 8)
                                    .scaleEffect(x: step3Scale, y: 1, anchor: .trailing)
                            }
                            HStack(spacing: 0) {
                                Spacer()
                                Rectangle().fill(Color.white.opacity(0.9))
                                    .frame(width: 44, height: 8)
                                    .scaleEffect(x: step2Scale, y: 1, anchor: .trailing)
                            }
                            HStack(spacing: 0) {
                                Spacer()
                                Rectangle().fill(Color.white)
                                    .frame(width: 58, height: 8)
                                    .scaleEffect(x: step1Scale, y: 1, anchor: .trailing)
                            }
                        }
                        .frame(width: 68, height: 44)

                        // House peak
                        Image(systemName: "house.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .offset(y: -28)
                    }
                    .scaleEffect(logoScale)
                }
                .opacity(logoOpacity)

                Spacer().frame(height: 32)

                // App name
                VStack(spacing: 8) {
                    Text("RENOVA")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(DS.amber)
                        .opacity(titleOpacity)
                        .offset(y: titleOpacity == 1 ? 0 : 20)

                    Text("STEPS")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(DS.textPrimary)
                        .opacity(titleOpacity)
                        .offset(y: titleOpacity == 1 ? 0 : 20)
                }

                Spacer().frame(height: 16)

                Text("Build in the right order")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DS.textMuted)
                    .opacity(subtitleOpacity)
                    .offset(y: subtitleOpacity == 1 ? 0 : 10)

                Spacer()
            }
            .scaleEffect(exitScale)
            .opacity(exitOpacity)
        }
        .onAppear {
            guard !isVisible else { return }
            isVisible = true
            startAnimations()
        }
        .onDisappear {
            isVisible = false
            resetAnimations()
        }
    }

    private func startAnimations() {
        // Phase 1: Background + particles (0–0.6s)
        withAnimation(.easeIn(duration: 0.6)) {
            particle1Opacity = 1
            particle2Opacity = 0.7
            particle3Opacity = 0.5
        }
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            particle1Y = -30
        }
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            particle2Y = 20
        }

        // Phase 2: Logo (0.6–1.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            guard isVisible else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                guard isVisible else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.0)) { step1Scale = 1 }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.1)) { step2Scale = 1 }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2)) { step3Scale = 1 }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3)) { step4Scale = 1 }
            }
        }

        // Phase 3: Title (1.4–2.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            guard isVisible else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                titleOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                guard isVisible else { return }
                withAnimation(.easeOut(duration: 0.4)) {
                    subtitleOpacity = 1
                }
                glowPulse = true
            }
        }

        // Phase 4: Exit (2.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            guard isVisible else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                exitScale = 1.6
                exitOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                onComplete()
            }
        }
    }

    private func resetAnimations() {
        step1Scale = 0.3; step2Scale = 0.3; step3Scale = 0.3; step4Scale = 0.3
        logoScale = 0.5; logoOpacity = 0; titleOpacity = 0; subtitleOpacity = 0
        particle1Y = 0; particle2Y = 0; particle3Y = 0
        particle1Opacity = 0; particle2Opacity = 0; particle3Opacity = 0
        glowPulse = false; exitScale = 1.0; exitOpacity = 1.0
    }
}
