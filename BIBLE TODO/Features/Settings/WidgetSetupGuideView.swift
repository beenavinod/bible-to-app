import Combine
import SwiftUI

private enum WidgetSetupPlacement {
    case homeScreen
    case lockScreen

    static func forWidget(id: String) -> Self {
        id == "LockScreenIconWidget" ? .lockScreen : .homeScreen
    }
}

private struct GuideStep: Identifiable {
    let id: Int
    let title: String
    let detail: String
}

/// Full-screen animated walkthrough for adding Bible Life widgets on iPhone (SwiftUI “video”).
struct WidgetSetupGuideView: View {
    let widget: WidgetInfo
    let palette: AppThemePalette
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pageIndex = 0

    private var placement: WidgetSetupPlacement {
        WidgetSetupPlacement.forWidget(id: widget.id)
    }

    private var steps: [GuideStep] {
        switch placement {
        case .homeScreen:
            homeScreenSteps(widgetId: widget.id, widgetName: widget.name)
        case .lockScreen:
            lockScreenSteps(widgetName: widget.name)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                palette.canvas.ignoresSafeArea()

                VStack(spacing: 0) {
                    phoneStage
                        .padding(.horizontal, 16)
                        .padding(.top, 6)

                    TabView(selection: $pageIndex) {
                        ForEach(steps) { step in
                            stepCaption(title: step.title, detail: step.detail)
                                .tag(step.id)
                                .padding(.horizontal, 22)
                                .padding(.top, 16)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 210)

                    pageDots
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Bible Life widgets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(palette.card.opacity(0.95), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { onDismiss() }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(palette.accent)
                }
            }
        }
        .tint(palette.accent)
        .modifier(WidgetGuideAutoPlayModifier(
            reduceMotion: reduceMotion,
            pageCount: steps.count,
            pageIndex: $pageIndex
        ))
    }

    private var phoneStage: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, 340)
            ZStack {
                FakeIPhoneFrame(
                    placement: placement,
                    stepIndex: pageIndex,
                    widgetId: widget.id,
                    palette: palette,
                    reduceMotion: reduceMotion
                )
                .frame(width: w)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 420)
    }

    private func stepCaption(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(palette.primaryText)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(palette.secondaryText)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(steps) { step in
                let i = step.id
                Capsule()
                    .fill(i == pageIndex ? palette.accent : palette.border.opacity(0.45))
                    .frame(width: i == pageIndex ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: pageIndex)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(pageIndex + 1) of \(steps.count)")
    }

    private func homeScreenSteps(widgetId: String, widgetName: String) -> [GuideStep] {
        let pickLine: String = {
            switch widgetId {
            case "StreakWidget":
                return "Swipe to preview sizes, choose **Bible Streak**, then tap **Add Widget**."
            case "VerseTaskWidget":
                return "Swipe to preview sizes, choose **Verse & Task**, then tap **Add Widget**."
            default:
                return "Swipe to preview sizes, choose **\(widgetName)**, then tap **Add Widget**."
            }
        }()

        return [
            GuideStep(id: 0, title: "Long press the Home Screen", detail: "On empty space or any app icon, touch and hold until icons gently jiggle."),
            GuideStep(id: 1, title: "You’re in edit mode", detail: "The dots under icons and the **+** button mean you can move apps and add widgets."),
            GuideStep(id: 2, title: "Tap the + button", detail: "In the top-left corner, tap **+** to open Apple’s widget gallery."),
            GuideStep(id: 3, title: "Search for Bible Life", detail: "Use the search field and type **Bible Life** so our app’s widgets appear."),
            GuideStep(id: 4, title: "Select Bible Life", detail: "Tap the **Bible Life** row (same icon as on your Home Screen) to see our widget styles."),
            GuideStep(id: 5, title: "Pick a size, then add", detail: pickLine),
            GuideStep(id: 6, title: "Widget appears on your Home Screen", detail: "It drops in above your apps. It’s still selected so you can position it."),
            GuideStep(id: 7, title: "Drag it into place", detail: "Drag the widget to an empty grid cell. Lift your finger when it snaps where you want it."),
            GuideStep(id: 8, title: "Resize (if available)", detail: "On supported sizes, drag the rounded handles on the edges until the outline matches the size you want."),
            GuideStep(id: 9, title: "Tap Done to finish", detail: "Tap **Done** in the upper corner. Your Bible Life widget stays on the Home Screen."),
        ]
    }

    private func lockScreenSteps(widgetName: String) -> [GuideStep] {
        [
            GuideStep(id: 0, title: "Long press the Lock Screen", detail: "Wake your iPhone, then touch and hold the clock or wallpaper until Customize appears."),
            GuideStep(id: 1, title: "Tap Customize", detail: "You’re editing the current Lock Screen layout."),
            GuideStep(id: 2, title: "Open the widget row", detail: "Tap the accessory strip **below the time** (or another widget slot) where small icons live."),
            GuideStep(id: 3, title: "Find Bible Life", detail: "Swipe the picker horizontally until you see **Bible Life**, then tap it."),
            GuideStep(id: 4, title: "Choose \(widgetName)", detail: "Select the **\(widgetName)** style, then confirm so it attaches to your Lock Screen."),
            GuideStep(id: 5, title: "Placed on your Lock Screen", detail: "The widget sits in the strip under the clock, next to Flashlight, Camera, or your other shortcuts."),
            GuideStep(id: 6, title: "Drag to reorder", detail: "While still editing, drag the Bible Life control left or right to change its order in the strip."),
            GuideStep(id: 7, title: "Close the editor", detail: "Tap **×** or the wallpaper, then **Done** (or lock) to save. Wake again to see your finished Lock Screen."),
        ]
    }
}

