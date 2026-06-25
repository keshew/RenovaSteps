import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()

            TabView(selection: $currentPage) {
                OnboardingPage1(onNext: { withAnimation { currentPage = 1 } })
                    .tag(0)
                OnboardingPage2(onNext: { withAnimation { currentPage = 2 } })
                    .tag(1)
                OnboardingPage3(onComplete: onComplete)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

            // Dots + Skip
            VStack {
                HStack {
                    Spacer()
                    Button("Skip") { onComplete() }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(DS.textMuted)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Capsule()
                            .fill(i == currentPage ? DS.amber : DS.divider)
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Page 1: Follow Correct Steps
struct OnboardingPage1: View {
    var onNext: () -> Void
    @State private var isVisible = false
    @State private var tapped = false
    @State private var burstScale: CGFloat = 1.0
    @State private var burstOpacity: Double = 0
    @State private var stepsAppear = false

    let steps = ["Demo", "Wiring", "Plaster", "Paint", "Floor"]
    let stepColors: [Color] = [DS.danger, DS.warning, DS.orange, DS.blue, DS.success]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Interactive illustration
            ZStack {
                // Burst effect on tap
                ForEach(0..<8) { i in
                    Circle()
                        .fill(stepColors[i % stepColors.count].opacity(0.3))
                        .frame(width: tapped ? 80 : 10, height: tapped ? 80 : 10)
                        .offset(
                            x: tapped ? cos(Double(i) * .pi / 4) * 90 : 0,
                            y: tapped ? sin(Double(i) * .pi / 4) * 90 : 0
                        )
                        .opacity(burstOpacity)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(Double(i) * 0.03), value: tapped)
                }

                VStack(spacing: 0) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                        HStack {
                            ZStack {
                                Circle().fill(stepColors[i]).frame(width: 32, height: 32)
                                Text("\(i+1)").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            }
                            Text(step)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(DS.textPrimary)
                            Spacer()
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(stepColors[i])
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(DS.card)
                        .cornerRadius(10)
                        .scaleEffect(stepsAppear ? 1 : 0.8)
                        .opacity(stepsAppear ? 1 : 0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(i) * 0.08 + (isVisible ? 0 : 0.5)), value: stepsAppear)
                    }
                }
                .frame(maxWidth: 280)
                .onTapGesture {
                    guard !tapped else { return }
                    tapped = true
                    withAnimation(.easeOut(duration: 0.3)) { burstOpacity = 0.8 }
                    withAnimation(.easeIn(duration: 0.6).delay(0.4)) { burstOpacity = 0 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        tapped = false
                    }
                }
            }
            .frame(height: 320)
            .overlay(
                Text("Tap to animate →")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DS.textMuted)
                    .padding(.top, 8),
                alignment: .bottom
            )

            Spacer().frame(height: 40)

            VStack(spacing: 12) {
                Text("Follow Correct Steps")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(DS.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)

                Text("Get the right sequence for every repair stage.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(DS.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 15)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: isVisible)

            Spacer().frame(height: 48)

            Button("Next", action: onNext)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 32)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.5), value: isVisible)

            Spacer().frame(height: 80)
        }
        .onAppear {
            isVisible = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { stepsAppear = true }
        }
        .onDisappear { isVisible = false; stepsAppear = false }
    }
}

// MARK: - Page 2: Track Dependencies
struct OnboardingPage2: View {
    var onNext: () -> Void
    @State private var isVisible = false
    @State private var dragOffset: CGSize = .zero
    @State private var connected = false
    @State private var arrowProgress: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                // Background glow
                Ellipse()
                    .fill(DS.glowYellow)
                    .frame(width: 200, height: 100)
                    .blur(radius: 40)
                    .opacity(isVisible ? 0.6 : 0)

