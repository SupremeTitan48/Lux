import Testing
@testable import LuxDesignSystem

@Suite struct ContrastTests {
    /// Reading text must meet WCAG AA (4.5:1) on the page in both appearances;
    /// rubrics are body-sized italic text and must meet it too.
    @Test(arguments: [("textPrimary", Palette.textPrimary), ("textSecondary", Palette.textSecondary), ("rubric", Palette.rubric), ("notice", Palette.notice), ("accent", Palette.accent)])
    func textContrast(name: String, color: AdaptiveColor) {
        #expect(color.light.contrast(with: Palette.surfacePrimary.light) >= 4.5, "\(name) light")
        #expect(color.dark.contrast(with: Palette.surfacePrimary.dark) >= 4.5, "\(name) dark")
        #expect(color.light.contrast(with: Palette.surfaceSecondary.light) >= 4.5, "\(name) light raised")
        #expect(color.dark.contrast(with: Palette.surfaceSecondary.dark) >= 4.5, "\(name) dark raised")
    }

    @Test func contrastMath() {
        let black = RGBA(0, 0, 0), white = RGBA(1, 1, 1)
        #expect(abs(black.contrast(with: white) - 21) < 0.01)
        #expect(abs(white.contrast(with: white) - 1) < 0.0001)
    }
}

@Suite struct ReadingStyleTests {
    @Test func scalesSizeAndLeading() {
        let style = ReadingStyle(typeface: .baskerville, scale: 1.5, leading: 2)
        #expect(style.size(.body) == TypeRole.body.size * 1.5)
        #expect(style.lineSpacing(.body) == TypeRole.body.lineSpacing * 3)
        #expect(ReadingStyle.standard.size(.verse) == TypeRole.verse.size)
    }

    @Test func clampsToItsRanges() {
        let style = ReadingStyle(scale: 9, leading: -1)
        #expect(style.scale == ReadingStyle.scaleRange.upperBound)
        #expect(style.leading == ReadingStyle.leadingRange.lowerBound)
    }

    @Test func surfacesAreNeutral() {
        for color in [Palette.surfacePrimary.light, Palette.surfacePrimary.dark, Palette.surfaceSecondary.light, Palette.surfaceSecondary.dark] {
            #expect(color.red == color.green && color.green == color.blue)
        }
    }
}

@Suite struct SkyTests {
    /// The card's title is large text (WCAG AA 3:1) over the top of the sky,
    /// and must also clear the middle stop, where a long title can reach.
    @Test(arguments: [false, true])
    func titlesAreLegible(dark: Bool) {
        for sky in [Sky.dawn(dark: dark), Sky.dusk(dark: dark)] {
            #expect(sky.text.contrast(with: sky.stops[0]) >= 4.5)
            #expect(sky.text.contrast(with: sky.stops[1]) >= 3)
        }
    }
}
