import LuxCore
import LuxDesignSystem
import SwiftUI

/// Renders one element of a composed service.
struct ServiceElementView: View {
    let element: ServiceElement
    @AppStorage(ReaderSettingKey.orthography) private var orthography: Orthography = .modernLetterforms
    @AppStorage(ReaderSettingKey.showRubrics) private var showRubrics = true
    @AppStorage(ReaderSettingKey.showProvenance) private var showProvenance = false
    @AppStorage(ReaderSettingKey.showVerseNumbers) private var showVerseNumbers = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.readingStyle) private var style
    @Environment(\.dynamicTypeSize) private var dynamicType
    @State private var selectedOption = 0

    private var colors: LuxColors { LuxColors(scheme) }
    private func render(_ text: String) -> String { orthography.render(text) }
    private func typeFont(_ role: TypeRole) -> Font { style.font(role, dynamicType: dynamicType) }
    private func typeLeading(_ role: TypeRole) -> Double { style.lineSpacing(role, dynamicType: dynamicType) }

    var body: some View {
        switch element {
        case let .rubric(_, text, source):
            if showRubrics {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(render(text))
                        .font(typeFont(.rubric))
                        .foregroundStyle(colors.rubric)
                        .lineSpacing(typeLeading(.rubric))
                    provenance(source)
                }
                .accessibilityLabel("Rubric. \(render(text))")
            }

        case let .heading(_, text, latin, reference, source):
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(render(text))
                    .font(typeFont(.heading))
                    .foregroundStyle(source == nil ? colors.textSecondary : colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                if let reference, !text.contains(reference) {
                    Text(reference).font(typeFont(.caption)).foregroundStyle(colors.textSecondary)
                }
                if let latin, !text.contains(latin) {
                    Text(render(latin)).font(typeFont(.caption).italic()).foregroundStyle(colors.textSecondary)
                }
            }
            .padding(.top, Spacing.s)

        case let .text(_, kind, speaker, text, citation, source):
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if let speaker, kind != "collect" {
                    SpeakerLabel(speaker: speaker)
                }
                Text(render(text))
                    .font(typeFont(.body))
                    .foregroundStyle(colors.textPrimary)
                    .lineSpacing(typeLeading(.body))
                    .selectableText()
                if let citation {
                    Text(render(citation)).font(typeFont(.caption)).foregroundStyle(colors.textSecondary)
                }
                provenance(source)
            }

        case let .versicles(_, lines, source):
            VStack(alignment: .leading, spacing: Spacing.s) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    VStack(alignment: .leading, spacing: 2) {
                        SpeakerLabel(speaker: line.speaker)
                        Text(render(line.text))
                            .font(line.speaker == .people ? typeFont(.body).bold() : typeFont(.body))
                            .foregroundStyle(colors.textPrimary)
                    }
                }
                provenance(source)
            }

        case let .psalm(_, title, latin, verses, gloria, source):
            VStack(alignment: .leading, spacing: Spacing.s) {
                if let title {
                    Text(title).font(typeFont(.heading)).foregroundStyle(colors.textPrimary).accessibilityAddTraits(.isHeader)
                }
                if let latin {
                    Text(render(latin)).font(typeFont(.caption).italic()).foregroundStyle(colors.textSecondary)
                }
                ForEach(Array(verses.enumerated()), id: \.offset) { _, verse in
                    VerseView(verse: verse, render: render)
                }
                if !gloria.isEmpty {
                    Divider().overlay(colors.divider).padding(.vertical, Spacing.xs)
                    ForEach(Array(gloria.enumerated()), id: \.offset) { _, verse in
                        VerseView(verse: verse, render: render)
                    }
                }
                provenance(source)
            }

        case let .alternatives(_, label, options):
            VStack(alignment: .leading, spacing: Spacing.m) {
                Picker(label, selection: $selectedOption) {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                        Text(render(option.label)).tag(index)
                    }
                }
                .optionPickerStyle()
                ForEach(options[min(selectedOption, options.count - 1)].elements, id: \.id) { child in
                    // Type-erased: the view contains itself.
                    AnyView(ServiceElementView(element: child))
                }
            }

        case let .lesson(_, printed, references, source):
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(references.map(\.description).joined(separator: "; "))
                    .font(typeFont(.heading))
                    .foregroundStyle(colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text("As printed: \(render(printed))")
                    .font(typeFont(.caption))
                    .foregroundStyle(colors.textSecondary)
                provenance(source)
            }
            .padding(.top, Spacing.s)

        case let .reading(_, passage):
            VStack(alignment: .leading, spacing: Spacing.s) {
                ReadingView(passage: passage, showVerseNumbers: showVerseNumbers)
                provenance(passage.source)
            }

        case let .placeholder(_, _, label, reason):
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label(label, systemImage: "book.closed").font(typeFont(.heading))
                Text(reason).font(typeFont(.caption))
            }
            .foregroundStyle(colors.notice)
            .padding(Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(colors.notice.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private func provenance(_ source: SourceReference?) -> some View {
        if showProvenance, let source {
            Text(provenanceText(source))
                .font(typeFont(.caption).monospacedDigit())
                .foregroundStyle(colors.textSecondary)
        }
    }

    private func provenanceText(_ source: SourceReference) -> String {
        var parts = [source.sourceID,
                     "lines \(source.rawLines.lowerBound)–\(source.rawLines.upperBound)",
                     "page \(source.pages.map(String.init).joined(separator: ", "))"]
        if let review = source.review { parts.append("review: \(review)") }
        return parts.joined(separator: " · ")
    }
}

/// The text of a lesson. Prose is set in paragraphs, as the edition marks
/// them (¶) and at each new chapter; the poetical books are set in verse, one
/// line to each verse (`ScriptureForm`). Verse numbers are shown only when
/// asked for in settings; the edition's ¶ then stays in the text too.
/// Words the translators supplied are set in italic, as the edition prints them.
private struct ReadingView: View {
    let passage: ScripturePassage
    let showVerseNumbers: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.readingStyle) private var style
    @Environment(\.dynamicTypeSize) private var dynamicType

    var body: some View {
        let colors = LuxColors(scheme)
        let paragraphs = passage.paragraphs
        VStack(alignment: .leading, spacing: Spacing.m) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, paragraph in
                switch passage.form {
                case .prose:
                    paragraph.enumerated().reduce(Text("")) { text, item in
                        let (n, verse) = item
                        return text + (n == 0 ? Text("") : Text(" ")) + self.verseText(verse, first: index == 0 && n == 0, colors: colors)
                    }
                    .lineSpacing(style.lineSpacing(.body, dynamicType: dynamicType))
                    .paragraphText()
                case .verse:
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        ForEach(Array(paragraph.enumerated()), id: \.offset) { n, verse in
                            self.verseText(verse, first: index == 0 && n == 0, colors: colors)
                                .lineSpacing(style.lineSpacing(.verse, dynamicType: dynamicType))
                                .paragraphText()
                        }
                    }
                }
            }
        }
        .font(style.font(passage.form == .verse ? .verse : .body, dynamicType: dynamicType))
        .foregroundStyle(colors.textPrimary)
    }

    /// One verse: its number when asked for, then its words.
    private func verseText(_ verse: ScriptureVerse, first: Bool, colors: LuxColors) -> Text {
        let segments = showVerseNumbers ? verse.segments : verse.segmentsWithoutParagraphMark
        let words = segments.reduce(Text("")) { text, segment in
            text + (segment.supplied ? Text(segment.text).italic() : Text(segment.text))
        }
        guard showVerseNumbers else { return words }
        let label = first || verse.number == 1 ? "\(verse.chapter):\(verse.number)" : "\(verse.number)"
        return Text(label)
            .font(style.font(.caption, dynamicType: dynamicType).monospacedDigit())
            .foregroundStyle(colors.textSecondary)
            .baselineOffset(4)
            + Text("\u{2009}") + words
    }
}

