import LuxCore
import LuxDesignSystem
import SwiftUI

/// The Prayer Reader: a composed office, top to bottom.
struct ReaderView: View {
    let office: Office
    let date: CivilDate
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var scheme
    @State private var showNotes = false

    var body: some View {
        let colors = LuxColors(scheme)
        Group {
            switch model.compose(office, on: date) {
            case let .success(document):
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Spacing.l) {
                        header(document)
                        ForEach(document.sections) { section in
                            VStack(alignment: .leading, spacing: Spacing.m) {
                                if let title = section.title {
                                    Text(title.uppercased())
                                        .font(TypeRole.caption.font)
                                        .kerning(1.5)
                                        .foregroundStyle(colors.textSecondary)
                                        .accessibilityAddTraits(.isHeader)
                                }
                                ForEach(section.elements, id: \.id) { element in
                                    ServiceElementView(element: element)
                                }
                            }
                        }
                        notes(document)
                    }
                    .padding(Spacing.m)
                    .frame(maxWidth: Spacing.readingMeasure, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
            case let .failure(error):
                ContentUnavailableView("This office could not be composed", systemImage: "exclamationmark.triangle",
                                       description: Text(String(describing: error)))
            }
        }
        .background(colors.surfacePrimary)
        .navigationTitle(office.displayName)
    }

    private func header(_ document: ServiceDocument) -> some View {
        let colors = LuxColors(scheme)
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(document.title).font(TypeRole.title.font).foregroundStyle(colors.textPrimary)
            Text(document.day.title).font(TypeRole.heading.font).foregroundStyle(Palette.seasonAccent(document.day.season).color(for: scheme))
            Text(date.formatted).font(TypeRole.caption.font).foregroundStyle(colors.textSecondary)
        }
    }

    private func notes(_ document: ServiceDocument) -> some View {
        let list = VStack(alignment: .leading, spacing: Spacing.s) {
            ForEach(Array(document.diagnostics.enumerated()), id: \.offset) { _, diagnostic in
                Label(diagnostic.message, systemImage: diagnostic.severity == .info ? "info.circle" : "exclamationmark.circle")
                    .font(TypeRole.caption.font)
            }
        }
        #if os(watchOS)
        return VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Notes on this office").font(TypeRole.heading.font)
            list
        }
        .padding(.top, Spacing.l)
        #else
        return DisclosureGroup("Notes on this office (\(document.diagnostics.count))", isExpanded: $showNotes) {
            list.padding(.top, Spacing.s)
        }
        .font(TypeRole.caption.font)
        .padding(.top, Spacing.l)
        #endif
    }
}
