import Foundation
import SwiftUI

struct ThemeOption: Identifiable, Equatable {
    let id: UUID
    let name: String
    let preview: [ColorToken]
}

struct BackgroundOption: Identifiable, Equatable {
    let id: UUID
    let name: String
    let colors: [ColorToken]
}

enum AppTab: Hashable {
    case home
    case journey
    case settings
}

enum AppTheme: String, CaseIterable, Codable {
    case oliveMist
    case sand
    case twilight

    var displayName: String {
        switch self {
        case .oliveMist: "Olive Mist"
        case .sand: "Soft Sand"
        case .twilight: "Evening Calm"
        }
    }

    /// Accent themes beyond the default `oliveMist` require Premium.
    var isPremiumOnly: Bool {
        switch self {
        case .oliveMist: false
        case .sand, .twilight: true
        }
    }
}

enum AppBackground: String, CaseIterable, Codable {
    case plain
    case dawn
    case meadow

    var displayName: String {
        switch self {
        case .plain: "Plain"
        case .dawn: "Dawn Wash"
        case .meadow: "Meadow Glow"
        }
    }
}

/// Light solid fills and soft vertical gradients for the Home tab.
enum HomeWallpaper: String, CaseIterable, Codable {
    case w1
    case w2
    case w3
    case w4
    case w5
    case w6
    case w7
    case w8
    case w9
    case w10
    case g1
    case g2
    case g3
    case g4
    case g5
    case g6

    static let defaultWallpaper = HomeWallpaper.w1

    var displayName: String {
        switch self {
        case .w1: "Warm cream"
        case .w2: "Lavender mist"
        case .w3: "Mint wash"
        case .w4: "Peach glow"
        case .w5: "Ice blue"
        case .w6: "Pale sage"
        case .w7: "Blush shell"
        case .w8: "Soft butter"
        case .w9: "Sea glass"
        case .w10: "Pearl gray"
        case .g1: "Sky to peach"
        case .g2: "Lilac to cream"
        case .g3: "Mint to butter"
        case .g4: "Rose to shell"
        case .g5: "Periwinkle mist"
        case .g6: "Sage to linen"
        }
    }

    /// Full-bleed solid fill, or the **top** stop of a gradient (for previews / fallbacks).
    var solidBackgroundColor: Color {
        switch self {
        case .w1:
            Color(red: 0.98, green: 0.96, blue: 0.91)
        case .w2:
            Color(red: 0.95, green: 0.94, blue: 0.99)
        case .w3:
            Color(red: 0.92, green: 0.97, blue: 0.94)
        case .w4:
            Color(red: 0.99, green: 0.94, blue: 0.92)
        case .w5:
            Color(red: 0.93, green: 0.97, blue: 1.0)
        case .w6:
            Color(red: 0.93, green: 0.96, blue: 0.90)
        case .w7:
            Color(red: 0.99, green: 0.93, blue: 0.94)
        case .w8:
            Color(red: 0.99, green: 0.97, blue: 0.88)
        case .w9:
            Color(red: 0.90, green: 0.97, blue: 0.97)
        case .w10:
            Color(red: 0.94, green: 0.95, blue: 0.97)
        case .g1:
            Color(red: 0.76, green: 0.82, blue: 0.88)
        case .g2:
            Color(red: 0.90, green: 0.88, blue: 0.97)
        case .g3:
            Color(red: 0.86, green: 0.94, blue: 0.90)
        case .g4:
            Color(red: 0.97, green: 0.86, blue: 0.89)
        case .g5:
            Color(red: 0.84, green: 0.87, blue: 0.98)
        case .g6:
            Color(red: 0.86, green: 0.92, blue: 0.87)
        }
    }