private struct SpeakerLabel: View {
    let speaker: Speaker
    @Environment(\.colorScheme) private var scheme
    @Environment(\.readingStyle) private var style
    @Environment(\.dynamicTypeSize) private var dynamicType
    private func typeFont(_ role: TypeRole) -> Font { style.font(role, dynamicType: dynamicType) }

    var body: some View {
        Text(name.uppercased())
            .font(typeFont(.caption))
            .kerning(1.2)
            .foregroundStyle(LuxColors(scheme).rubric)
    }

    private var name: String {
        switch speaker {
        case .minister: "Minister"
        case .priest: "Priest"
        case .people: "Answer"
        case .all: "All"
        }
    }
}

/// A verse of a psalm or canticle, with its pointing. Verse numbers are shown
/// only when asked for in settings, as in the lessons.
private struct VerseView: View {
    let verse: Verse
    let render: (String) -> String
    @AppStorage(ReaderSettingKey.showVerseNumbers) private var showVerseNumbers = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.readingStyle) private var style
    @Environment(\.dynamicTypeSize) private var dynamicType
    private func typeFont(_ role: TypeRole) -> Font { style.font(role, dynamicType: dynamicType) }
    private func typeLeading(_ role: TypeRole) -> Double { style.lineSpacing(role, dynamicType: dynamicType) }

    var body: some View {
        let colors = LuxColors(scheme)
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            if showVerseNumbers {
                Text(verse.number.map(String.init) ?? "")
                    .font(typeFont(.caption).monospacedDigit())
                    .foregroundStyle(colors.textSecondary)
                    .frame(minWidth: 24, alignment: .trailing)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(render(verse.first) + (verse.second == nil ? "" : " :"))
                if let second = verse.second {
                    Text(render(second)).padding(.leading, Spacing.m)
                }
            }
            .font(typeFont(.verse))
            .foregroundStyle(colors.textPrimary)
            .lineSpacing(typeLeading(.verse))
        }
    }
}

extension View {
    /// Text set as a paragraph: full width, wrapping, selectable.
    fileprivate func paragraphText() -> some View {
        fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .selectableText()
    }

    @ViewBuilder
    fileprivate func selectableText() -> some View {
        #if os(watchOS)
        self
        #else
        textSelection(.enabled)
        #endif
    }

    @ViewBuilder
    fileprivate func optionPickerStyle() -> some View {
        #if os(watchOS)
        pickerStyle(.navigationLink)
        #else
        pickerStyle(.segmented)
        #endif
    }
}
