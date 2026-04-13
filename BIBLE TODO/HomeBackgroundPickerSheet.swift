import SwiftUI

struct HomeBackgroundPickerSheet: View {
    @EnvironmentObject private var appState: AppState
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
                .padding(.bottom, 18)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(HomeWallpaper.allCases, id: \.self) { wallpaper in
                        wallpaperCell(wallpaper)
                    }
                }
                .padding(.bottom, 28)
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(sheetBackground.ignoresSafeArea())
    }

    private func wallpaperCell(_ wallpaper: HomeWallpaper) -> some View {
        let selected = wallpaper == appState.homeWallpaper

        return Button {
            Task { @MainActor in
                appState.setHomeWallpaper(wallpaper)
                try? await Task.sleep(for: .milliseconds(120))
                dismiss()
            }
        } label: {
            GeometryReader { geo in
                ZStack {
                    Image(wallpaper.assetName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()

                    Text("Aa")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)

                    VStack {
                        HStack {
                            Spacer()
                            Text("Free")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(titleBrown.opacity(0.85))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.white.opacity(0.82)))
                                .padding(8)
                        }
                        Spacer()
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .aspectRatio(2 / 3, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white, lineWidth: selected ? 3 : 0)
            )
            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}
