#if canImport(SwiftUI)
import SwiftUI

extension RGBA {
    public var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha) }
}

extension AdaptiveColor {
    /// The colour for the current colour scheme.
    public func color(for scheme: ColorScheme) -> Color {
        (scheme == .dark ? dark : light).color
    }
}

extension TypeRole {
    /// A font for this role that scales with Dynamic Type.
    public var font: Font {
        let relative: Font.TextStyle
        switch self {
        case .title: relative = .largeTitle
        case .heading: relative = .title3
        case .body, .verse: relative = .body
        case .rubric: relative = .callout
        case .caption: relative = .caption
        case .dropCap: relative = .largeTitle
        }
        var font = Typeface.isReadingFaceBundled
            ? Font.custom(Typeface.readingFamily, size: size, relativeTo: relative)
            : Font.system(relative, design: .serif)
        if italic { font = font.italic() }
        return font
    }
}

/// Reads palette colours for the current colour scheme.
public struct LuxColors {
    public let scheme: ColorScheme
    public init(_ scheme: ColorScheme) { self.scheme = scheme }

    public var surfacePrimary: Color { Palette.surfacePrimary.color(for: scheme) }
    public var surfaceSecondary: Color { Palette.surfaceSecondary.color(for: scheme) }
    public var textPrimary: Color { Palette.textPrimary.color(for: scheme) }
    public var textSecondary: Color { Palette.textSecondary.color(for: scheme) }
    public var rubric: Color { Palette.rubric.color(for: scheme) }
    public var divider: Color { Palette.divider.color(for: scheme) }
    public var notice: Color { Palette.notice.color(for: scheme) }
    public var accent: Color { Palette.accent.color(for: scheme) }
}
#endif
