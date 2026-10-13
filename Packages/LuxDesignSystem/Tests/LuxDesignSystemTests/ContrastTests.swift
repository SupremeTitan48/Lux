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
