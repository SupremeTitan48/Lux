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
/// neutral page that matches the system's own surfaces, near-black text, and
/// red for rubrics, as in the printed book.
public enum Palette {
    public static let surfacePrimary = AdaptiveColor(light: RGBA(hex: 0xFFFFFF), dark: RGBA(hex: 0x1E1E1E))
    public static let surfaceSecondary = AdaptiveColor(light: RGBA(hex: 0xF5F5F5), dark: RGBA(hex: 0x2A2A2A))
    public static let textPrimary = AdaptiveColor(light: RGBA(hex: 0x1C1C1C), dark: RGBA(hex: 0xEBEBEB))
    public static let textSecondary = AdaptiveColor(light: RGBA(hex: 0x5E5E5E), dark: RGBA(hex: 0xADADAD))
    /// Rubrics and drop capitals.
    public static let rubric = AdaptiveColor(light: RGBA(hex: 0x9B2D20), dark: RGBA(hex: 0xE38A78))
    public static let divider = AdaptiveColor(light: RGBA(hex: 0xDADADA), dark: RGBA(hex: 0x3A3A3A))
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

/// The reader's typographic preferences: typeface, size and leading. Plain
/// values, so they can be stored and tested; the SwiftUI bindings turn them
/// into fonts. They apply to the text of the office, not to the interface.
public struct ReadingStyle: Hashable, Sendable, Codable {
    public var typeface: ReadingTypeface
    /// A multiple of the role sizes, applied on top of Dynamic Type.
    public var scale: Double
    /// A multiple of the role line spacing.
    public var leading: Double

    public static let scaleRange: ClosedRange<Double> = 0.8...1.8
    public static let leadingRange: ClosedRange<Double> = 0.5...2.0

    public init(typeface: ReadingTypeface = .systemSerif, scale: Double = 1, leading: Double = 1) {
        self.typeface = typeface
        self.scale = min(max(scale, ReadingStyle.scaleRange.lowerBound), ReadingStyle.scaleRange.upperBound)
        self.leading = min(max(leading, ReadingStyle.leadingRange.lowerBound), ReadingStyle.leadingRange.upperBound)
    }

    public static let standard = ReadingStyle()

    public func size(_ role: TypeRole) -> Double { role.size * scale }
    public func lineSpacing(_ role: TypeRole) -> Double { role.lineSpacing * scale * leading }
}

/// Typefaces for the text of the office. Each is installed with the
/// operating system, so Lux redistributes no font files; a face missing on
/// a platform falls back to the system serif.
public enum ReadingTypeface: String, Hashable, Sendable, Codable, CaseIterable {
    /// New York on Apple platforms.
    case systemSerif = "system-serif"
    case baskerville = "Baskerville"
    case georgia = "Georgia"
    case iowan = "Iowan Old Style"
    case palatino = "Palatino"
    case hoefler = "Hoefler Text"
    /// San Francisco, for readers who prefer a sans serif.
    case systemSans = "system-sans"

    public var displayName: String {
        switch self {
        case .systemSerif: "New York"
        case .systemSans: "San Francisco"
        default: rawValue
        }
    }

    /// The PostScript family name to ask the system for, or nil for a
    /// system design.
    public var familyName: String? {
        switch self {
        case .systemSerif, .systemSans: nil
        default: rawValue
        }
    }
}

/// The skies of the Today cards: dawn for Morning Prayer, dusk for Evening
/// Prayer. Stops run from the top of the card to the bottom; the card's text
/// sits at the top, where each sky is lightest (dawn, light) or darkest.
public enum Sky {
    public struct Gradient: Hashable, Sendable {
        public var stops: [RGBA]
        /// The colour of text set on the top of the sky.
        public var text: RGBA
    }

    public static func dawn(dark: Bool) -> Gradient {
        dark
            ? Gradient(stops: [RGBA(hex: 0x1D2740), RGBA(hex: 0x463B5E), RGBA(hex: 0x9C6250)], text: RGBA(hex: 0xF6EEE4))
            : Gradient(stops: [RGBA(hex: 0xC4DDF2), RGBA(hex: 0xF7DCB4), RGBA(hex: 0xF3AE84)], text: RGBA(hex: 0x1B2738))
    }

    public static func dusk(dark: Bool) -> Gradient {
        dark
            ? Gradient(stops: [RGBA(hex: 0x12172E), RGBA(hex: 0x3F2549), RGBA(hex: 0x8E3F3A)], text: RGBA(hex: 0xF6EEE4))
            : Gradient(stops: [RGBA(hex: 0x3D4C8C), RGBA(hex: 0xA65A86), RGBA(hex: 0xF09A5B)], text: RGBA(hex: 0xFFFFFF))
    }

    /// The covers of the Library's folders: one quiet colour each, deepening
    /// from top to bottom, with light text at the top. In dark appearance
    /// the same colours are dimmed.
    public enum Folder: String, Hashable, Sendable, CaseIterable {
        case psalter, collects, creeds
        /// Seasons of the Collects. The 1662 book prescribes no liturgical
        /// colours; these follow the season accents (`Palette.seasonAccent`).
        case violet, gold, green, red, blue
    }

    public static func folder(_ folder: Folder, dark: Bool) -> Gradient {
        let stops: [UInt32]
        switch folder {
        case .psalter: stops = [0x2F5D50, 0x4A7A66, 0x8DB59A]
        case .collects: stops = [0x6B2737, 0x8E3D51, 0xC98A8F]
        case .creeds: stops = [0x5E4614, 0x7E6224, 0xC4A766]
        case .violet: stops = [0x3E2F63, 0x5A4785, 0xA592C9]
        case .gold: stops = [0x6A4E10, 0x8A6A1F, 0xD8BC72]
        case .green: stops = [0x2E5A3A, 0x467550, 0x98BE8E]
        case .red: stops = [0x7A2420, 0x9A372D, 0xD98A6E]
        case .blue: stops = [0x2B4166, 0x405B88, 0x93ABCF]
        }
        let colours = stops.map { RGBA(hex: $0) }
        return dark
            ? Gradient(stops: colours.map { $0.scaled(0.55) }, text: RGBA(hex: 0xF6EEE4))
            : Gradient(stops: colours, text: RGBA(hex: 0xFFFFFF))
    }
}

extension RGBA {
    /// The colour with each channel multiplied by `factor`: darker below 1.
    public func scaled(_ factor: Double) -> RGBA {
        RGBA(red * factor, green * factor, blue * factor, alpha)
    }
}
