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

/// Full-bleed wallpapers for the Home tab only (`Assets.xcassets` `HomeWallpaper01` … `09`).
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

    static let defaultWallpaper = HomeWallpaper.w1

    var assetName: String {
        switch self {
        case .w1: "HomeWallpaper01"
        case .w2: "HomeWallpaper02"
        case .w3: "HomeWallpaper03"
        case .w4: "HomeWallpaper04"
        case .w5: "HomeWallpaper05"
        case .w6: "HomeWallpaper06"
        case .w7: "HomeWallpaper07"
        case .w8: "HomeWallpaper08"
        case .w9: "HomeWallpaper09"
        }
    }

    /// Text / chrome on the Home screen (independent of `AppTheme` palette).
    var homeForeground: HomeForegroundStyle {
        switch self {
        case .w1, .w2, .w3, .w4, .w6:
            HomeForegroundStyle(
                primary: Color(red: 0.08, green: 0.07, blue: 0.06),
                secondary: Color(red: 0.08, green: 0.07, blue: 0.06).opacity(0.78),
                tertiary: Color(red: 0.08, green: 0.07, blue: 0.06).opacity(0.52),
                glassStroke: Color.black.opacity(0.12),
                legibilityShadow: Color.white.opacity(0.9),
                iconBackdrop: Color.white.opacity(0.58),
                taskCardFill: Color.white.opacity(0.82),
                taskHoldTrackFill: Color.black.opacity(0.07),
                taskCardShadow: Color.black.opacity(0.18),
                prefersLightStatusBar: false
            )
        case .w5, .w7, .w8, .w9:
            HomeForegroundStyle(
                primary: .white,
                secondary: Color.white.opacity(0.88),
                tertiary: Color.white.opacity(0.62),
                glassStroke: Color.white.opacity(0.4),
                legibilityShadow: Color.black.opacity(0.65),
                iconBackdrop: Color.white.opacity(0.22),
                taskCardFill: Color.white.opacity(0.16),
                taskHoldTrackFill: Color.white.opacity(0.22),
                taskCardShadow: Color.black.opacity(0.45),
                prefersLightStatusBar: true
            )
        }
    }
}

struct HomeForegroundStyle {
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let glassStroke: Color
    /// Halo behind glyphs on top of photography (improves contrast without a text box).
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
