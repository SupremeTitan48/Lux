import BCP1662
import LuxCore
import LuxDesignSystem
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @AppStorage(ReaderSettingKey.orthography) private var orthography: Orthography = .modernLetterforms
    @AppStorage(ReaderSettingKey.showRubrics) private var showRubrics = true
    @AppStorage(ReaderSettingKey.showProvenance) private var showProvenance = false
    @AppStorage(ReaderSettingKey.showVerseNumbers) private var showVerseNumbers = false
    @AppStorage(ReaderSettingKey.typeface) private var typeface: ReadingTypeface = .systemSerif
    @AppStorage(ReaderSettingKey.scale) private var scale = 1.0
    @AppStorage(ReaderSettingKey.leading) private var leading = 1.0
    @AppStorage(ReaderSettingKey.officiant) private var officiant: Officiant = .priest
    @AppStorage(ReaderSettingKey.serviceChoices) private var choicesJSON = ""

    var body: some View {
        NavigationStack {
            Form {
                officeSection
                ForEach(optionGroups) { group in
                    Section(group.title) {
                        ForEach(group.options) { option(for: $0) }
                    }
                }
                textSection
                Section {
                    Picker("Letterforms", selection: $orthography) {
                        ForEach(Orthography.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    Toggle("Show rubrics", isOn: $showRubrics)
                    Toggle("Show source lines", isOn: $showProvenance)
                } header: {
                    Text("Reading")
                } footer: {
                    Text("Texts are kept as printed in 1762. Letterforms change only how the long s is shown.")
                }
                Section("About") {
                    Text("Lux is open source. The 1662 texts follow the Baskerville printing of 1762.")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
        }
        #if os(macOS)
        .frame(minWidth: 460, idealWidth: 520, minHeight: 560)
        #endif
    }

    // MARK: The office

    private var officeSection: some View {
        Section {
            Picker("Officiant", selection: $officiant) {
                ForEach(Officiant.allCases, id: \.self) { Text($0.label).tag($0) }
            }
            ForEach(model.serviceOptions.filter { !$0.officiants.isEmpty && $0.applies(to: officiant) }) { option(for: $0) }
        } header: {
            Text("The Office")
        } footer: {
            if let summary = model.serviceOptions.first(where: { !$0.officiants.isEmpty && $0.applies(to: officiant) })?.summary {
                Text(summary)
            } else {
                Text("Parts the book reserves to a priest are said only when the officiant is a priest.")
            }
        }
    }

    /// The options for everyone, grouped as the tradition groups them; a
    /// group whose options belong to different offices is split by office.
    private struct OptionGroup: Identifiable {
        var title: String
        var options: [ServiceOption]
        var id: String { title }
    }

    private var optionGroups: [OptionGroup] {
        var groups: [OptionGroup] = []
        for option in model.serviceOptions where option.officiants.isEmpty {
            let splitByOffice = model.serviceOptions.contains { $0.group == option.group && $0.offices != option.offices }
            let title = splitByOffice && option.offices.count == 1
                ? "\(option.group) at \(option.offices[0].displayName)" : option.group
            if let index = groups.firstIndex(where: { $0.title == title }) {
                groups[index].options.append(option)
            } else {
                groups.append(OptionGroup(title: title, options: [option]))
            }
        }
        return groups
    }

    @ViewBuilder
    private func option(for option: ServiceOption) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Picker(option.title, selection: binding(for: option)) {
                ForEach(option.choices) { Text($0.label).tag($0.id) }
            }
            if let summary = option.summary, option.officiants.isEmpty {
                Text(summary).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func binding(for option: ServiceOption) -> Binding<String> {
        Binding {
            ServiceChoices(json: choicesJSON).choice(for: option)
        } set: { choice in
            var choices = ServiceChoices(json: choicesJSON)
            choices.stored[option.id] = choice
            choicesJSON = choices.json
        }
    }

    // MARK: Text

    private var textSection: some View {
        Section {
            Picker("Typeface", selection: $typeface) {
                ForEach(ReadingTypeface.allCases.filter(\.isInstalled), id: \.self) { face in
                    Text(face.displayName).tag(face)
                }
            }
            LabeledContent("Size") {
                HStack {
                    Image(systemName: "textformat.size.smaller").accessibilityHidden(true)
                    Slider(value: $scale, in: ReadingStyle.scaleRange, step: 0.05)
                        .accessibilityValue(Text(scale.formatted(.percent.precision(.fractionLength(0)))))
                    Image(systemName: "textformat.size.larger").accessibilityHidden(true)
                }
            }
            LabeledContent("Line spacing") {
                Slider(value: $leading, in: ReadingStyle.leadingRange, step: 0.25)
                    .accessibilityValue(Text(leading.formatted(.number.precision(.fractionLength(2)))))
            }
            Toggle("Verse numbers", isOn: $showVerseNumbers)
            if let preview {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    ForEach(preview, id: \.id) { ServiceElementView(element: $0) }
                }
                .padding(.vertical, Spacing.s)
                .accessibilityLabel("Preview")
            }
            Button("Restore defaults") {
                typeface = .systemSerif
                scale = 1
                leading = 1
            }
            .disabled(typeface == .systemSerif && scale == 1 && leading == 1)
        } header: {
            Text("Text")
        } footer: {
            Text("Verse numbers are hidden in the psalms, canticles and lessons unless turned on here. The lessons are set in paragraphs; Job, the Psalms, Proverbs, Ecclesiastes, the Song of Solomon, Wisdom and Ecclesiasticus are set in verse. The size adds to the system text size.")
        }
    }

    /// A real text of the book to judge the style by: the first collect of
    /// the year, Advent Sunday's.
    private var preview: [ServiceElement]? {
        guard let tradition = model.tradition, let first = tradition.collectObservances.first else { return nil }
        let collect = tradition.collects(for: first).prefix(1)
        return collect.isEmpty ? nil : Array(collect)
    }
}

extension ReadingTypeface {
    /// Whether this device has the face; system designs always exist.
    var isInstalled: Bool {
        guard let family = familyName else { return true }
        #if canImport(UIKit)
        return UIFont.familyNames.contains(family)
        #elseif canImport(AppKit)
        return NSFontManager.shared.availableFontFamilies.contains(family)
        #else
        return false
        #endif
    }
}
