import SwiftUI

struct HomeBackgroundPickerSheet: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscription: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    private let sheetBackground = Color(red: 0.99, green: 0.97, blue: 0.93)
    private let titleBrown = Color(red: 0.22, green: 0.16, blue: 0.12)
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(titleBrown.opacity(0.75))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.65)))
                        .buttonLabelHitCircle()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)

            Text("Home background")
                .font(.system(.title2, design: .serif, weight: .bold))
                .foregroundStyle(titleBrown)
                .padding(.top, 14)
                .padding(.bottom, 6)

            Text("Choose a solid, gradient, or photo background for your home screen.")
                .font(.footnote)
                .foregroundStyle(titleBrown.opacity(0.72))
                .padding(.bottom, 18)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    pickerSection(title: "Solids", wallpapers: colorWallpapers)
                    pickerSection(title: "Gradients", wallpapers: gradientWallpapers)
                    pickerSection(title: "Photos", wallpapers: photoWallpapers)
                }
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(sheetBackground.ignoresSafeArea())
    }

    // MARK: - Wallpaper categories

    private var colorWallpapers: [HomeWallpaper] {
        [.w1, .w2, .w3, .w4, .w5, .w6, .w7, .w8, .w9, .w10]
    }

    private var gradientWallpapers: [HomeWallpaper] {
        [.g1, .g2, .g3, .g4, .g5, .g6]
    }

    private var photoWallpapers: [HomeWallpaper] {
        [.p1, .p2, .p3, .p4, .p5, .p6, .p7, .p8, .p9]
    }

    // MARK: - Section

    private func pickerSection(title: String, wallpapers: [HomeWallpaper]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(titleBrown.opacity(0.55))
                .textCase(.uppercase)
                .tracking(0.6)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(wallpapers, id: \.self) { wallpaper in
                    wallpaperCell(wallpaper)
                }
            }
        }
    }

    // MARK: - Cell

    private func wallpaperCell(_ wallpaper: HomeWallpaper) -> some View {
        let selected = wallpaper == appState.homeWallpaper

        return Button {
            if wallpaper.isPremiumOnly, !subscription.isPremium {
                subscription.presentPaywall()
                return
            }
            Task { @MainActor in
                appState.setHomeWallpaper(wallpaper)
                try? await Task.sleep(for: .milliseconds(120))
                dismiss()
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomLeading) {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Group {
                                if let assetName = wallpaper.imageAssetName {
                                    Image(assetName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else if let gradient = wallpaper.homeLinearGradient {
                                    gradient
                                } else {
                                    wallpaper.solidBackgroundColor
                                }
                            }
                        }
                        .clipped()

                    if wallpaper.isPremiumOnly, !subscription.isPremium {
                        Color.black.opacity(0.38)
                        Image(systemName: "lock.fill")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    Text("Aa")
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundStyle(
                            wallpaper.isImageWallpaper
                                ? .white
                                : Color(red: 0.12, green: 0.12, blue: 0.12)
                        )
                        .shadow(
                            color: wallpaper.isImageWallpaper ? .black.opacity(0.5) : .clear,
                            radius: wallpaper.isImageWallpaper ? 3 : 0,
                            x: 0,
                            y: 1
                        )
                        .padding(12)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.black.opacity(selected ? 0.28 : 0.08), lineWidth: selected ? 2.5 : 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 2)

                Text(wallpaper.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(titleBrown.opacity(0.88))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .buttonLabelHitRect()
        }
        .buttonStyle(.plain)
    }
}
