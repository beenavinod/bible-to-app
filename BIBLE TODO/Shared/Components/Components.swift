import SwiftUI

struct AppBackgroundView: View {
    let background: AppBackground

    var body: some View {
        LinearGradient(
            colors: background.gradientColors,
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(background.gradientColors.last?.opacity(0.35) ?? .clear)
                .frame(width: 240, height: 240)
                .blur(radius: 30)
                .offset(x: 80, y: -40)
        }
    }
}

struct HomeWallpaperBackgroundView: View {
    let wallpaper: HomeWallpaper

    var body: some View {
        Group {
            if let gradient = wallpaper.homeLinearGradient {
                gradient
            } else {
                wallpaper.solidBackgroundColor
            }
        }
        .ignoresSafeArea()
    }
}

/// Circular press-and-hold control for the Home “today’s task” card (incomplete / in progress / done).
struct HomePressHoldCircleView: View {
    let progress: Double
    let isCompleted: Bool
    let isInteractive: Bool
    let primaryText: Color
    let secondaryText: Color
    let accent: Color
    let accentSoft: Color

    let onPress: () -> Void
    let onRelease: () -> Void

    private let diameter: CGFloat = 108
    private let ringWidth: CGFloat = 4

    private var inProgress: Bool {
        isInteractive && !isCompleted && progress > 0 && progress < 1
    }

    var body: some View {
        let gesture = DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard isInteractive, !isCompleted else { return }
                onPress()
            }
            .onEnded { _ in
                guard isInteractive, !isCompleted else { return }
                onRelease()
            }

        VStack(spacing: 8) {
            ZStack {
                if isCompleted {
                    Circle()
                        .fill(Color(red: 0.55, green: 0.68, blue: 0.58))
                        .frame(width: diameter, height: diameter)
                        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)

                    Image(systemName: "checkmark")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                } else if inProgress {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.99, green: 0.99, blue: 0.98),
                                    accentSoft.opacity(0.55),
                                ],
                                center: .center,
                                startRadius: 4,
                                endRadius: diameter * 0.55
                            )
                        )
                        .frame(width: diameter, height: diameter)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(accent, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: diameter - ringWidth, height: diameter - ringWidth)

                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(primaryText.opacity(0.85))
                } else {
                    Circle()
                        .fill(accentSoft.opacity(0.35))
                        .frame(width: diameter, height: diameter)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(primaryText.opacity(0.85))
                }
            }
            .contentShape(Circle())
            .gesture(gesture)

            Text(isCompleted ? "Completed" : "Press and hold to complete")
                .font(.caption.weight(.medium))
                .foregroundStyle(isCompleted ? primaryText : secondaryText)
                .multilineTextAlignment(.center)
                .frame(width: diameter + 8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isCompleted ? "Completed" : "Press and hold to complete today’s task")
    }
}

struct CardContainer<Content: View>: View {
    let palette: AppThemePalette
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(20)
            .background(palette.card)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(palette.border.opacity(0.55), lineWidth: 1)
            )
            .shadow(color: palette.shadow, radius: 16, x: 0, y: 10)
    }
}

struct TopBar: View {
    let title: String
    let subtitle: String?
    let palette: AppThemePalette
    var showsBackButton = false
    /// Opens the Home background picker (Home tab).
    var onHomeBackgroundTap: (() -> Void)? = nil
    /// When set, shows a tappable share control that opens your share flow.
    var onShareTap: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top) {
            if showsBackButton {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(palette.primaryText)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.title3, design: .serif, weight: .regular))
                    .foregroundStyle(palette.primaryText)

                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(palette.secondaryText)
                }
            }

            Spacer()

            HStack(spacing: 14) {
                if let onHomeBackgroundTap {
                    Button(action: onHomeBackgroundTap) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.headline)
                            .foregroundStyle(palette.primaryText)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Home background")
                }

                if let onShareTap {
                    Button(action: onShareTap) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundStyle(palette.primaryText)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Share")
                }
            }
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
    }
}

struct HoldToCompleteButton: View {
    let progress: Double
    let palette: AppThemePalette
    let isCompleted: Bool
    let onPress: () -> Void
    let onRelease: () -> Void

