import Foundation
import SwiftUI

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
