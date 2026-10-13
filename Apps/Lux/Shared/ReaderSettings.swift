import LuxCore
import SwiftUI

/// Per-device reading preferences.
enum ReaderSettingKey {
    static let orthography = "reader.orthography"
    static let showRubrics = "reader.showRubrics"
    static let showProvenance = "reader.showProvenance"
}

extension Orthography {
    var label: String {
        switch self {
        case .asPrinted: "As printed (ſ)"
        case .modernLetterforms: "Modern letterforms (s)"
        }
    }
}