// MARK: - Auto-advance

private struct WidgetGuideAutoPlayModifier: ViewModifier {
    let reduceMotion: Bool
    let pageCount: Int
    @Binding var pageIndex: Int

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.onReceive(Timer.publish(every: 4.6, on: .main, in: .common).autoconnect()) { _ in
                guard pageCount > 0 else { return }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                    pageIndex = (pageIndex + 1) % pageCount
                }
            }
        }
    }
}

// MARK: - Phone chrome

private struct FakeIPhoneFrame: View {
    let placement: WidgetSetupPlacement
    let stepIndex: Int
    let widgetId: String
    let palette: AppThemePalette
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.9), Color.black.opacity(0.74)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.38), radius: 26, y: 16)

            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(placement == .lockScreen ? lockWallpaper : homeWallpaper)
                .padding(10)
                .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                .padding(10)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        .padding(18)
                }
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(Color.black.opacity(0.92))
                        .frame(width: 92, height: 28)
                        .padding(.top, 16)
                }
                .overlay {
                    stageContent
                        .padding(14)
                }
        }
        .aspectRatio(9 / 19.2, contentMode: .fit)
    }

    private var homeWallpaper: LinearGradient {
        LinearGradient(
            colors: [
                palette.headerAccent.opacity(0.42),
                palette.canvas,
                palette.accent.opacity(0.22),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var lockWallpaper: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.07, blue: 0.16),
                Color(red: 0.1, green: 0.12, blue: 0.26),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    @ViewBuilder
    private var stageContent: some View {
        switch placement {
        case .homeScreen:
            HomeScreenGuideDemo(step: stepIndex, widgetId: widgetId, palette: palette, reduceMotion: reduceMotion)
        case .lockScreen:
            LockScreenGuideDemo(step: stepIndex, palette: palette, reduceMotion: reduceMotion)
        }
    }
}

// MARK: - Bible Life branding (mini)

private struct BibleLifeAppIcon: View {
    let palette: AppThemePalette
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [palette.headerAccent, palette.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: "book.closed.fill")
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
    }
}

// MARK: - Mini widget previews (match shipping widgets)

