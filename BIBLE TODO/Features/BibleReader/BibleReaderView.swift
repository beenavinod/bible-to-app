import SwiftUI

struct BibleReaderView: View {
    let onDismiss: () -> Void
    let appPalette: AppThemePalette

    @StateObject private var model: BibleReaderViewModel

    @State private var showBookPicker = false
    @State private var showReaderOptions = false
    @State private var expandedBookName: String?

    init(
        onDismiss: @escaping () -> Void,
        persistence: AppPersistence,
        appPalette: AppThemePalette,
        startBook: String = "Genesis",
        startChapter: Int = 1
    ) {
        self.onDismiss = onDismiss
        self.appPalette = appPalette
        _model = StateObject(
            wrappedValue: BibleReaderViewModel(persistence: persistence, book: startBook, chapter: startChapter)
        )
    }

    private var palette: BibleReaderPalette {
        model.readerTheme.palette
    }

    private var chapterContentId: String {
        "\(model.book)|\(model.chapter)"
    }

    private var bodyPointSize: CGFloat {
        CGFloat(19 * model.fontScale)
    }

    private var verseNumSize: CGFloat {
        CGFloat(max(11, 12 * model.fontScale))
    }

    var body: some View {
        ZStack(alignment: .top) {
            palette.canvas
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Color.clear
                            .frame(height: 1)
                            .id("bibleScrollTop")

                        if let err = model.loadError {
                            Text(err)
                                .font(.subheadline)
                                .foregroundStyle(palette.body.opacity(0.85))
                                .padding(.horizontal, 24)
                                .padding(.top, 100)
                        } else {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(model.verses, id: \.n) { verse in
                                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                                        Text("\(verse.n)")
                                            .font(.system(size: verseNumSize, weight: .medium, design: .rounded))
                                            .foregroundStyle(palette.verseNumber)
                                            .frame(width: 32, alignment: .trailing)

                                        Text(verse.t)
                                            .font(.system(size: bodyPointSize, weight: .regular, design: .serif))
                                            .foregroundStyle(palette.body)
                                            .lineSpacing(CGFloat(model.lineSpacingExtra))
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.horizontal, 22)
                                    .id("verse-\(verse.n)")
                                }
                            }
                            .padding(.top, 88)
                            .padding(.bottom, 120)
                            .id(chapterContentId)
                        }

