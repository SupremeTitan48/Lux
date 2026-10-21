import LuxCore
import LuxDesignSystem
import SwiftUI

/// Renders one element of a composed service.
struct ServiceElementView: View {
    let element: ServiceElement
    @AppStorage(ReaderSettingKey.orthography) private var orthography: Orthography = .modernLetterforms
    @AppStorage(ReaderSettingKey.showRubrics) private var showRubrics = true
    @AppStorage(ReaderSettingKey.showProvenance) private var showProvenance = false
    @Environment(\.colorScheme) private var scheme
    @State private var selectedOption = 0

    private var colors: LuxColors { LuxColors(scheme) }
    private func render(_ text: String) -> String { orthography.render(text) }

    var body: some View {
        switch element {
        case let .rubric(_, text, source):
            if showRubrics {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(render(text))
                        .font(TypeRole.rubric.font)
                        .foregroundStyle(colors.rubric)
                        .lineSpacing(TypeRole.rubric.lineSpacing)
                    provenance(source)
                }
                .accessibilityLabel("Rubric. \(render(text))")
            }

        case let .heading(_, text, latin, reference, source):
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(render(text))
                    .font(TypeRole.heading.font)
                    .foregroundStyle(source == nil ? colors.textSecondary : colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                if let reference, !text.contains(reference) {
                    Text(reference).font(TypeRole.caption.font).foregroundStyle(colors.textSecondary)
                }
                if let latin, !text.contains(latin) {
                    Text(render(latin)).font(TypeRole.caption.font.italic()).foregroundStyle(colors.textSecondary)
                }
            }
            .padding(.top, Spacing.s)

        case let .text(_, kind, speaker, text, citation, source):
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if let speaker, kind != "collect" {
                    SpeakerLabel(speaker: speaker)
                }
                Text(render(text))
                    .font(TypeRole.body.font)
                    .foregroundStyle(colors.textPrimary)
                    .lineSpacing(TypeRole.body.lineSpacing)
                    .selectableText()
                if let citation {
                    Text(render(citation)).font(TypeRole.caption.font).foregroundStyle(colors.textSecondary)
                }
                provenance(source)
            }

        case let .versicles(_, lines, source):
            VStack(alignment: .leading, spacing: Spacing.s) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    VStack(alignment: .leading, spacing: 2) {
                        SpeakerLabel(speaker: line.speaker)
                        Text(render(line.text))
                            .font(line.speaker == .people ? TypeRole.body.font.bold() : TypeRole.body.font)
                            .foregroundStyle(colors.textPrimary)
                    }
                }
                provenance(source)
            }

        case let .psalm(_, title, latin, verses, gloria, source):
            VStack(alignment: .leading, spacing: Spacing.s) {
                if let title {
                    Text(title).font(TypeRole.heading.font).foregroundStyle(colors.textPrimary).accessibilityAddTraits(.isHeader)
                }
                if let latin {
                    Text(render(latin)).font(TypeRole.caption.font.italic()).foregroundStyle(colors.textSecondary)
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
                    .font(TypeRole.heading.font)
                    .foregroundStyle(colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text("As printed: \(render(printed))")
                    .font(TypeRole.caption.font)
                    .foregroundStyle(colors.textSecondary)
                provenance(source)
            }
            .padding(.top, Spacing.s)

        case let .placeholder(_, _, label, reason):
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label(label, systemImage: "book.closed").font(TypeRole.heading.font)
                Text(reason).font(TypeRole.caption.font)
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
                .font(TypeRole.caption.font.monospacedDigit())
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

private struct SpeakerLabel: View {
    let speaker: Speaker
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Text(name.uppercased())
            .font(TypeRole.caption.font)
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

private struct VerseView: View {
    let verse: Verse
    let render: (String) -> String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let colors = LuxColors(scheme)
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            Text(verse.number.map(String.init) ?? "")
                .font(TypeRole.caption.font.monospacedDigit())
                .foregroundStyle(colors.textSecondary)
                .frame(minWidth: 24, alignment: .trailing)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(render(verse.first) + (verse.second == nil ? "" : " :"))
                if let second = verse.second {
                    Text(render(second)).padding(.leading, Spacing.m)
                }
            }
            .font(TypeRole.verse.font)
            .foregroundStyle(colors.textPrimary)
            .lineSpacing(TypeRole.verse.lineSpacing)
        }
    }
}

extension View {
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
