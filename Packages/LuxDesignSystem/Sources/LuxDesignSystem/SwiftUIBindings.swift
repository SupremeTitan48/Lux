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

extension ReadingStyle {
    /// The font for a role in this style, at the given Dynamic Type size.
    public func font(_ role: TypeRole, dynamicType: DynamicTypeSize = .large) -> Font {
        let points = size(role) * dynamicType.scale
        var font: Font
        switch typeface {
        case .systemSerif: font = .system(size: points, design: .serif)
        case .systemSans: font = .system(size: points, design: .default)
        default: font = .custom(typeface.familyName!, fixedSize: points)
        }
        if role.italic { font = font.italic() }
        return font
    }

    /// Line spacing for a role at the given Dynamic Type size.
    public func lineSpacing(_ role: TypeRole, dynamicType: DynamicTypeSize) -> Double {
        lineSpacing(role) * dynamicType.scale
    }
}

extension DynamicTypeSize {
    /// How much this size enlarges body text relative to the default
    /// (Large), after the body sizes of Apple's Dynamic Type table.
    public var scale: Double {
        let body: Double
        switch self {
        case .xSmall: body = 14
        case .small: body = 15
        case .medium: body = 16
        case .large: body = 17
        case .xLarge: body = 19
        case .xxLarge: body = 21
        case .xxxLarge: body = 23
        case .accessibility1: body = 28
        case .accessibility2: body = 33
        case .accessibility3: body = 40
        case .accessibility4: body = 47
        case .accessibility5: body = 53
        @unknown default: body = 17
        }
        return body / 17
    }
}

extension Sky.Gradient {
    public var linear: LinearGradient {
        LinearGradient(colors: stops.map(\.color), startPoint: .top, endPoint: .bottom)
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
