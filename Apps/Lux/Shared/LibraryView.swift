import BCP1662
import LuxCore
import LuxDesignSystem
import SwiftUI

/// Library: the book's texts outside the offices, in folders shown as cards.
struct LibraryView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NavigationStack {
            ScrollView {
                if let tradition = model.tradition {
                    let dark = scheme == .dark
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: Spacing.m)], spacing: Spacing.m) {
                        NavigationLink { PsalterPage(tradition: tradition) } label: {
                            GradientCard(title: "The Psalter", subtitle: "The Psalms of David, by day of the month",
                                         symbol: "music.note.list", sky: Sky.folder(.psalter, dark: dark), minHeight: 180)
                        }
                        NavigationLink { CollectsPage(tradition: tradition) } label: {
                            GradientCard(title: "The Collects", subtitle: "For the Sundays and holy days of the year",
                                         symbol: "text.book.closed", sky: Sky.folder(.collects, dark: dark), minHeight: 180)
                        }
                        NavigationLink {
                            ElementsPage(title: "The Creed of St Athanasius", elements: tradition.athanasianCreed)
                        } label: {
                            GradientCard(title: "Creeds", subtitle: "Quicunque vult",
                                         symbol: "books.vertical", sky: Sky.folder(.creeds, dark: dark), minHeight: 180)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(Spacing.m)
                }
            }
            .navigationTitle("Library")
        }
    }
}

/// The Psalter: the thirty days of the monthly course, then every psalm.
private struct PsalterPage: View {
    let tradition: BCP1662Tradition
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let colors = LuxColors(scheme)
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                heading("By day of the month", colors: colors)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: Spacing.s)], spacing: Spacing.s) {
                    ForEach(1...30, id: \.self) { day in
                        NavigationLink { PsalterDayPage(tradition: tradition, day: day) } label: {
                            IndexTile(title: "\(day)", caption: "Day")
                        }
                        .accessibilityLabel("Day \(day)")
                    }
                }
                heading("Every psalm", colors: colors)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 56), spacing: Spacing.s)], spacing: Spacing.s) {
                    ForEach(tradition.psalmNumbers, id: \.self) { number in
                        NavigationLink {
                            ElementsPage(title: "Psalm \(number)", elements: tradition.psalm(number))
                        } label: {
                            IndexTile(title: "\(number)")
                        }
                        .accessibilityLabel("Psalm \(number)")
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(Spacing.m)
        }
        .navigationTitle("The Psalter")
    }

    private func heading(_ text: String, colors: LuxColors) -> some View {
        Text(text.uppercased())
            .font(TypeRole.caption.font)
            .kerning(1.5)
            .foregroundStyle(colors.textSecondary)
            .accessibilityAddTraits(.isHeader)
    }
}

/// The psalms of one day of the course, at Morning and Evening Prayer.
private struct PsalterDayPage: View {
    let tradition: BCP1662Tradition
    let day: Int
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let colors = LuxColors(scheme)
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.l) {
                ForEach([Office.morningPrayer, .eveningPrayer], id: \.self) { office in
                    Text(office.displayName.uppercased())
                        .font(TypeRole.caption.font)
                        .kerning(1.5)
                        .foregroundStyle(colors.textSecondary)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(tradition.psalms(day: day, office: office), id: \.id) { ServiceElementView(element: $0) }
                }
            }
            .padding(.horizontal, ReaderLayout.margin)
            .padding(.vertical, Spacing.m)
        }
        .navigationTitle("Day \(day)")
    }
}

/// The Collects in folders by season.
private struct CollectsPage: View {
    let tradition: BCP1662Tradition
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: Spacing.m)], spacing: Spacing.m) {
                ForEach(tradition.collectGroups) { group in
                    NavigationLink { CollectGroupPage(group: group, tradition: tradition) } label: {
                        GradientCard(title: group.title, subtitle: "\(group.observances.count) collects",
                                     sky: Sky.folder(Self.folder(group.season), dark: scheme == .dark), minHeight: 120)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(Spacing.m)
        }
        .navigationTitle("The Collects")
    }

    /// The season's colour, after `Palette.seasonAccent`.
    static func folder(_ season: String) -> Sky.Folder {
        switch season {
        case "advent", "lent", "septuagesima": .violet
        case "christmas", "easter": .gold
        case "whitsun": .red
        case "saints": .blue
        default: .green
        }
    }
}

private struct CollectGroupPage: View {
    let group: BCP1662Tradition.CollectGroup
    let tradition: BCP1662Tradition

    var body: some View {
        List(group.observances, id: \.self) { id in
            NavigationLink(ObservanceNames.name(id)) {
                ElementsPage(title: ObservanceNames.name(id), elements: tradition.collects(for: id))
            }
        }
        .navigationTitle(group.title)
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
            .padding(.horizontal, ReaderLayout.margin)
            .padding(.vertical, Spacing.m)
        }
        .navigationTitle(title)
    }
}
