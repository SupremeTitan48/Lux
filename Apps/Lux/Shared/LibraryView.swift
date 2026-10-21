import BCP1662
import LuxCore
import LuxDesignSystem
import SwiftUI

/// Library: the Psalter, the Collects and the Creed of St Athanasius.
struct LibraryView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            List {
                if let tradition = model.tradition {
                    Section("The Psalter") {
                        NavigationLink("The Psalms of David") { PsalterIndex(tradition: tradition) }
                    }
                    Section("The Collects") {
                        ForEach(tradition.collectObservances, id: \.self) { id in
                            NavigationLink(ObservanceNames.name(id)) {
                                ElementsPage(title: ObservanceNames.name(id), elements: tradition.collects(for: id))
                            }
                        }
                    }
                    Section("Creeds") {
                        NavigationLink("Quicunque vult") {
                            ElementsPage(title: "The Creed of St Athanasius", elements: tradition.athanasianCreed)
                        }
                    }
                }
            }
            .navigationTitle("Library")
        }
    }
}

private struct PsalterIndex: View {
    let tradition: BCP1662Tradition

    var body: some View {
        List(tradition.psalmNumbers, id: \.self) { number in
            NavigationLink("Psalm \(number)") {
                ElementsPage(title: "Psalm \(number)", elements: tradition.psalm(number))
            }
        }
        .navigationTitle("The Psalter")
    }
}

struct ElementsPage: View {
    let title: String
    let elements: [ServiceElement]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.l) {
                ForEach(elements, id: \.id) { ServiceElementView(element: $0) }
            }
            .padding(Spacing.m)
            .frame(maxWidth: Spacing.readingMeasure, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(title)
    }
}
