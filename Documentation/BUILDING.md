# Building Lux

## Swift packages (any platform with Swift 6)

```sh
swift build --package-path Packages/LuxCore
swift build --package-path Packages/LuxDesignSystem
swift build --package-path Traditions/BCP1662
```

The packages need Swift 6.0 or later and Foundation only; they build on
macOS and Linux.

## Content

The pipeline needs Python 3.10 or later and nothing else.

```sh
cd Tools/ContentExtraction
python3 -m lux_extract build     # regenerate the content
python3 -m lux_extract check     # verify committed content is current
python3 -m lux_extract propose   # fill missing decision-table entries (uses system word lists)
```

`propose` is only needed when the witness or the normalization rules
change; it marks every new entry with how it was decided, for review.

## Apps

The apps are described by an [XcodeGen](https://github.com/yonaskolb/XcodeGen) spec.

```sh
brew install xcodegen
xcodegen generate --spec Apps/Lux/project.yml
open Apps/Lux/Lux.xcodeproj
```

Targets: `Lux` (iPhone, iPad, Mac, Apple Vision Pro) and `LuxWatch`
(Apple Watch). Set your development team in Xcode to run on a device.

The app sources were written without access to Xcode and had not been
compiled when this document was written; the macOS CI job is the first build.