private struct GuideStreakWidgetCard: View {
    let palette: AppThemePalette
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 6) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(palette.accent)
                Text("7")
                    .font(compact ? .caption.weight(.bold) : .title3.weight(.bold))
                    .foregroundStyle(palette.primaryText)
                Text("day streak")
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(palette.secondaryText)
            }
            if !compact {
                Capsule()
                    .fill(palette.border.opacity(0.5))
                    .frame(height: 1)
                HStack(spacing: 4) {
                    ForEach(0 ..< 5, id: \.self) { i in
                        Text("\(12 + i)")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(i < 3 ? palette.accent : palette.border.opacity(0.35)))
                    }
                }
            }
        }
        .padding(compact ? 8 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.card.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(palette.border.opacity(0.55), lineWidth: 1)
                )
        )
    }
}

private struct GuideVerseTaskWidgetCard: View {
    let palette: AppThemePalette
    var compact: Bool = false

    var body: some View {
        Group {
            if compact {
                VStack(alignment: .center, spacing: 3) {
                    Text("Let all that you do be done in love.")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(palette.primaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.75)
                    Text("1 Cor 16:14")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(palette.accent)
                        .multilineTextAlignment(.center)
                }
            } else {
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Encourage Someone")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(palette.primaryText)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                        Text("Send one meaningful message filled with hope.")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(palette.secondaryText)
                            .lineLimit(3)
                            .minimumScaleFactor(0.85)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "circle")
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(palette.secondaryText.opacity(0.55))
                }
            }
        }
        .padding(compact ? 8 : 11)
        .frame(maxWidth: .infinity, alignment: compact ? .center : .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [palette.card.opacity(0.98), palette.canvas.opacity(0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(palette.border.opacity(0.55), lineWidth: 1)
                )
        )
    }
}

private struct GuideLockBadgeAccessory: View {
    let palette: AppThemePalette

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.black.opacity(0.55),
                            Color.white.opacity(0.28),
                            Color.black.opacity(0.5),
                        ],
                        center: .center
                    )
                )
                .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
            VStack(spacing: 1) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("First Step")
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("1d")
                    .font(.system(size: 6, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(Circle())
    }
}

// MARK: - Home Screen “video” scenes

private struct HomeScreenGuideDemo: View {
    let step: Int
    let widgetId: String
    let palette: AppThemePalette
    let reduceMotion: Bool

    @State private var pulse = false
    @State private var galleryNudge = false
    @State private var resizePulse = false

