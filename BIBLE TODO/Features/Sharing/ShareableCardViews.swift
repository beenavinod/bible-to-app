import Photos
import SwiftUI
import UIKit

// MARK: - Export (9:16 — Instagram Stories / WhatsApp status, 1080×1920)

private enum ShareExportLayout {
    static let width: CGFloat = 1080
    static let height: CGFloat = 1920
    static var aspectRatio: CGFloat { width / height }
    /// ~390pt reference iPhone width: verse/task match on-screen home proportions at export width.
    static let storyTypographyScale: CGFloat = width / 390
    static let previewMaxHeight: CGFloat = 360
    static let horizontalPadding: CGFloat = 56
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
                .offset(x: -280, y: ShareExportLayout.height * 0.36)
        }
        .frame(width: ShareExportLayout.width, height: ShareExportLayout.height)
        .clipped()
    }
}

// MARK: - Verse share template (home wallpaper + verse + white task card + watermark)

struct ShareableVerseCardLayout: View {
    let record: DailyRecord
    let wallpaper: HomeWallpaper
    /// When `false`, export verse-only (no task card) for free-tier users.
    var showsTaskCard: Bool = true

    private let w = ShareExportLayout.width
    private let h = ShareExportLayout.height
    private var fg: HomeForegroundStyle { wallpaper.homeForeground }
    private var typeScale: CGFloat { ShareExportLayout.storyTypographyScale }

    var body: some View {
        ZStack {
            Group {
                if let assetName = wallpaper.imageAssetName {
                    Image(assetName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .overlay(Color.black.opacity(0.18))
                } else if let gradient = wallpaper.homeLinearGradient {
                    gradient
                } else {
                    wallpaper.solidBackgroundColor
                }
            }
            .frame(width: w, height: h)
            .clipped()

            VStack(spacing: 0) {
                Spacer(minLength: 120)

                HomeDayVerseSection(record: record, fg: fg, fontScale: typeScale)
                    .padding(.horizontal, ShareExportLayout.horizontalPadding)

                if showsTaskCard {
                    Spacer(minLength: 56)

                    HomeDayTaskCardTextOnly(record: record, fg: fg, fontScale: typeScale, isViewingToday: true)
                        .padding(.horizontal, ShareExportLayout.horizontalPadding)
                } else {
                    Spacer(minLength: 48)
                }

                Spacer(minLength: 72)

                ShareVerseWatermark(fg: fg, scale: min(typeScale / 2.35, 1.28))
                    .padding(.bottom, 100)
            }
        }
        .frame(width: w, height: h)
    }
}

private struct ShareVerseWatermark: View {
    let fg: HomeForegroundStyle
    /// Relative to the original 1× story mark; keeps branding readable on tall exports.
    var scale: CGFloat = 1

    var body: some View {
        let logo = 36 * scale
        let corner = 9 * scale
        HStack(spacing: 10 * scale) {
            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: logo, height: logo)
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))

            Text("Bible Life")
                .font(.system(size: 18 * scale, weight: .semibold, design: .default))
                .foregroundStyle(fg.primary)
        }
        .padding(.horizontal, 18 * scale)
        .padding(.vertical, 10 * scale)
        .background(
            Capsule(style: .continuous)
                .fill(fg.taskCardFill.opacity(0.92))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(fg.glassStroke.opacity(0.9), lineWidth: 1)
                )
        )
        .shadow(color: fg.taskCardShadow, radius: 8 * scale, x: 0, y: 4 * scale)
    }
}

// MARK: - Streak (full-height story: hero + stat cards + week row)

private let shareWeekdayLabels = ["S", "M", "T", "W", "T", "F", "S"]

struct ShareableStreakCardLayout: View {
    let summary: StreakSummary
    let week: [DailyRecord?]
    let palette: AppThemePalette

    private let w = ShareExportLayout.width
    private let h = ShareExportLayout.height
    private let pad = ShareExportLayout.horizontalPadding
    private var s: CGFloat { ShareExportLayout.storyTypographyScale }

    /// Seven entries for S–S, padded with `nil` if needed (matches home journey week row).
    private var weekPadded: [DailyRecord?] {
        if week.count >= 7 { return Array(week.prefix(7)) }
        return week + Array(repeating: nil, count: 7 - week.count)
    }

    private var heroDiameter: CGFloat { min(w * 0.52, 560) }
    private var heroNumberSize: CGFloat { heroDiameter * 0.34 }
    private var dayStreakCaptionSize: CGFloat { max(22, 26 * s / 2.45) }
    private var headlineSize: CGFloat { max(34, 40 * s / 2.5) }
    private var statCardCorner: CGFloat { 28 * s / 2.45 }
    private var weekDot: CGFloat { min(56 * s / 2.45, 68) }
    private var weekLabelSize: CGFloat { max(16, 18 * s / 2.45) }

