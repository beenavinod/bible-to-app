import Photos
import SwiftUI
import UIKit

// MARK: - Export (square: fits phone preview + works for Instagram / feeds)

private enum ShareExportLayout {
    static let side: CGFloat = 1080
    static let previewMaxHeight: CGFloat = 280
    static let horizontalPadding: CGFloat = 48
}

// MARK: - Payload

enum ShareDrawerPayload: Identifiable, Equatable {
    case verse(DailyRecord, wallpaper: HomeWallpaper)
    case streak(StreakSummary, week: [DailyRecord?])

    var id: String {
        switch self {
        case .verse(let r, let wallpaper):
            return "v-\(r.id.uuidString)-\(wallpaper.rawValue)"
        case .streak(let s, let week):
            let bits = week.map { $0?.completed == true ? "1" : "0" }.joined()
            return "s-\(s.currentStreak)-\(s.longestStreak)-\(bits)"
        }
    }
}

// MARK: - Background (aligned with app + streak / verse widgets)

private struct ShareThemedCanvas: View {
    let palette: AppThemePalette

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [palette.canvas, palette.card],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(palette.headerAccent.opacity(0.2))
                .frame(width: 420, height: 420)
                .blur(radius: 50)
                .offset(x: 320, y: -280)

            Circle()
                .fill(palette.tabInactive.opacity(0.25))
                .frame(width: 360, height: 360)
                .blur(radius: 45)
                .offset(x: -280, y: 340)
        }
        .frame(width: ShareExportLayout.side, height: ShareExportLayout.side)
        .clipped()
    }
}

// MARK: - Verse share template (home wallpaper + verse + white task card + watermark)

struct ShareableVerseCardLayout: View {
    let record: DailyRecord
    let wallpaper: HomeWallpaper
    /// When `false`, export verse-only (no task card) for free-tier users.
    var showsTaskCard: Bool = true

    private let side = ShareExportLayout.side
    private var fg: HomeForegroundStyle { wallpaper.homeForeground }

    var body: some View {
        let verseScale: CGFloat = 1.55
        let taskScale: CGFloat = 1.42

        ZStack {
            Group {
                if let gradient = wallpaper.homeLinearGradient {
                    gradient
                } else {
                    wallpaper.solidBackgroundColor
                }
            }
            .frame(width: side, height: side)
            .clipped()

            VStack(spacing: 0) {
                Spacer(minLength: 48)

                HomeDayVerseSection(record: record, fg: fg, fontScale: verseScale)
                    .padding(.horizontal, 44)

                if showsTaskCard {
                    Spacer(minLength: 32)

                    HomeDayTaskCardTextOnly(record: record, fg: fg, fontScale: taskScale, isViewingToday: true)
                        .padding(.horizontal, 48)
                } else {
                    Spacer(minLength: 24)
                }

                Spacer(minLength: 28)

                ShareVerseWatermark(fg: fg)
                    .padding(.bottom, 40)
            }
        }
        .frame(width: side, height: side)
    }
}

private struct ShareVerseWatermark: View {
    let fg: HomeForegroundStyle

    var body: some View {
        HStack(spacing: 10) {
            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            Text("Bible Life")
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundStyle(fg.primary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(fg.taskCardFill.opacity(0.92))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(fg.glassStroke.opacity(0.9), lineWidth: 1)
                )
        )
        .shadow(color: fg.taskCardShadow, radius: 8, x: 0, y: 4)
    }
}

// MARK: - Streak (streak widget style)

private let shareWeekdayLabels = ["S", "M", "T", "W", "T", "F", "S"]

struct ShareableStreakCardLayout: View {
    let summary: StreakSummary
    let week: [DailyRecord?]
    let palette: AppThemePalette

    private let pad = ShareExportLayout.horizontalPadding

    /// Seven entries for S–S, padded with `nil` if needed (matches home journey week row).
    private var weekPadded: [DailyRecord?] {
        if week.count >= 7 { return Array(week.prefix(7)) }
        return week + Array(repeating: nil, count: 7 - week.count)
    }