    var body: some View {
        ZStack {
            homeIconLayer
                .opacity(step >= 1 && step <= 2 || step >= 6 && step <= 9 ? 1 : 0.5)
                .modifier(HomeJiggleModifier(active: step == 1 && !reduceMotion))

            if step == 0 {
                LongPressHint(reduceMotion: reduceMotion, handTint: palette.accent, ringTint: palette.accent)
            }

            if step >= 2, step < 6 {
                VStack {
                    HStack {
                        plusBadge
                            .scaleEffect(step == 2 && pulse && !reduceMotion ? 1.14 : 1)
                        Spacer()
                    }
                    Spacer()
                }
            }

            if step >= 8 {
                VStack {
                    HStack {
                        Spacer()
                        donePill
                    }
                    Spacer()
                }
            }

            if step >= 3, step < 6 {
                widgetGalleryOverlay
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if step >= 6 {
                placedWidgetLayer
            }
        }
        .animation(.easeInOut(duration: 0.42), value: step)
        .onAppear { runPulseLoops() }
        .onChange(of: step) { _, _ in
            runPulseLoops()
        }
    }

    private var homeIconLayer: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
        return LazyVGrid(columns: cols, spacing: 10) {
            ForEach(0 ..< 12, id: \.self) { i in
                if i == 0 {
                    VStack(spacing: 3) {
                        BibleLifeAppIcon(palette: palette, size: 40)
                        Text("Bible Life")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(palette.primaryText.opacity(0.85))
                    }
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(palette.card.opacity(0.9))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Image(systemName: ["house.fill", "message.fill", "calendar", "music.note", "camera.fill", "map.fill", "photo.fill", "envelope.fill", "phone.fill", "gamecontroller.fill", "leaf.fill"][i - 1])
                                .font(.system(size: 12))
                                .foregroundStyle(palette.secondaryText.opacity(0.55))
                        }
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 48)
    }

    private var plusBadge: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.96))
                .frame(width: 32, height: 32)
            Image(systemName: "plus")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(color: .black.opacity(0.22), radius: 3, y: 2)
    }

    private var donePill: some View {
        Text("Done")
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Capsule().fill(Color.blue.opacity(0.92)))
            .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
    }

    private var widgetGalleryOverlay: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {}) {
                    Text("Cancel")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.blue)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 6)
                        .buttonLabelHitRect()
                }
                .buttonStyle(.plain)
                Spacer()
                Text("Add Widget")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Spacer()
                Color.clear.frame(width: 52, height: 1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)

            Divider()

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                Text(step >= 3 ? "bible life" : "Search")
                    .font(.subheadline)
                    .foregroundStyle(step >= 3 ? Color.primary : Color.secondary)
                Spacer()
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemGroupedBackground)))

            if step >= 4 {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        galleryRow(title: "Weather", systemImage: "cloud.sun.fill", highlight: false)
                        galleryRow(title: "Photos", systemImage: "photo.on.rectangle.angled", highlight: false)
                        galleryRow(title: "Bible Life", systemImage: nil, highlight: true)
                    }
                }
                .frame(maxHeight: step >= 5 ? 72 : 120)
            }

            if step >= 5 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bible Life")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    sizePickerStrip
                    HStack {
                        Spacer()
                        Text("Add Widget")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(galleryNudge && !reduceMotion ? 1 : 0.88))
                                    .scaleEffect(galleryNudge && !reduceMotion ? 1.04 : 1)
                            )
                        Spacer()
                    }
                    .padding(.top, 4)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemGroupedBackground)))
            }

            Spacer(minLength: 0)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.35), radius: 20, y: -4)
        )
        .padding(.top, 36)
    }

    private func galleryRow(title: String, systemImage: String?, highlight: Bool) -> some View {
        HStack(spacing: 12) {
            if title == "Bible Life" {
                BibleLifeAppIcon(palette: palette, size: 40)
            } else if let systemImage {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay { Image(systemName: systemImage).foregroundStyle(.blue) }
            }
            Text(title)
                .font(.subheadline.weight(highlight ? .bold : .regular))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(highlight ? palette.accent.opacity(0.12) : Color.clear)
        )
        .overlay(alignment: .leading) {
            if highlight {
                RoundedRectangle(cornerRadius: 3)
                    .fill(palette.accent)
                    .frame(width: 4)
                    .padding(.vertical, 8)
            }
        }
    }

    private var sizePickerStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                switch widgetId {
                case "StreakWidget":
                    GuideStreakWidgetCard(palette: palette, compact: true)
                        .frame(width: 118, height: 76)
                        .overlay(selectionRing(on: true))
                    GuideStreakWidgetCard(palette: palette, compact: false)
                        .frame(width: 150, height: 100)
                        .overlay(selectionRing(on: false))
                case "VerseTaskWidget":
                    GuideVerseTaskWidgetCard(palette: palette, compact: true)
                        .frame(width: 110, height: 80)
                        .overlay(selectionRing(on: true))
                    GuideVerseTaskWidgetCard(palette: palette, compact: false)
                        .frame(width: 158, height: 102)
                        .overlay(selectionRing(on: false))
                default:
                    GuideStreakWidgetCard(palette: palette, compact: true)
                        .frame(width: 118, height: 76)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func selectionRing(on: Bool) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(on ? Color.blue : Color.clear, lineWidth: on ? 3 : 0)
    }

    @ViewBuilder
    private var placedWidgetLayer: some View {
        let cardWidth: CGFloat = 168
        VStack {
            Group {
                switch widgetId {
                case "VerseTaskWidget":
                    GuideVerseTaskWidgetCard(palette: palette, compact: false)
                default:
                    GuideStreakWidgetCard(palette: palette, compact: false)
                }
            }
            .frame(width: cardWidth, height: 108)
            .modifier(WidgetDragNudgeModifier(active: step == 7 && !reduceMotion))
            .overlay {
                if step == 8 {
                    resizeHandles(width: cardWidth, height: 108)
                }
            }
            .overlay {
                if step >= 6, step <= 8 {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(palette.accent.opacity(0.85), lineWidth: 2.5)
                }
            }
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
            Spacer()
        }
        .padding(.top, 58)
    }

    private func resizeHandles(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .center) {
            Capsule()
                .fill(Color.blue.opacity(0.95))
                .frame(width: 40, height: 5)
                .offset(y: -height / 2)
                .scaleEffect(resizePulse && !reduceMotion ? 1.06 : 1)
            Capsule()
                .fill(Color.blue.opacity(0.95))
                .frame(width: 40, height: 5)
                .offset(y: height / 2)
                .scaleEffect(resizePulse && !reduceMotion ? 1.06 : 1)
            Capsule()
                .fill(Color.blue.opacity(0.95))
                .frame(width: 5, height: 34)
                .offset(x: -width / 2)
                .scaleEffect(resizePulse && !reduceMotion ? 1.06 : 1)
            Capsule()
                .fill(Color.blue.opacity(0.95))
                .frame(width: 5, height: 34)
                .offset(x: width / 2)
                .scaleEffect(resizePulse && !reduceMotion ? 1.06 : 1)
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
    }

    private func runPulseLoops() {
        pulse = false
        galleryNudge = false
        resizePulse = false
        guard !reduceMotion else { return }
        if step == 2 {
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) { pulse = true }
        }
        if step == 5 {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { galleryNudge = true }
        }
        if step == 8 {
            withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) { resizePulse = true }
        }
    }
}