    var body: some View {
        ZStack {
            ShareThemedCanvas(palette: palette)

            VStack(spacing: 0) {
                Spacer(minLength: h * 0.06)

                streakStoryHeader
                    .padding(.horizontal, pad)

                Spacer(minLength: h * 0.04)

                streakHeroOrb
                    .frame(maxWidth: .infinity)

                Spacer(minLength: h * 0.045)

                streakStatPairRow
                    .padding(.horizontal, pad)

                Spacer(minLength: h * 0.05)

                streakWeekSection
                    .padding(.horizontal, pad)

                Spacer(minLength: h * 0.04)

                streakStoryFooter
                    .padding(.horizontal, pad + 8)

                Spacer(minLength: h * 0.07)
            }
            .frame(width: w, height: h)
        }
        .frame(width: w, height: h)
    }

    private var streakStoryHeader: some View {
        VStack(spacing: 14 * s / 2.6) {
            HStack(spacing: 14 * s / 2.6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: headlineSize * 0.62, weight: .semibold))
                    .foregroundStyle(palette.accent)
                Text("Streak unlocked")
                    .font(.system(size: headlineSize, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.primaryText)
            }
            Text("Bible Life")
                .font(.system(size: 20 * s / 2.5, weight: .semibold, design: .serif))
                .foregroundStyle(palette.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }

    private var streakHeroOrb: some View {
        let streak = summary.currentStreak
        let caption = streak == 1 ? "DAY STREAK" : "DAYS STREAK"
        return ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [palette.accent, palette.headerAccent.opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: heroDiameter, height: heroDiameter)
                .shadow(color: palette.shadow.opacity(0.35), radius: 28, x: 0, y: 14)

            VStack(spacing: heroDiameter * 0.045) {
                Text("\(streak)")
                    .font(.system(size: heroNumberSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.35)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 2)

                Text(caption)
                    .font(.system(size: dayStreakCaptionSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .tracking(3)
            }
            .padding(.vertical, heroDiameter * 0.06)
        }
    }

    private var streakStatPairRow: some View {
        let gap: CGFloat = 22 * s / 2.5
        let labelPt = max(17, 19 * s / 2.5)
        let valuePt = max(44, 52 * s / 2.5)
        return HStack(alignment: .top, spacing: gap) {
            streakStatCard(title: "Longest", value: "\(summary.longestStreak)", labelPt: labelPt, valuePt: valuePt)
            streakStatCard(title: "Total days", value: "\(summary.totalCompletedDays)", labelPt: labelPt, valuePt: valuePt)
        }
    }

    private func streakStatCard(title: String, value: String, labelPt: CGFloat, valuePt: CGFloat) -> some View {
        VStack(spacing: 10 * s / 2.5) {
            Text(title)
                .font(.system(size: labelPt, weight: .medium, design: .rounded))
                .foregroundStyle(palette.secondaryText)
            Text(value)
                .font(.system(size: valuePt, weight: .bold, design: .rounded))
                .foregroundStyle(palette.primaryText)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28 * s / 2.5)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: statCardCorner, style: .continuous)
                .fill(palette.card)
                .shadow(color: palette.shadow.opacity(0.2), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: statCardCorner, style: .continuous)
                .stroke(palette.border.opacity(0.55), lineWidth: 1)
        )
    }

    private var streakWeekSection: some View {
        VStack(spacing: 22 * s / 2.5) {
            Text("THIS WEEK")
                .font(.system(size: max(15, 17 * s / 2.45), weight: .bold, design: .rounded))
                .foregroundStyle(palette.primaryText)
                .tracking(1.2)

            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    streakWeekdayCell(index: index)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private func streakWeekdayCell(index: Int) -> some View {
        let completed = weekPadded[index]?.completed == true
        let label = shareWeekdayLabels.indices.contains(index) ? shareWeekdayLabels[index] : "?"
        let strokeW: CGFloat = completed ? 0 : max(2, 2.5 * s / 2.45)

        return VStack(spacing: 12 * s / 2.5) {
            ZStack {
                Circle()
                    .fill(completed ? palette.accent : Color.clear)
                    .frame(width: weekDot, height: weekDot)
                if !completed {
                    Circle()
                        .stroke(palette.accent.opacity(0.85), lineWidth: strokeW)
                        .frame(width: weekDot, height: weekDot)
                }
                if completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: weekDot * 0.36, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            Text(label)
                .font(.system(size: weekLabelSize, weight: .bold, design: .rounded))
                .foregroundStyle(palette.primaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var streakStoryFooter: some View {
        VStack(spacing: 20 * s / 2.5) {
            Text("Consistency is worship")
                .font(.system(size: max(22, 26 * s / 2.45), weight: .semibold, design: .serif))
                .foregroundStyle(palette.primaryText.opacity(0.92))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            Text("Bible Life · Live the Word")
                .font(.system(size: max(16, 18 * s / 2.55), weight: .medium, design: .rounded))
                .foregroundStyle(palette.secondaryText.opacity(0.95))
                .multilineTextAlignment(.center)
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
        let w = ShareExportLayout.width
        let h = ShareExportLayout.height

        Color.clear
            .frame(maxHeight: ShareExportLayout.previewMaxHeight)
            .aspectRatio(ShareExportLayout.aspectRatio, contentMode: .fit)
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
                width: ShareExportLayout.width,
                height: ShareExportLayout.height
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
        ZStack {
            palette.canvas
                .ignoresSafeArea()

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
        }
        .compositingGroup()
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
                    .buttonStyle(.plain)
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