    /// When non-`nil`, use this instead of `solidBackgroundColor` for the full-screen Home backdrop.
    var homeLinearGradient: LinearGradient? {
        switch self {
        case .w1, .w2, .w3, .w4, .w5, .w6, .w7, .w8, .w9, .w10:
            nil
        case .g1:
            LinearGradient(
                colors: [
                    Color(red: 0.76, green: 0.82, blue: 0.88),
                    Color(red: 0.92, green: 0.88, blue: 0.84),
                    Color(red: 0.99, green: 0.90, blue: 0.80),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .g2:
            LinearGradient(
                colors: [
                    Color(red: 0.90, green: 0.88, blue: 0.97),
                    Color(red: 0.97, green: 0.95, blue: 0.99),
                    Color(red: 0.99, green: 0.97, blue: 0.94),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .g3:
            LinearGradient(
                colors: [
                    Color(red: 0.86, green: 0.94, blue: 0.90),
                    Color(red: 0.94, green: 0.97, blue: 0.88),
                    Color(red: 0.99, green: 0.96, blue: 0.88),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .g4:
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.86, blue: 0.89),
                    Color(red: 0.99, green: 0.91, blue: 0.90),
                    Color(red: 0.99, green: 0.94, blue: 0.92),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .g5:
            LinearGradient(
                colors: [
                    Color(red: 0.84, green: 0.87, blue: 0.98),
                    Color(red: 0.91, green: 0.93, blue: 0.99),
                    Color(red: 0.95, green: 0.96, blue: 0.99),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .g6:
            LinearGradient(
                colors: [
                    Color(red: 0.86, green: 0.92, blue: 0.87),
                    Color(red: 0.93, green: 0.95, blue: 0.90),
                    Color(red: 0.97, green: 0.96, blue: 0.91),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    /// Text / chrome on the Home screen (always dark on these light fills).
    var homeForeground: HomeForegroundStyle {
        HomeForegroundStyle(
            primary: Color(red: 0.11, green: 0.11, blue: 0.12),
            secondary: Color(red: 0.11, green: 0.11, blue: 0.12).opacity(0.62),
            tertiary: Color(red: 0.11, green: 0.11, blue: 0.12).opacity(0.42),
            glassStroke: Color.black.opacity(0.1),
            legibilityShadow: Color.white.opacity(0.35),
            iconBackdrop: Color.white.opacity(0.72),
            taskCardFill: Color(red: 0.99, green: 0.98, blue: 0.97),
            taskHoldTrackFill: Color.black.opacity(0.06),
            taskCardShadow: Color.black.opacity(0.12),
            prefersLightStatusBar: false
        )
    }
}

struct HomeForegroundStyle {
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let glassStroke: Color
    /// Subtle halo behind glyphs on busy or tinted fills.
    let legibilityShadow: Color
    /// Squircle fill behind toolbar icons (not `Material`, so it doesn't follow system appearance).
    let iconBackdrop: Color
    /// Task card tint (follows wallpaper contrast group).
    let taskCardFill: Color
    let taskHoldTrackFill: Color
    let taskCardShadow: Color
    let prefersLightStatusBar: Bool
}

enum ColorToken: String, Codable, CaseIterable {
    case canvas
    case card
    case primaryText
    case secondaryText
    case softGreen
    case softGreenDark
    case softGold
    case softGoldDark
    case accentRose
    case accentBlue
    case border
    case shadow
    case white

    var color: Color {
        switch self {
        case .canvas:
            Color(red: 0.93, green: 0.95, blue: 0.91)
        case .card:
            Color(red: 0.99, green: 0.98, blue: 0.97)
        case .primaryText:
            Color(red: 0.24, green: 0.23, blue: 0.20)
        case .secondaryText:
            Color(red: 0.50, green: 0.49, blue: 0.44)
        case .softGreen:
            Color(red: 0.76, green: 0.82, blue: 0.70)
        case .softGreenDark:
            Color(red: 0.60, green: 0.70, blue: 0.55)
        case .softGold:
            Color(red: 0.88, green: 0.82, blue: 0.68)
        case .softGoldDark:
            Color(red: 0.74, green: 0.66, blue: 0.48)
        case .accentRose:
            Color(red: 0.83, green: 0.64, blue: 0.64)
        case .accentBlue:
            Color(red: 0.59, green: 0.69, blue: 0.84)
        case .border:
            Color(red: 0.87, green: 0.84, blue: 0.77)
        case .shadow:
            Color.black.opacity(0.08)
        case .white:
            .white
        }
    }
}

struct AppThemePalette: Equatable {
    let canvas: Color
    let card: Color
    let headerAccent: Color
    let tabInactive: Color
    let primaryText: Color
    let secondaryText: Color
    let border: Color
    let shadow: Color
    let accent: Color
    let accentSecondary: Color
}

extension AppTheme {
    var palette: AppThemePalette {
        switch self {
        case .oliveMist:
            AppThemePalette(
                canvas: ColorToken.canvas.color,
                card: ColorToken.card.color,
                headerAccent: ColorToken.softGreen.color,
                tabInactive: ColorToken.softGold.color,
                primaryText: ColorToken.primaryText.color,
                secondaryText: ColorToken.secondaryText.color,
                border: ColorToken.border.color,
                shadow: ColorToken.shadow.color,
                accent: ColorToken.softGreenDark.color,
                accentSecondary: ColorToken.softGoldDark.color
            )
        case .sand:
            AppThemePalette(
                canvas: Color(red: 0.96, green: 0.93, blue: 0.88),
                card: Color(red: 0.99, green: 0.98, blue: 0.96),
                headerAccent: Color(red: 0.86, green: 0.76, blue: 0.66),
                tabInactive: Color(red: 0.81, green: 0.73, blue: 0.62),
                primaryText: Color(red: 0.26, green: 0.21, blue: 0.19),
                secondaryText: Color(red: 0.49, green: 0.43, blue: 0.38),
                border: Color(red: 0.88, green: 0.80, blue: 0.72),
                shadow: Color.black.opacity(0.07),
                accent: Color(red: 0.72, green: 0.57, blue: 0.44),
                accentSecondary: Color(red: 0.63, green: 0.51, blue: 0.39)
            )
        case .twilight:
            AppThemePalette(
                canvas: Color(red: 0.16, green: 0.18, blue: 0.19),
                card: Color(red: 0.20, green: 0.22, blue: 0.24),
                headerAccent: Color(red: 0.43, green: 0.53, blue: 0.49),
                tabInactive: Color(red: 0.40, green: 0.37, blue: 0.30),
                primaryText: Color(red: 0.95, green: 0.94, blue: 0.90),
                secondaryText: Color(red: 0.76, green: 0.75, blue: 0.70),
                border: Color(red: 0.30, green: 0.32, blue: 0.34),
                shadow: Color.black.opacity(0.28),
                accent: Color(red: 0.67, green: 0.77, blue: 0.65),
                accentSecondary: Color(red: 0.86, green: 0.77, blue: 0.59)
            )
        }
    }
}

extension AppBackground {
    var gradientColors: [Color] {
        switch self {
        case .plain:
            [ColorToken.canvas.color, ColorToken.card.color]
        case .dawn:
            [Color(red: 0.98, green: 0.94, blue: 0.90), Color(red: 0.92, green: 0.95, blue: 0.89)]
        case .meadow:
            [Color(red: 0.90, green: 0.94, blue: 0.87), Color(red: 0.96, green: 0.94, blue: 0.89)]
        }
    }
}

extension ThemeOption {
    static let all: [ThemeOption] = [
        ThemeOption(id: UUID(), name: AppTheme.oliveMist.displayName, preview: [.softGreen, .softGold]),
        ThemeOption(id: UUID(), name: AppTheme.sand.displayName, preview: [.softGold, .accentRose]),
        ThemeOption(id: UUID(), name: AppTheme.twilight.displayName, preview: [.softGreenDark, .accentBlue])
    ]
}

extension BackgroundOption {
    static let all: [BackgroundOption] = [
        BackgroundOption(id: UUID(), name: AppBackground.plain.displayName, colors: [.canvas, .card]),
        BackgroundOption(id: UUID(), name: AppBackground.dawn.displayName, colors: [.softGold, .card]),
        BackgroundOption(id: UUID(), name: AppBackground.meadow.displayName, colors: [.softGreen, .card])
    ]
}

extension HomeWallpaper {
    /// Gradient home wallpapers (`g1`–`g6`) require Premium.
    var isPremiumOnly: Bool { homeLinearGradient != nil }
}

extension AppBackground {
    /// App-wide gradient backgrounds (`dawn`, `meadow`) require Premium; `plain` is free.
    var isPremiumOnly: Bool {
        switch self {
        case .plain: false
        case .dawn, .meadow: true
        }
    }
}
