import Combine
import Foundation
import SwiftUI

@MainActor
final class BibleReaderViewModel: ObservableObject {
    @Published private(set) var verses: [WEBBibleVerseRecord] = []
    @Published private(set) var booksTOC: [BibleBookTOC] = []
    @Published private(set) var loadError: String?
    @Published private(set) var copyright: String = ""
    /// Bumps when chapter text finishes loading so the reader can scroll to the start of the passage.
    @Published private(set) var readerContentRevision: Int = 0

    @Published var book: String
    @Published var chapter: Int

    @Published var readerTheme: BibleReaderTheme {
        didSet { persistence.setBibleReaderTheme(readerTheme) }
    }

    @Published var fontScale: Double {
        didSet { scheduleReaderAppearancePersistence() }
    }

    @Published var lineSpacingExtra: Double {
        didSet { scheduleReaderAppearancePersistence() }
    }

    private let persistence: AppPersistence
    private var appearancePersistTask: Task<Void, Never>?

    init(persistence: AppPersistence, book: String, chapter: Int) {
        self.persistence = persistence
        self.book = book
        self.chapter = chapter
        readerTheme = persistence.bibleReaderTheme()
        fontScale = persistence.bibleReaderFontScale()
        lineSpacingExtra = persistence.bibleReaderLineSpacingExtra()
    }

    func loadIndexAndChapter() async {
        loadError = nil
        do {
            try await WEBBibleIndex.shared.load()
            booksTOC = await WEBBibleIndex.shared.books()
            copyright = await WEBBibleIndex.shared.copyright()
            await applyCurrentChapter()
        } catch {
            loadError = error.localizedDescription
            verses = []
            booksTOC = []
        }
    }

    func applyCurrentChapter() async {
        if let v = await WEBBibleIndex.shared.verses(book: book, chapter: chapter) {
            verses = v
            loadError = nil
            readerContentRevision += 1
        } else {
            verses = []
            loadError = "This chapter could not be loaded."
            readerContentRevision += 1
        }
    }

    func selectChapter(book: String, chapter: Int) {
        self.book = book
        self.chapter = chapter
        Task { await applyCurrentChapter() }
    }

    /// Persists font and line spacing after interaction settles (avoids disk I/O every drag frame on device).
    private func scheduleReaderAppearancePersistence() {
        appearancePersistTask?.cancel()
        appearancePersistTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            persistence.setBibleReaderFontScale(fontScale)
            persistence.setBibleReaderLineSpacingExtra(lineSpacingExtra)
        }
    }

    /// Call when the reading options sheet closes so the latest values are saved even if debounce has not fired.
    func flushReaderAppearancePersistence() {
        appearancePersistTask?.cancel()
        appearancePersistTask = nil
        persistence.setBibleReaderFontScale(fontScale)
        persistence.setBibleReaderLineSpacingExtra(lineSpacingExtra)
    }
}
