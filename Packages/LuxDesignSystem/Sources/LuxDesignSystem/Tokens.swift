import Foundation

/// Design tokens for Lux. See Documentation/DESIGN_SYSTEM.md.
///
/// Tokens are plain values so they can be tested, exported and used outside
/// SwiftUI. `SwiftUIBindings.swift` maps them to SwiftUI types.

/// An sRGB colour with alpha, components 0...1.
public struct RGBA: Hashable, Sendable {
    public var red: Double, green: Double, blue: Double, alpha: Double

    public init(_ red: Double, _ green: Double, _ blue: Double, _ alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// From a 24-bit hex value, e.g. `0x9B2D20`.
    public init(hex: UInt32, alpha: Double = 1) {
        self.init(Double((hex >> 16) & 0xFF) / 255, Double((hex >> 8) & 0xFF) / 255, Double(hex & 0xFF) / 255, alpha)
    }

    /// Relative luminance (WCAG 2.x).
    public var luminance: Double {
        func channel(_ c: Double) -> Double { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
    }

    /// WCAG contrast ratio between two opaque colours.
    public func contrast(with other: RGBA) -> Double {
        let (a, b) = (luminance + 0.05, other.luminance + 0.05)
        return max(a, b) / min(a, b)
    }
}

/// A colour for light and dark appearance.
public struct AdaptiveColor: Hashable, Sendable {
    public var light: RGBA
    public var dark: RGBA
    public init(light: RGBA, dark: RGBA) {
        self.light = light
        self.dark = dark
    }
}

/// Semantic colours (see Documentation/DESIGN_SYSTEM.md, Color System): a
/// printed page. Warm surfacePrimary, iron-gall textPrimary, and red for
/// rubrics, as in the printed book.
public enum Palette {
    public static let surfacePrimary = AdaptiveColor(light: RGBA(hex: 0xFAF6EE), dark: RGBA(hex: 0x16140F))
    public static let surfaceSecondary = AdaptiveColor(light: RGBA(hex: 0xFFFDF8), dark: RGBA(hex: 0x211E18))
    public static let textPrimary = AdaptiveColor(light: RGBA(hex: 0x1F1B16), dark: RGBA(hex: 0xEDE6D8))
    public static let textSecondary = AdaptiveColor(light: RGBA(hex: 0x5C5347), dark: RGBA(hex: 0xB4AA99))
    /// Rubrics and drop capitals.
    public static let rubric = AdaptiveColor(light: RGBA(hex: 0x9B2D20), dark: RGBA(hex: 0xE38A78))
    public static let divider = AdaptiveColor(light: RGBA(hex: 0xD9CFBD), dark: RGBA(hex: 0x3A342A))
    /// The application accent for controls and links.
    public static let accent = AdaptiveColor(light: RGBA(hex: 0x6B3A2A), dark: RGBA(hex: 0xD9A48C))
    /// Placeholders for text Lux cannot supply.
    public static let notice = AdaptiveColor(light: RGBA(hex: 0x7A5B00), dark: RGBA(hex: 0xE2C26A))

    /// Liturgical colours are not prescribed by the 1662 book; Lux uses a
    /// season accent only as a quiet marker.
    public static func seasonAccent(_ season: String) -> AdaptiveColor {
        switch season {
        case "advent", "lent", "septuagesima": return AdaptiveColor(light: RGBA(hex: 0x5B3F78), dark: RGBA(hex: 0xB79BD6))
        case "christmas", "easter": return AdaptiveColor(light: RGBA(hex: 0x8A6A1F), dark: RGBA(hex: 0xE0C27A))
        case "whitsun": return rubric
        default: return AdaptiveColor(light: RGBA(hex: 0x3F6B47), dark: RGBA(hex: 0x93C79C))
        }
    }
}

/// Type roles. Sizes are points at the default Dynamic Type size; the
/// SwiftUI bindings scale them with the user's text size setting.
public enum TypeRole: String, CaseIterable, Sendable {
    case title, heading, body, verse, rubric, caption, dropCap

    public var size: Double {
        switch self {
        case .title: 28
        case .heading: 19
        case .body: 19
        case .verse: 19
        case .rubric: 15
        case .caption: 13
        case .dropCap: 54
        }
    }

    public var lineSpacing: Double {
        switch self {
        case .body, .verse: 7
        case .rubric: 4
        default: 2
        }
    }

    public var italic: Bool { self == .rubric }
}

/// Spacing scale, in points.
public enum Spacing {
    public static let hairline = 1.0
    public static let xs = 4.0
    public static let s = 8.0
    public static let m = 16.0
    public static let l = 24.0
    public static let xl = 40.0
    /// Comfortable reading measure, in points (about 66 characters of body text).
    public static let readingMeasure = 620.0
}

/// Typefaces. The reading face is a Baskerville revival under the SIL Open
/// Font License, bundled by the app; until the font is bundled, the system
/// serif is used. The reference PDF's fonts are never assumed redistributable.
public enum Typeface {
    public static let readingFamily = "Libre Baskerville"
    public static let fallback = "system-serif"
    /// Set when the app bundle carries the reading face. Lux does not bundle
    /// it yet: the font's licence is recorded in LICENSES.md once chosen.
    public static let isReadingFaceBundled = false
}
