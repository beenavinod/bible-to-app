import Foundation
import SwiftUI

struct Verse: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let title: String
    let text: String
    let reference: String
    let taskTitle: String
    let taskDescription: String
    let taskQuote: String
    let symbolName: String
}

struct DailyRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let verse: Verse
    let completed: Bool
}

struct StreakSummary: Codable, Equatable {
    let currentStreak: Int
    let longestStreak: Int
    let totalCompletedDays: Int
}

struct Achievement: Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let symbolName: String
    let accentColor: ColorToken
    let unlockDays: Int

    func isUnlocked(for streak: Int) -> Bool {
        streak >= unlockDays
    }
}

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

extension Achievement {
    static let defaults: [Achievement] = [
        Achievement(id: UUID(), title: "Cross", subtitle: "3d", symbolName: "cross.case.fill", accentColor: .accentRose, unlockDays: 3),
        Achievement(id: UUID(), title: "Bible", subtitle: "5d", symbolName: "book.closed.fill", accentColor: .accentBlue, unlockDays: 5),
        Achievement(id: UUID(), title: "Holy Spirit", subtitle: "7d", symbolName: "wind", accentColor: .softGoldDark, unlockDays: 7),
        Achievement(id: UUID(), title: "Church", subtitle: "10d", symbolName: "building.columns.fill", accentColor: .softGreenDark, unlockDays: 10)
    ]
}
