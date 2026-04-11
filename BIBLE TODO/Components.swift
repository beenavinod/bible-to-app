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
    let palette: AppThemePalette

    var body: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(unlocked ? achievement.accentColor.color.opacity(0.2) : palette.card)
                .frame(height: 68)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(unlocked ? achievement.accentColor.color.opacity(0.45) : palette.border, lineWidth: 1)
                }
                .overlay {
                    Image(systemName: unlocked ? achievement.symbolName : "lock")
                        .font(.system(size: 28))
                        .foregroundStyle(unlocked ? achievement.accentColor.color : palette.secondaryText.opacity(0.55))
                }

            VStack(spacing: 2) {
                Text(achievement.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, minHeight: 36, alignment: .top)
                Text(achievement.subtitle)
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, alignment: .top)
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

struct ThemeSwatchView: View {
    let colors: [Color]
    let isSelected: Bool
    let palette: AppThemePalette

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                Circle()
                    .fill(color)
                    .frame(width: 18, height: 18)
            }
        }
        .padding(10)
        .background(palette.card.opacity(isSelected ? 1 : 0.7))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(isSelected ? palette.accent : palette.border, lineWidth: 1)
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
