import Foundation

/// Root document in `web_bible.json` (built by `Scripts/build_web_bible.py`).
struct WEBBiblePayload: Decodable {
    let translationId: String
    let translationName: String
    let copyright: String
    let chapters: [WEBBibleChapterRecord]

    private enum CodingKeys: String, CodingKey {
        case translationId, translationName, copyright, chapters
    }

    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        translationId = try c.decode(String.self, forKey: .translationId)
        translationName = try c.decode(String.self, forKey: .translationName)
        copyright = try c.decode(String.self, forKey: .copyright)
        chapters = try c.decode([WEBBibleChapterRecord].self, forKey: .chapters)
    }
}

struct WEBBibleChapterRecord: Decodable {
    let book: String
    let chapter: Int
    let verses: [WEBBibleVerseRecord]

    private enum CodingKeys: String, CodingKey {
        case book, chapter, verses
    }

    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        book = try c.decode(String.self, forKey: .book)
        chapter = try c.decode(Int.self, forKey: .chapter)
        verses = try c.decode([WEBBibleVerseRecord].self, forKey: .verses)
    }
}

struct WEBBibleVerseRecord: Decodable, Hashable {
    let n: Int
    let t: String

    private enum CodingKeys: String, CodingKey {
        case n, t
    }

    init(n: Int, t: String) {
        self.n = n
        self.t = t
    }

    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        n = try c.decode(Int.self, forKey: .n)
        t = try c.decode(String.self, forKey: .t)
    }

    /// The bundled WEB source repeats the same verse number for poetic line breaks; merge into one row per verse.
    static func mergedUniqueVerses(_ verses: [WEBBibleVerseRecord]) -> [WEBBibleVerseRecord] {
        guard !verses.isEmpty else { return [] }
        var order: [Int] = []
        var merged: [Int: String] = [:]
        for v in verses {
            if let existing = merged[v.n] {
                merged[v.n] = existing + " " + v.t
            } else {
                order.append(v.n)
                merged[v.n] = v.t
            }
        }
        return order.map { WEBBibleVerseRecord(n: $0, t: merged[$0] ?? "") }
    }
}

struct BibleBookTOC: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let chapterCount: Int
}