    var body: some View {
        ZStack {
            ShareThemedCanvas(palette: palette)

            VStack(alignment: .leading, spacing: 0) {
                Text("Bible Life")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(palette.primaryText)
                Text("My streak")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(palette.secondaryText)
                    .padding(.bottom, 20)

                topStatsRow

                totalDaysCard
                    .padding(.vertical, 18)

                Divider()
                    .overlay(palette.border.opacity(0.75))

                thisWeekSection

                Spacer(minLength: 12)

                Text("Bible Life · Live the Word")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(palette.secondaryText.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, pad)
            .padding(.vertical, 44)
        }
        .frame(width: ShareExportLayout.side, height: ShareExportLayout.side)
    }

    private var topStatsRow: some View {
        HStack(alignment: .top) {
            HStack(spacing: 14) {
                Circle()
                    .fill(palette.headerAccent.opacity(0.92))
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Streak")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(palette.secondaryText)
                    Text("\(summary.currentStreak)")
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .foregroundStyle(palette.primaryText)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text("Longest")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(palette.secondaryText)
                Text("\(summary.longestStreak)")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.primaryText)
            }
        }
    }

    private var totalDaysCard: some View {
        VStack(spacing: 6) {
            Text("Total Days Completed")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(palette.secondaryText)
            Text("\(summary.totalCompletedDays)")
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(palette.card.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(palette.border.opacity(0.7), lineWidth: 1)
        )
    }

    private var thisWeekSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("THIS WEEK")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(palette.primaryText)

            HStack(spacing: 10) {
                ForEach(0..<7, id: \.self) { index in
                    weekdayCell(index: index)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 8)
    }

    private func weekdayCell(index: Int) -> some View {
        let completed = weekPadded[index]?.completed == true
        let label = shareWeekdayLabels.indices.contains(index) ? shareWeekdayLabels[index] : "?"
        let circleSize: CGFloat = 52

        return VStack(spacing: 8) {
            Circle()
                .fill(completed ? palette.accent : palette.card)
                .frame(width: circleSize, height: circleSize)
                .overlay {
                    Circle()
                        .stroke(completed ? palette.accent.opacity(0.35) : palette.border, lineWidth: 1)
                }
                .overlay {
                    if completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(palette.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - In-sheet preview (fixed height, scale to fit — no clipping, buttons stay visible)

struct ShareableCardPreview: View {
    let payload: ShareDrawerPayload
    let palette: AppThemePalette
    var verseShareIncludesTask: Bool = true

    var body: some View {
        let w = ShareExportLayout.side
        let h = ShareExportLayout.side

        Color.clear
            .frame(maxHeight: ShareExportLayout.previewMaxHeight)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    let scale = min(geo.size.width / w, geo.size.height / h)
                    Group {
                        switch payload {
                        case .verse(let record, let wallpaper):
                            ShareableVerseCardLayout(record: record, wallpaper: wallpaper, showsTaskCard: verseShareIncludesTask)
                        case .streak(let summary, let week):
                            ShareableStreakCardLayout(summary: summary, week: week, palette: palette)
                        }
                    }
                    .frame(width: w, height: h)
                    .scaleEffect(scale, anchor: .center)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(palette.border.opacity(0.55), lineWidth: 1)
            )
            .shadow(color: palette.shadow.opacity(0.55), radius: 14, y: 8)
    }
}

// MARK: - Render image

@MainActor
enum ShareImageRenderer {
    static func render(_ payload: ShareDrawerPayload, palette: AppThemePalette, verseShareIncludesTask: Bool = true) -> UIImage? {
        let content: AnyView = {
            switch payload {
            case .verse(let r, let wallpaper):
                return AnyView(ShareableVerseCardLayout(record: r, wallpaper: wallpaper, showsTaskCard: verseShareIncludesTask))
            case .streak(let s, let w):
                return AnyView(ShareableStreakCardLayout(summary: s, week: w, palette: palette))
            }
        }()

        let renderer = ImageRenderer(content: content)
        renderer.scale = 1.0
        if #available(iOS 17.0, *) {
            renderer.isOpaque = true
            renderer.proposedSize = ProposedViewSize(
                width: ShareExportLayout.side,
                height: ShareExportLayout.side
            )
        }
        return renderer.uiImage
    }
}

// MARK: - Activity sheet

struct ShareActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Themed actions

private struct SharePaletteButton: View {
    let title: String
    let systemImage: String
    let palette: AppThemePalette
    var isPrimary = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isPrimary ? Color.white : palette.primaryText)
        .background {
            if isPrimary {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [palette.headerAccent, palette.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: palette.shadow.opacity(0.45), radius: 10, y: 5)
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(palette.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(palette.border.opacity(0.85), lineWidth: 1.2)
                    )
                    .shadow(color: palette.shadow.opacity(0.25), radius: 8, y: 4)
            }
        }
    }
}

// MARK: - Drawer

struct ShareDrawerSheet: View {
    let payload: ShareDrawerPayload
    let palette: AppThemePalette
    /// Verse shares omit the task card when `false` (free tier).
    var verseShareIncludesTask: Bool = true
    @Environment(\.dismiss) private var dismiss

    @State private var renderedImage: UIImage?
    @State private var showActivity = false
    @State private var isRendering = true
    @State private var saveMessage: String?
    @State private var showSaveAlert = false

    var body: some View {
        VStack(spacing: 0) {
            shareSheetHeader

            VStack(spacing: 14) {
                Text("Share to Instagram, WhatsApp, Messages, and more.")
                    .font(.subheadline)
                    .foregroundStyle(palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                ShareableCardPreview(payload: payload, palette: palette, verseShareIncludesTask: verseShareIncludesTask)
                    .padding(.horizontal, 8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Share preview")

                if isRendering {
                    ProgressView("Preparing image…")
                        .tint(palette.accent)
                        .foregroundStyle(palette.secondaryText)
                        .padding(.vertical, 4)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 16)

            Spacer(minLength: 0)

            VStack(spacing: 12) {
                SharePaletteButton(
                    title: "Share",
                    systemImage: "square.and.arrow.up",
                    palette: palette,
                    isPrimary: true
                ) {
                    guard renderedImage != nil else { return }
                    showActivity = true
                }
                .disabled(renderedImage == nil)
                .opacity(renderedImage == nil ? 0.55 : 1)

                SharePaletteButton(
                    title: "Save to Photos",
                    systemImage: "arrow.down.circle.fill",
                    palette: palette,
                    isPrimary: false
                ) {
                    saveToPhotos()
                }
                .disabled(renderedImage == nil)
                .opacity(renderedImage == nil ? 0.55 : 1)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.canvas.ignoresSafeArea())
        .alert("Photos", isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveMessage ?? "")
        }
        .sheet(isPresented: $showActivity) {
            if let renderedImage {
                ShareActivityView(items: [renderedImage])
                    .presentationDetents([.medium, .large])
            }
        }
        .task(id: payload.id) {
            isRendering = true
            renderedImage = ShareImageRenderer.render(payload, palette: palette, verseShareIncludesTask: verseShareIncludesTask)
            isRendering = false
        }
    }

    private var shareSheetHeader: some View {
        ZStack {
            Text("Share")
                .font(.headline)
                .foregroundStyle(palette.primaryText)

            HStack {
                Button("Done") { dismiss() }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(palette.primaryText)
                Spacer()
                Color.clear
                    .frame(width: 44, height: 1)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(palette.canvas)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(palette.border.opacity(0.55))
                .frame(height: 1)
        }
    }

    private func saveToPhotos() {
        guard let image = renderedImage else { return }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    saveMessage = "Photos access is needed to save your card. You can enable it in Settings."
                    showSaveAlert = true
                }
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success {
                        saveMessage = "Saved to your photo library. You can share it from the Photos app anytime."
                    } else {
                        saveMessage = error?.localizedDescription ?? "Couldn’t save the image."
                    }
                    showSaveAlert = true
                }
            })
        }
    }
}