private struct WidgetDragNudgeModifier: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        if active {
            TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                content.offset(x: sin(t * 2.4) * 14, y: cos(t * 2.1) * 6)
            }
        } else {
            content
        }
    }
}

private struct HomeJiggleModifier: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        if active {
            TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                content.rotationEffect(.degrees(sin(t * 6) * 2.6))
            }
        } else {
            content
        }
    }
}

// MARK: - Lock Screen “video” scenes

private struct LockScreenGuideDemo: View {
    let step: Int
    let palette: AppThemePalette
    let reduceMotion: Bool

    @State private var slotGlow = false
    @State private var customizePulse = false

    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                Text(Date(), format: .dateTime.hour().minute())
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                Text(Date(), format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.65))
            }
            .padding(.top, 64)

            if step == 0 {
                LongPressHint(reduceMotion: reduceMotion, handTint: .white, ringTint: .white)
            }

            VStack {
                Spacer()
                if step >= 1 {
                    customizePill
                        .padding(.bottom, 44)
                }
            }

            if step >= 2 {
                accessorySlotOutline
                    .padding(.top, 138)
            }

            if step >= 3 {
                lockWidgetStrip(step: step, reduceMotion: reduceMotion)
                    .opacity(step >= 5 ? 0.22 : 1)
                    .padding(.top, 200)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if step >= 5 {
                placedAccessoryRow(step: step, reduceMotion: reduceMotion)
                    .padding(.top, 198)
            }
        }
        .onAppear { runGlowLoops() }
        .onChange(of: step) { _, _ in
            runGlowLoops()
        }
    }

    private var customizePill: some View {
        Text("Customize")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(customizePulse && !reduceMotion ? 0.3 : 0.18))
            )
            .overlay(Capsule().stroke(Color.white.opacity(0.45), lineWidth: 1))
    }

    private var accessorySlotOutline: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(palette.accent.opacity(slotGlow && !reduceMotion ? 0.95 : 0.5), lineWidth: slotGlow && !reduceMotion ? 3 : 2)
            .frame(height: 58)
            .padding(.horizontal, 36)
    }

    private func lockWidgetStrip(step: Int, reduceMotion: Bool) -> some View {
        let strip = HStack(spacing: 0) {
            HStack(spacing: 10) {
                stripOrb(system: "flashlight.off.fill")
                stripOrb(system: "camera.fill")
                stripBibleLifeChip(highlight: step >= 4)
                stripOrb(system: "moon.fill")
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
        )
        .padding(.horizontal, 20)

        return Group {
            if (step == 3 || step == 4), !reduceMotion {
                TimelineView(.animation(minimumInterval: 1 / 24, paused: false)) { ctx in
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    strip.offset(x: sin(t * 1.85) * -26)
                }
            } else {
                strip
            }
        }
    }

    private func stripOrb(system: String) -> some View {
        Circle()
            .fill(Color.white.opacity(0.12))
            .frame(width: 44, height: 44)
            .overlay { Image(systemName: system).foregroundStyle(.white.opacity(0.85)) }
    }

    private func stripBibleLifeChip(highlight: Bool) -> some View {
        HStack(spacing: 6) {
            BibleLifeAppIcon(palette: palette, size: 32)
            Text("Bible Life")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(highlight ? palette.accent.opacity(0.45) : Color.white.opacity(0.14))
        )
        .overlay(
            Capsule()
                .stroke(highlight ? Color.white.opacity(0.55) : Color.clear, lineWidth: 1.5)
        )
    }

    private func placedAccessoryRow(step: Int, reduceMotion: Bool) -> some View {
        HStack(spacing: 12) {
            stripOrb(system: "flashlight.off.fill")
            Group {
                if step == 6, !reduceMotion {
                    TimelineView(.animation(minimumInterval: 1 / 24, paused: false)) { ctx in
                        let t = ctx.date.timeIntervalSinceReferenceDate
                        GuideLockBadgeAccessory(palette: palette)
                            .offset(x: sin(t * 2.2) * 12)
                    }
                } else {
                    GuideLockBadgeAccessory(palette: palette)
                }
            }
            stripOrb(system: "camera.fill")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.35))
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
        )
        .padding(.horizontal, 28)
    }

    private func runGlowLoops() {
        slotGlow = false
        customizePulse = false
        guard !reduceMotion else { return }
        if step == 1 {
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) { customizePulse = true }
        }
        if step >= 2 {
            withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true)) { slotGlow = true }
        }
    }
}

// MARK: - Shared hints

private struct LongPressHint: View {
    let reduceMotion: Bool
    let handTint: Color
    let ringTint: Color
    @State private var ring = false

    var body: some View {
        ZStack {
            ForEach(0 ..< 3, id: \.self) { i in
                Circle()
                    .stroke(ringTint.opacity(0.42 - Double(i) * 0.12), lineWidth: 2)
                    .frame(width: 52 + CGFloat(i) * 34, height: 52 + CGFloat(i) * 34)
                    .scaleEffect(ring && !reduceMotion ? 1.16 : 0.86)
                    .opacity(ring && !reduceMotion ? 0 : 0.82)
            }
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: 40))
                .foregroundStyle(handTint)
                .symbolRenderingMode(.hierarchical)
                .offset(x: 16, y: 26)
                .modifier(BobModifier(active: !reduceMotion))
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) { ring = true }
        }
    }
}

private struct BobModifier: ViewModifier {
    let active: Bool
    @State private var up = false

    func body(content: Content) -> some View {
        content
            .offset(y: up && active ? -5 : 3)
            .onAppear {
                guard active else { return }
                withAnimation(.easeInOut(duration: 0.82).repeatForever(autoreverses: true)) { up = true }
            }
    }
}
