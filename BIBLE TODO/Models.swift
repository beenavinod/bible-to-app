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

/// Badge category matching the `type` column in `badge_definitions`.
enum BadgeType: String, Codable, CaseIterable, Sendable {
    case taskStreak = "task-streak"
    case verseShare = "verse-share"
    case firstShare = "first-share"
}

/// Visual prestige tier derived from badge weight.
enum BadgeRarity: String, Codable, CaseIterable {
    case common
    case rare
    case epic
    case legendary

    init(weight: Int) {
        switch weight {
        case ..<28:   self = .common
        case ..<90:   self = .rare
        case ..<185:  self = .epic
        default:      self = .legendary
        }
    }

    var glowColor: Color {
        switch self {
        case .common:    .clear
        case .rare:      .blue.opacity(0.4)
        case .epic:      .purple.opacity(0.5)
        case .legendary: .yellow.opacity(0.8)
        }
    }
}

/// Client-side representation of a row from `badge_definitions`.
/// All fields except `symbolName` come from Supabase; the icon is resolved client-side via `BadgeIcons`.
struct Achievement: Identifiable, Hashable {
    let id: Int
    let slug: String
    let name: String
    let badgeDescription: String
    let type: BadgeType
    let actionsRequired: Int
    let weight: Int
    let isActive: Bool

    /// SF Symbol name resolved from the static `BadgeIcons.forSlug` dictionary.
    var symbolName: String {
        BadgeIcons.forSlug[slug] ?? "star.fill"
    }

    var rarity: BadgeRarity {
        BadgeRarity(weight: weight)
    }

    func isUnlocked(for count: Int) -> Bool {
        count >= actionsRequired
    }

    static func == (lhs: Achievement, rhs: Achievement) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Static slug-to-SF-Symbol mapping and fallback badge catalog.
/// Icons use native iOS SF Symbols — no custom assets required.
enum BadgeIcons {
    static let forSlug: [String: String] = [
        "task_streak_1":   "shoeprints.fill",
        "task_streak_2":   "bolt.fill",
        "task_streak_3":   "flame.fill",
        "task_streak_5":   "leaf.fill",
        "task_streak_7":   "star.fill",
        "task_streak_10":  "tree.fill",
        "task_streak_14":  "safari.fill",
        "task_streak_21":  "hourglass",
        "task_streak_30":  "arrow.up.forward",
        "task_streak_45":  "sun.max.fill",
        "task_streak_60":  "sunrise.fill",
        "task_streak_75":  "burst.fill",
        "task_streak_90":  "brain.head.profile.fill",
        "task_streak_105": "star.circle.fill",
        "task_streak_120": "water.waves",
        "task_streak_150": "arrow.up.circle.fill",
        "task_streak_180": "road.lanes",
        "task_streak_210": "bell.badge.fill",
        "task_streak_300": "crown.fill",
        "task_streak_365": "cross.fill",
        "verse_share_3":   "book.fill",
        "first_share":     "light.max",
    ]