                        if !model.copyright.isEmpty, model.loadError == nil {
                            Text(model.copyright)
                                .font(.caption2)
                                .foregroundStyle(palette.verseNumber)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 32)
                        }
                    }
                }
                .id("bibleReaderScroll-\(model.readerContentRevision)")
                .scrollContentBackground(.hidden)
                .background(palette.canvas)
                .transaction { $0.animation = nil }
                .onChange(of: model.readerContentRevision) { _, _ in
                    DispatchQueue.main.async {
                        proxy.scrollTo("bibleScrollTop", anchor: .top)
                        DispatchQueue.main.async {
                            proxy.scrollTo("bibleScrollTop", anchor: .top)
                        }
                    }
                }
            }

            VStack {
                topChrome
                Spacer()
                bottomChapterPill
            }
        }
        .animation(nil, value: model.fontScale)
        .animation(nil, value: model.lineSpacingExtra)
        .task {
            await model.loadIndexAndChapter()
        }
        .sheet(isPresented: $showBookPicker) {
            BibleBookChapterPickerSheet(
                appPalette: appPalette,
                books: model.booksTOC,
                selectedBook: model.book,
                selectedChapter: model.chapter,
                expandedBookName: $expandedBookName,
                onSelect: { book, chapter in
                    model.selectChapter(book: book, chapter: chapter)
                    showBookPicker = false
                },
                onClose: { showBookPicker = false }
            )
            .presentationDragIndicator(.visible)
            .onAppear {
                expandedBookName = model.book
            }
        }
        .sheet(isPresented: $showReaderOptions) {
            BibleReaderOptionsSheet(model: model, appPalette: appPalette)
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.visible)
        }
    }

    private var topChrome: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(palette.chromeGlyph)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(palette.chromeFill))
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                showReaderOptions = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(palette.chromeGlyph)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(palette.chromeFill))
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var bottomChapterPill: some View {
        HStack {
            Button {
                showBookPicker = true
            } label: {
                Text("\(model.book) \(model.chapter)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.body)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        Capsule(style: .continuous)
                            .fill(palette.chromeFill)
                            .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 4)
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(palette.bottomPillStroke, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 28)
    }
}

// MARK: - Book / chapter sheet

private struct BibleBookChapterPickerSheet: View {
    let appPalette: AppThemePalette
    let books: [BibleBookTOC]
    let selectedBook: String
    let selectedChapter: Int
    @Binding var expandedBookName: String?
    let onSelect: (String, Int) -> Void
    let onClose: () -> Void

    private let grid = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)

    var body: some View {
        NavigationStack {
            ZStack {
                appPalette.canvas
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(books) { book in
                            bookRow(book)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(appPalette.card, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(appPalette.primaryText)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(appPalette.card))
                            .overlay(Circle().stroke(appPalette.border.opacity(0.55), lineWidth: 1))
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Books")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(appPalette.primaryText)
                }
            }
        }
    }

    private func bookRow(_ book: BibleBookTOC) -> some View {
        let expanded = expandedBookName == book.name
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                expandedBookName = expanded ? nil : book.name
            } label: {
                HStack {
                    Text(book.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(appPalette.primaryText)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(expanded ? appPalette.card : appPalette.secondaryText)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(expanded ? appPalette.accent : appPalette.card))
                        .overlay(Circle().stroke(appPalette.border.opacity(0.55), lineWidth: expanded ? 0 : 1))
                }
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                LazyVGrid(columns: grid, spacing: 10) {
                    ForEach(1 ... book.chapterCount, id: \.self) { ch in
                        let isOn = selectedBook == book.name && selectedChapter == ch
                        Button {
                            onSelect(book.name, ch)
                        } label: {
                            Text("\(ch)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(appPalette.primaryText)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(appPalette.card.opacity(0.95))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(isOn ? appPalette.accent : appPalette.border.opacity(0.45), lineWidth: isOn ? 2 : 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 16)
            }

            Divider()
                .background(appPalette.border.opacity(0.45))
        }
    }
}

// MARK: - Reading options sheet

private struct BibleReaderOptionsSheet: View {
    @ObservedObject var model: BibleReaderViewModel
    let appPalette: AppThemePalette
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                Text("Reading")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(appPalette.primaryText)
                Spacer()
                Button("Done") { dismiss() }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(appPalette.accent)
            }
            .padding(.top, 4)

            fontSizeRow
            lineSpacingRow
            themeRow
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(appPalette.card)
    }

    private var fontSizeRow: some View {
        HStack(spacing: 14) {
            Text("A")
                .font(.caption.weight(.bold))
                .foregroundStyle(appPalette.accent)
            Slider(value: fontScaleBinding, in: 0.85 ... 1.45)
                .tint(appPalette.accent)
            Text("A")
                .font(.title2.weight(.bold))
                .foregroundStyle(appPalette.accent)
        }
    }

    private var lineSpacingRow: some View {
        HStack(spacing: 14) {
            lineSpacingIcon(compact: true)
            Slider(value: lineSpacingBinding, in: 0 ... 16)
                .tint(appPalette.accent)
            lineSpacingIcon(compact: false)
        }
    }

    private var fontScaleBinding: Binding<Double> {
        Binding(
            get: { model.fontScale },
            set: { newValue in
                var transaction = Transaction()
                transaction.animation = nil
                withTransaction(transaction) {
                    model.fontScale = newValue
                }
            }
        )
    }

    private var lineSpacingBinding: Binding<Double> {
        Binding(
            get: { model.lineSpacingExtra },
            set: { newValue in
                var transaction = Transaction()
                transaction.animation = nil
                withTransaction(transaction) {
                    model.lineSpacingExtra = newValue
                }
            }
        )
    }

    private func lineSpacingIcon(compact: Bool) -> some View {
        VStack(spacing: compact ? 3 : 6) {
            ForEach(0 ..< 3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 1)
                    .fill(appPalette.accent.opacity(0.85))
                    .frame(width: 22, height: 2)
            }
        }
        .frame(width: 28)
    }

    private var themeRow: some View {
        HStack(spacing: 12) {
            ForEach(BibleReaderTheme.allCases, id: \.self) { theme in
                let p = theme.palette
                let on = model.readerTheme == theme
                Button {
                    var transaction = Transaction()
                    transaction.animation = nil
                    withTransaction(transaction) {
                        model.readerTheme = theme
                    }
                } label: {
                    ZStack {
                        Capsule()
                            .fill(p.canvas)
                            .frame(height: 44)
                            .overlay(
                                Capsule()
                                    .stroke(appPalette.border.opacity(theme == .midnight ? 0.35 : 0.55), lineWidth: 1)
                            )
                        if on {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(theme == .midnight ? Color.white : appPalette.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview("Bible reader") {
    BibleReaderView(onDismiss: {}, persistence: PreviewPersistence(), appPalette: AppTheme.oliveMist.palette)
}
