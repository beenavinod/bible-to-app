import Foundation

enum WEBBibleIndexError: LocalizedError {
    case missingBundleFile
    case decodeFailed

    var errorDescription: String? {
        switch self {
        case .missingBundleFile:
            "The Bible text file is missing from the app bundle. Run Scripts/build_web_bible.py and rebuild."
        case .decodeFailed:
            "Could not read the Bible data file."
        }
    }
}

/// Loads Protestant WEB text from `web_bible.json` once and serves chapter lookups.
actor WEBBibleIndex {
    static let shared = WEBBibleIndex()

    private var keyToVerses: [String: [WEBBibleVerseRecord]] = [:]
    private var tableOfContents: [BibleBookTOC] = []
    private var copyrightLine: String = ""
    private var didLoad = false

    func load() throws {
        guard !didLoad else { return }
        guard let url = Bundle.main.url(forResource: "web_bible", withExtension: "json") else {
            throw WEBBibleIndexError.missingBundleFile
        }
        let data = try Data(contentsOf: url)
        let payload: WEBBiblePayload
        do {
            payload = try JSONDecoder().decode(WEBBiblePayload.self, from: data)
        } catch {
            throw WEBBibleIndexError.decodeFailed
        }
        copyrightLine = payload.copyright

        var map: [String: [WEBBibleVerseRecord]] = [:]
        map.reserveCapacity(payload.chapters.count)
        for row in payload.chapters {
            let key = Self.chapterKey(book: row.book, chapter: row.chapter)
            map[key] = WEBBibleVerseRecord.mergedUniqueVerses(row.verses)
        }

        var books: [String] = []
        var counts: [String: Int] = [:]
        for row in payload.chapters {
            counts[row.book, default: 0] = max(counts[row.book, default: 0], row.chapter)
            if books.last != row.book {
                books.append(row.book)
            }
        }
        let toc = books.map { BibleBookTOC(name: $0, chapterCount: counts[$0] ?? 0) }

        keyToVerses = map
        tableOfContents = toc
        didLoad = true
    }

    func books() -> [BibleBookTOC] {
        tableOfContents
    }

    func verses(book: String, chapter: Int) -> [WEBBibleVerseRecord]? {
        keyToVerses[Self.chapterKey(book: book, chapter: chapter)]
    }

    func copyright() -> String {
        copyrightLine
    }

    private static func chapterKey(book: String, chapter: Int) -> String {
        "\(book)|\(chapter)"
    }
}