    /// Complete badge catalog used as fallback when Supabase data is unavailable.
    /// IDs use negative values to avoid collisions with database-assigned IDs.
    static let fallbackCatalog: [Achievement] = [
        Achievement(id: -1,  slug: "task_streak_1",   name: "First Step",   badgeDescription: "The journey begins",           type: .taskStreak, actionsRequired: 1,   weight: 1,   isActive: true),
        Achievement(id: -2,  slug: "task_streak_2",   name: "Ignition",     badgeDescription: "You showed up again",          type: .taskStreak, actionsRequired: 2,   weight: 3,   isActive: true),
        Achievement(id: -3,  slug: "task_streak_3",   name: "Spark",        badgeDescription: "Momentum is building",         type: .taskStreak, actionsRequired: 3,   weight: 5,   isActive: true),
        Achievement(id: -4,  slug: "task_streak_5",   name: "Rise",         badgeDescription: "Growth has started",           type: .taskStreak, actionsRequired: 5,   weight: 8,   isActive: true),
        Achievement(id: -5,  slug: "task_streak_7",   name: "Momentum",     badgeDescription: "One week strong",              type: .taskStreak, actionsRequired: 7,   weight: 12,  isActive: true),
        Achievement(id: -6,  slug: "task_streak_10",  name: "Rooted",       badgeDescription: "Stability is forming",         type: .taskStreak, actionsRequired: 10,  weight: 16,  isActive: true),
        Achievement(id: -7,  slug: "task_streak_14",  name: "On Track",     badgeDescription: "You are finding direction",    type: .taskStreak, actionsRequired: 14,  weight: 20,  isActive: true),
        Achievement(id: -8,  slug: "task_streak_21",  name: "Steady",       badgeDescription: "Consistency is real",          type: .taskStreak, actionsRequired: 21,  weight: 28,  isActive: true),
        Achievement(id: -9,  slug: "task_streak_30",  name: "Climbing",     badgeDescription: "A full month achieved",        type: .taskStreak, actionsRequired: 30,  weight: 36,  isActive: true),
        Achievement(id: -10, slug: "task_streak_45",  name: "Aligned",      badgeDescription: "You're in rhythm",             type: .taskStreak, actionsRequired: 45,  weight: 48,  isActive: true),
        Achievement(id: -11, slug: "task_streak_60",  name: "Breakthrough", badgeDescription: "Habit becomes lifestyle",      type: .taskStreak, actionsRequired: 60,  weight: 60,  isActive: true),
        Achievement(id: -12, slug: "task_streak_75",  name: "Unstoppable",  badgeDescription: "You refuse to quit",           type: .taskStreak, actionsRequired: 75,  weight: 75,  isActive: true),
        Achievement(id: -13, slug: "task_streak_90",  name: "Renewed",      badgeDescription: "Transformation is happening",  type: .taskStreak, actionsRequired: 90,  weight: 90,  isActive: true),
        Achievement(id: -14, slug: "task_streak_105", name: "Radiant",      badgeDescription: "Your light is visible",        type: .taskStreak, actionsRequired: 105, weight: 105, isActive: true),
        Achievement(id: -15, slug: "task_streak_120", name: "Deep Rooted",  badgeDescription: "Strong and grounded",          type: .taskStreak, actionsRequired: 120, weight: 120, isActive: true),
        Achievement(id: -16, slug: "task_streak_150", name: "Ascending",    badgeDescription: "Next-level commitment",        type: .taskStreak, actionsRequired: 150, weight: 140, isActive: true),
        Achievement(id: -17, slug: "task_streak_180", name: "Unwavering",   badgeDescription: "Long-term discipline proven",  type: .taskStreak, actionsRequired: 180, weight: 165, isActive: true),
        Achievement(id: -18, slug: "task_streak_210", name: "Devoted",      badgeDescription: "Fully committed path",         type: .taskStreak, actionsRequired: 210, weight: 185, isActive: true),
        Achievement(id: -19, slug: "task_streak_300", name: "Mastery",      badgeDescription: "Elite consistency",            type: .taskStreak, actionsRequired: 300, weight: 240, isActive: true),
        Achievement(id: -20, slug: "task_streak_365", name: "365 Faithful", badgeDescription: "A year of unwavering faith",   type: .taskStreak, actionsRequired: 365, weight: 300, isActive: true),
        Achievement(id: -21, slug: "verse_share_3",   name: "Word Spreader",badgeDescription: "Shared God's word 3 times",    type: .verseShare, actionsRequired: 3,   weight: 15,  isActive: true),
        Achievement(id: -22, slug: "first_share",     name: "First Light",  badgeDescription: "Shared a verse for the first time", type: .firstShare, actionsRequired: 1, weight: 10, isActive: true),
    ]
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
    /// Squircle fill behind toolbar icons (not `Material`, so it doesn’t follow system appearance).
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