    var body: some View {
        let gesture = DragGesture(minimumDistance: 0)
            .onChanged { _ in onPress() }
            .onEnded { _ in onRelease() }

        ZStack {
            Circle()
                .stroke(palette.border, lineWidth: 2)
                .frame(width: 94, height: 94)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(palette.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 94, height: 94)
                .animation(.linear(duration: 0.08), value: progress)

            Circle()
                .fill(palette.card)
                .frame(width: 78, height: 78)
                .overlay {
                    Text(isCompleted ? "Done" : "Hold")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(palette.secondaryText)
                }
                .scaleEffect(isCompleted ? 1.04 : 1)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isCompleted)
        }
        .contentShape(Circle())
        .gesture(gesture)
        .accessibilityLabel(isCompleted ? "Completed" : "Hold to complete")
    }
}

struct HoldToCompleteBar: View {
    let progress: Double
    let secondaryText: Color
    let trackFill: Color
    let fillColor: Color
    let isCompleted: Bool
    let onPress: () -> Void
    let onRelease: () -> Void

    var body: some View {
        let gesture = DragGesture(minimumDistance: 0)
            .onChanged { _ in onPress() }
            .onEnded { _ in onRelease() }

        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(trackFill)
                        .frame(height: 11)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(secondaryText.opacity(0.35), lineWidth: 1)
                        )

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(fillColor)
                        .frame(width: max(6, CGFloat(progress) * geo.size.width), height: 11)
                        .animation(.linear(duration: 0.08), value: progress)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .frame(height: 11)

            Text(isCompleted ? "Completed for today" : "Press and hold to complete")
                .font(.caption)
                .foregroundStyle(secondaryText)
                .frame(maxWidth: .infinity)
        }
        .contentShape(Rectangle())
        .gesture(gesture)
        .accessibilityLabel(isCompleted ? "Completed" : "Hold to complete")
    }
}

struct WeekProgressView: View {
    let records: [DailyRecord?]
    let palette: AppThemePalette

