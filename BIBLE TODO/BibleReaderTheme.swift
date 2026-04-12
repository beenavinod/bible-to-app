import SwiftUI

/// Reader-only appearance (independent of `AppTheme`).
enum BibleReaderTheme: String, CaseIterable, Codable {
    case cream
    case paper
    case mist
    case midnight

    var displayTitle: String {
        switch self {
        case .cream: "Cream"
        case .paper: "White"
        case .mist: "Light gray"
        case .midnight: "Black"
        }
    }

    var palette: BibleReaderPalette {
        switch self {
        case .cream:
            BibleReaderPalette(
                canvas: Color(red: 0.96, green: 0.94, blue: 0.89),
                verseNumber: Color(red: 0.62, green: 0.58, blue: 0.52),
                body: Color(red: 0.32, green: 0.22, blue: 0.16),
                chromeFill: Color.white.opacity(0.95),
                chromeGlyph: Color(red: 0.32, green: 0.22, blue: 0.16),
                bottomPillStroke: Color(red: 0.82, green: 0.78, blue: 0.72),
                accent: Color(red: 0.45, green: 0.32, blue: 0.22),
                sheetBackground: Color(red: 0.97, green: 0.94, blue: 0.88),
                sheetSecondaryText: Color(red: 0.42, green: 0.38, blue: 0.34)
            )
        case .paper:
            BibleReaderPalette(
                canvas: Color.white,
                verseNumber: Color(red: 0.58, green: 0.56, blue: 0.52),
                body: Color(red: 0.28, green: 0.20, blue: 0.15),
                chromeFill: Color.white.opacity(0.96),
                chromeGlyph: Color(red: 0.28, green: 0.20, blue: 0.15),
                bottomPillStroke: Color(red: 0.86, green: 0.84, blue: 0.80),
                accent: Color(red: 0.45, green: 0.32, blue: 0.22),
                sheetBackground: Color(red: 0.98, green: 0.97, blue: 0.95),
                sheetSecondaryText: Color(red: 0.42, green: 0.38, blue: 0.34)
            )
        case .mist:
            BibleReaderPalette(
                canvas: Color(red: 0.91, green: 0.91, blue: 0.90),
                verseNumber: Color(red: 0.55, green: 0.54, blue: 0.50),
                body: Color(red: 0.30, green: 0.22, blue: 0.17),
                chromeFill: Color.white.opacity(0.94),
                chromeGlyph: Color(red: 0.30, green: 0.22, blue: 0.17),
                bottomPillStroke: Color(red: 0.78, green: 0.77, blue: 0.74),
                accent: Color(red: 0.45, green: 0.32, blue: 0.22),
                sheetBackground: Color(red: 0.96, green: 0.95, blue: 0.92),
                sheetSecondaryText: Color(red: 0.42, green: 0.38, blue: 0.34)
            )
        case .midnight:
            BibleReaderPalette(
                canvas: Color(red: 0.09, green: 0.09, blue: 0.10),
                verseNumber: Color(red: 0.55, green: 0.54, blue: 0.58),
                body: Color(red: 0.94, green: 0.93, blue: 0.90),
                chromeFill: Color(red: 0.16, green: 0.16, blue: 0.18),
                chromeGlyph: Color(red: 0.94, green: 0.93, blue: 0.90),
                bottomPillStroke: Color(red: 0.32, green: 0.32, blue: 0.34),
                accent: Color(red: 0.72, green: 0.58, blue: 0.45),
                sheetBackground: Color(red: 0.97, green: 0.94, blue: 0.88),
                sheetSecondaryText: Color(red: 0.42, green: 0.38, blue: 0.34)
            )
        }
    }
}

struct BibleReaderPalette: Equatable {
    let canvas: Color
    let verseNumber: Color
    let body: Color
    let chromeFill: Color
    let chromeGlyph: Color
    let bottomPillStroke: Color
    let accent: Color
    let sheetBackground: Color
    let sheetSecondaryText: Color
}
