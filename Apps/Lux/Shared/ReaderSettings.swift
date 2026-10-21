import Foundation
import LuxCore
import LuxDesignSystem
import SwiftUI

/// Per-device reading preferences.
enum ReaderSettingKey {
    static let orthography = "reader.orthography"
    static let showRubrics = "reader.showRubrics"
    static let showProvenance = "reader.showProvenance"
    static let showVerseNumbers = "reader.showVerseNumbers"
    static let typeface = "reader.typeface"
    static let scale = "reader.scale"
    static let leading = "reader.leading"
    /// Who leads the office (`Officiant`).
    static let officiant = "service.officiant"
    /// The tradition's service options, as a JSON object of option id to choice id.
    static let serviceChoices = "service.choices"
}

extension Orthography {
    var label: String {
        switch self {
        case .asPrinted: "As printed (ſ)"
        case .modernLetterforms: "Modern letterforms (s)"
        }
    }
}

extension Officiant {
    var label: String {
        switch self {
        case .priest: "Priest"
        case .deacon: "Deacon"
        case .layPerson: "Lay reader or private prayer"
        }
    }
}

/// The choices stored for a tradition's service options. Options without a
/// stored choice take the option's default.
struct ServiceChoices {
    var stored: [String: String]

    init(json: String) {
        stored = (try? JSONDecoder().decode([String: String].self, from: Data(json.utf8))) ?? [:]
    }

    var json: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return (try? encoder.encode(stored)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    }

    func choice(for option: ServiceOption) -> String {
        stored[option.id].flatMap { id in option.choices.contains { $0.id == id } ? id : nil } ?? option.defaultChoice
    }

    /// Every option's choice, for composition.
    func resolved(_ options: [ServiceOption]) -> [String: String] {
        Dictionary(uniqueKeysWithValues: options.map { ($0.id, choice(for: $0)) })
    }
}

private struct ReadingStyleKey: EnvironmentKey {
    static let defaultValue = ReadingStyle.standard
}

extension EnvironmentValues {
    /// The reader's typographic preferences, set at the root of the app.
    var readingStyle: ReadingStyle {
        get { self[ReadingStyleKey.self] }
        set { self[ReadingStyleKey.self] = newValue }
    }
}

/// Puts the stored reading style into the environment.
struct ReadingStyleProvider: ViewModifier {
    @AppStorage(ReaderSettingKey.typeface) private var typeface: ReadingTypeface = .systemSerif
    @AppStorage(ReaderSettingKey.scale) private var scale = 1.0
    @AppStorage(ReaderSettingKey.leading) private var leading = 1.0

    func body(content: Content) -> some View {
        content.environment(\.readingStyle, ReadingStyle(typeface: typeface, scale: scale, leading: leading))
    }
}

extension View {
    func readingStyleFromSettings() -> some View { modifier(ReadingStyleProvider()) }
}