    private let labels = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(records.enumerated()), id: \.offset) { index, record in
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill((record?.completed == true ? palette.accent.opacity(0.9) : palette.card))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(record?.completed == true ? palette.accent.opacity(0.4) : palette.border, lineWidth: 1)
                            )

                        if record?.completed == true {
                            Image(systemName: "checkmark")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(.white)
                        }
                    }

                    Text(labels[index])
                        .font(.caption)
                        .foregroundStyle(palette.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct AchievementBadgeView: View {
    let achievement: Achievement
    let unlocked: Bool
    /// Highlight when this badge is the one chosen for the Lock Screen accessory widget.
    var isLockScreenSelected: Bool = false
    let palette: AppThemePalette

    private var subtitle: String {
        switch achievement.type {
        case .taskStreak:
            "\(achievement.actionsRequired)d"
        case .verseShare:
            "\(achievement.actionsRequired)x"
        case .firstShare:
            "1st"
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            badgeIcon
            badgeLabel
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var badgeIcon: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(palette.accent.opacity(0.15))
            .frame(height: 68)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(palette.accent.opacity(0.45), lineWidth: 1)
            }
            .overlay {
                Image(systemName: achievement.symbolName)
                    .font(.system(size: 28))
                    .foregroundStyle(palette.accent)
                    .scaleEffect(unlocked ? 1.05 : 1.0)
                    .shadow(
                        color: unlocked ? achievement.rarity.glowColor : .clear,
                        radius: unlocked ? 10 : 0
                    )
            }
            .overlay(alignment: .bottomTrailing) {
                if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(palette.secondaryText.opacity(0.7))
                        .padding(3)
                        .background(
                            Circle()
                                .fill(palette.card)
                                .shadow(color: palette.shadow, radius: 2, y: 1)
                        )
                        .offset(x: -4, y: -4)
                }
            }
            .overlay(alignment: .topLeading) {
                if unlocked, isLockScreenSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(palette.accent)
                        .shadow(color: palette.card, radius: 0, x: 0, y: 0)
                        .shadow(color: palette.card, radius: 1, x: 0, y: 0)
                        .accessibilityLabel("Selected for Lock Screen widget")
                        .offset(x: 2, y: 2)
                }
            }
    }

    private var badgeLabel: some View {
        VStack(spacing: 2) {
            Text(achievement.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(palette.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 36, alignment: .top)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(palette.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

struct BadgeDetailSheet: View {
    let achievement: Achievement
    let unlocked: Bool
    var isLockScreenSelected: Bool = false
    let palette: AppThemePalette
    var onSelectForLockScreen: () -> Void = {}
    var onClearLockScreenSelection: () -> Void = {}
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer(minLength: 24)

                ZStack {
                    Circle()
                        .fill(palette.accent.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .overlay {
                            Circle()
                                .stroke(palette.accent.opacity(0.4), lineWidth: 2)
                        }
                        .shadow(
                            color: unlocked ? achievement.rarity.glowColor : .clear,
                            radius: unlocked ? 16 : 0
                        )

                    Image(systemName: achievement.symbolName)
                        .font(.system(size: 48))
                        .foregroundStyle(palette.accent)

                    if !unlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(palette.secondaryText.opacity(0.7))
                            .padding(5)
                            .background(
                                Circle()
                                    .fill(palette.card)
                                    .shadow(color: palette.shadow, radius: 2, y: 1)
                            )
                            .offset(x: 38, y: 38)
                    }
                }

                Text(achievement.name)
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .foregroundStyle(palette.primaryText)
                    .padding(.top, 20)

                Text(achievement.badgeDescription)
                    .font(.body)
                    .foregroundStyle(palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
                    .padding(.horizontal, 32)

                Divider()
                    .overlay(palette.border.opacity(0.7))
                    .padding(.vertical, 24)
                    .padding(.horizontal, 40)

                VStack(spacing: 14) {
                    badgeInfoRow(label: "Type", value: badgeTypeLabel)
                    badgeInfoRow(label: "Rarity", value: achievement.rarity.rawValue.capitalized)
                    badgeInfoRow(label: "Requirement", value: requirementLabel)
                    badgeInfoRow(label: "Status", value: unlocked ? "Earned" : "Locked")
                }
                .padding(.horizontal, 32)

                if unlocked {
                    lockScreenWidgetSection
                        .padding(.horizontal, 28)
                        .padding(.top, 8)
                }

                Spacer(minLength: 24)

                if unlocked {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(palette.accent)
                        Text("You earned this badge!")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(palette.accent)
                    }
                    .padding(.bottom, 24)
                } else {
                    Text("Keep going to unlock this badge")
                        .font(.subheadline)
                        .foregroundStyle(palette.secondaryText)
                        .padding(.bottom, 24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(palette.canvas.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(palette.accent)
                }
            }
            .toolbarBackground(palette.card.opacity(0.92), for: .navigationBar)
        }
    }

    @ViewBuilder
    private var lockScreenWidgetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Lock Screen widget")
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.secondaryText)
                .textCase(.uppercase)
                .tracking(0.8)

            if isLockScreenSelected {
                Label("Using on Lock Screen", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.accent)

                Text("This badge appears when you add the Bible Life Lock Screen widget.")
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    onClearLockScreenSelection()
                    dismiss()
                } label: {
                    Label("Remove from Lock Screen widget", systemImage: "iphone.circle")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(palette.secondaryText)
            } else {
                Button {
                    onSelectForLockScreen()
                    dismiss()
                } label: {
                    Label("Use for Lock Screen widget", systemImage: "iphone.circle")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(palette.headerAccent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var badgeTypeLabel: String {
        switch achievement.type {
        case .taskStreak: "Daily Streak"
        case .verseShare: "Verse Sharing"
        case .firstShare: "First Share"
        }
    }

    private var requirementLabel: String {
        switch achievement.type {
        case .taskStreak:
            "\(achievement.actionsRequired) day streak"
        case .verseShare:
            "Share \(achievement.actionsRequired) verses"
        case .firstShare:
            "Share a verse for the first time"
        }
    }

    private func badgeInfoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(palette.secondaryText)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(palette.primaryText)
        }
    }
}

// MARK: - Badge Unlocked Celebration

struct BadgeUnlockedSheet: View {
    let achievement: Achievement
    let palette: AppThemePalette
    let onContinue: () -> Void

    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var confettiActive = false

    var body: some View {
        ZStack {
            palette.canvas.ignoresSafeArea()

            ForEach(confettiParticles) { particle in
                ConfettiPieceView(particle: particle, active: confettiActive)
            }

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(palette.accent.opacity(0.12))
                        .frame(width: 160, height: 160)
                        .shadow(
                            color: achievement.rarity.glowColor.opacity(0.6),
                            radius: glowRadius
                        )

                    Circle()
                        .stroke(palette.accent.opacity(0.35), lineWidth: 2)
                        .frame(width: 160, height: 160)

                    Image(systemName: achievement.symbolName)
                        .font(.system(size: 64, weight: .medium))
                        .foregroundStyle(palette.accent)
                        .shadow(
                            color: achievement.rarity.glowColor,
                            radius: glowRadius * 0.6
                        )
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                VStack(spacing: 8) {
                    Text("Badge Unlocked!")
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(2)
                        .foregroundStyle(palette.accent)

                    Text(achievement.name)
                        .font(.system(.title, design: .serif, weight: .bold))
                        .foregroundStyle(palette.primaryText)

                    Text(achievement.badgeDescription)
                        .font(.title3)
                        .foregroundStyle(palette.secondaryText)
                        .multilineTextAlignment(.center)

                    Text(achievement.rarity.rawValue.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(1.4)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(achievement.rarity.glowColor.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(achievement.rarity.glowColor.opacity(0.5), lineWidth: 1)
                                )
                        )
                        .foregroundStyle(palette.primaryText)
                        .padding(.top, 4)
                }
                .padding(.top, 28)
                .padding(.horizontal, 32)
                .opacity(textOpacity)

                Spacer()

                Button(action: onContinue) {
                    Text("Continue")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            LinearGradient(
                                colors: [palette.headerAccent, palette.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: palette.shadow.opacity(0.34), radius: 18, x: 0, y: 10)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
                .opacity(buttonOpacity)
            }
        }
        .task {
            confettiParticles = (0..<40).map { _ in ConfettiParticle() }

            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }

            try? await Task.sleep(for: .milliseconds(200))
            confettiActive = true

            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                glowRadius = 24
            }

            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeOut(duration: 0.5)) {
                textOpacity = 1.0
            }

            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeOut(duration: 0.4)) {
                buttonOpacity = 1.0
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let startXFraction: CGFloat
    let driftX: CGFloat
    let size: CGFloat
    let rotation: Double
    let shape: ConfettiShape
    let duration: Double
    let delay: Double

    enum ConfettiShape: CaseIterable {
        case circle, rectangle, triangle
    }

    init() {
        let colors: [Color] = [
            .yellow, .orange, .green, .blue, .purple, .pink, .red, .mint, .teal
        ]
        color = colors.randomElement() ?? .yellow
        startXFraction = CGFloat.random(in: -0.05...1.05)
        driftX = CGFloat.random(in: -60...60)
        size = CGFloat.random(in: 6...12)
        rotation = Double.random(in: 0...360)
        shape = ConfettiShape.allCases.randomElement() ?? .circle
        duration = Double.random(in: 2.0...3.5)
        delay = Double.random(in: 0...0.5)
    }
}

private struct ConfettiPieceView: View {
    let particle: ConfettiParticle
    let active: Bool

    var body: some View {
        GeometryReader { geo in
            let startX = geo.size.width * particle.startXFraction
            confettiContent
                .rotationEffect(.degrees(active ? particle.rotation + 360 : particle.rotation))
                .position(
                    x: active ? startX + particle.driftX : startX,
                    y: active ? geo.size.height + 40 : -20
                )
                .opacity(active ? 0 : 1)
                .animation(
                    .easeIn(duration: particle.duration).delay(particle.delay),
                    value: active
                )
        }
    }

    @ViewBuilder
    private var confettiContent: some View {
        switch particle.shape {
        case .circle:
            Circle()
                .fill(particle.color)
                .frame(width: particle.size, height: particle.size)
        case .rectangle:
            RoundedRectangle(cornerRadius: 2)
                .fill(particle.color)
                .frame(width: particle.size, height: particle.size * 1.6)
        case .triangle:
            ConfettiTriangle()
                .fill(particle.color)
                .frame(width: particle.size, height: particle.size)
        }
    }
}

private struct ConfettiTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct WidgetPreviewCard: View {
    let palette: AppThemePalette
    let verseReference: String
    let taskTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BIBLE LIFE")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(palette.secondaryText)

            Text("Daily Verse")
                .font(.headline)
                .foregroundStyle(palette.primaryText)

            Text(verseReference)
                .font(.subheadline)
                .foregroundStyle(palette.secondaryText)

            Divider()
                .overlay(palette.border.opacity(0.7))

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Action")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.secondaryText)
                    Text(taskTitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(palette.primaryText)
                }

                Spacer()

                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.title3)
                    .foregroundStyle(palette.accent)
            }
        }
        .padding(16)
        .background(palette.card.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(palette.border.opacity(0.75), lineWidth: 1)
        )
    }
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let palette: AppThemePalette

    var body: some View {
        CardContainer(palette: palette) {
            VStack(spacing: 12) {
                Image(systemName: "book.closed")
                    .font(.largeTitle)
                    .foregroundStyle(palette.accent)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(palette.primaryText)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(palette.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