                VStack(spacing: 24) {
                    // Node A
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(DS.card)
                                .frame(width: 140, height: 52)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.amber.opacity(0.5), lineWidth: 1.5))
                            Text("Wiring")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(DS.amber)
                        }
                        Text("Step A")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(DS.textMuted)
                    }

                    // Arrow
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(DS.amber)
                            .frame(width: 2, height: 40)
                            .scaleEffect(y: connected ? 1 : 0, anchor: .top)
                            .animation(.easeInOut(duration: 0.4), value: connected)

                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.system(size: 14))
                            .foregroundColor(DS.amber)
                            .opacity(connected ? 1 : 0.3)
                            .scaleEffect(connected ? 1 : 0.5)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: connected)
                    }

                    // Node B – draggable
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(DS.card)
                                .frame(width: 140, height: 52)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.blue.opacity(connected ? 1 : 0.3), lineWidth: 1.5))
                            Text("Plumbing")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(DS.blue)
                        }
                        Text("Step B — drag to connect")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(DS.textMuted)
                    }
                    .offset(dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { val in
                                dragOffset = CGSize(width: val.translation.width * 0.3, height: max(-60, min(0, val.translation.height)))
                                if val.translation.height < -40 && !connected {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { connected = true }
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { dragOffset = .zero }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation { connected = false }
                                }
                            }
                    )
                }
            }
            .frame(height: 300)

            Spacer().frame(height: 40)

            VStack(spacing: 12) {
                Text("Track Dependencies")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(DS.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)

                Text("Know what must be done before the next step.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(DS.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 15)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: isVisible)

            Spacer().frame(height: 48)

            Button("Next", action: onNext)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 32)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.5), value: isVisible)

            Spacer().frame(height: 80)
        }
        .onAppear { withAnimation(.easeOut(duration: 0.5)) { isVisible = true } }
        .onDisappear { isVisible = false }
    }
}

// MARK: - Page 3: Avoid Rework
struct OnboardingPage3: View {
    var onComplete: () -> Void
    @State private var isVisible = false
    @State private var errorReveal = false
    @State private var scroll: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                // "Before fix" scenario
                VStack(spacing: 10) {
                    errorCard(icon: "xmark.circle.fill", color: DS.danger, text: "Painted before plastering", sub: "Surfaces damaged")
                        .scaleEffect(errorReveal ? 0.9 : 1)
                        .opacity(errorReveal ? 0.3 : 1)
                    errorCard(icon: "exclamationmark.triangle.fill", color: DS.warning, text: "Flooring before plumbing", sub: "Cuts required")
                        .scaleEffect(errorReveal ? 0.9 : 1)
                        .opacity(errorReveal ? 0.3 : 1)
                    errorCard(icon: "xmark.circle.fill", color: DS.danger, text: "Trim before painting", sub: "Repaint needed")
                        .scaleEffect(errorReveal ? 0.9 : 1)
                        .opacity(errorReveal ? 0.3 : 1)

                    // Fixed overlay
                    if errorReveal {
                        VStack(spacing: 10) {
                            fixedCard(text: "All steps in correct order")
                            fixedCard(text: "Zero rework detected")
                            fixedCard(text: "Timeline on track")
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: 300)
                .onTapGesture {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        errorReveal.toggle()
                    }
                }
            }
            .frame(height: 300)

            Spacer().frame(height: 40)

            VStack(spacing: 12) {
                Text("Avoid Rework")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(DS.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)

                Text("Prevent expensive mistakes and delays.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(DS.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 15)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: isVisible)

            Spacer().frame(height: 48)

            Button("Get Started") { onComplete() }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 32)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.5), value: isVisible)

            Spacer().frame(height: 80)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { isVisible = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { errorReveal = true }
            }
        }
        .onDisappear { isVisible = false; errorReveal = false }
    }

    @ViewBuilder
    func errorCard(icon: String, color: Color, text: String, sub: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(color).font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text(text).font(.system(size: 14, weight: .semibold)).foregroundColor(DS.textPrimary)
                Text(sub).font(.system(size: 12)).foregroundColor(DS.textMuted)
            }
            Spacer()
        }
        .padding(12)
        .background(DS.card)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.3), lineWidth: 1))
    }

    @ViewBuilder
    func fixedCard(text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.shield.fill").foregroundColor(DS.success).font(.system(size: 20))
            Text(text).font(.system(size: 14, weight: .semibold)).foregroundColor(DS.success)
            Spacer()
        }
        .padding(12)
        .background(DS.success.opacity(0.1))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.success.opacity(0.3), lineWidth: 1))
    }
}
