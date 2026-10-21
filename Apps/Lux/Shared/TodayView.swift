import LuxCore
import LuxDesignSystem
import SwiftUI

/// Today: what the day is, and its offices as a carousel of cards.
struct TodayView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var scheme
    @State private var shown: Office?

    private let offices: [Office] = [.morningPrayer, .eveningPrayer]

    var body: some View {
        let date = model.today
        let colors = LuxColors(scheme)
        let suggested = model.suggestedOffice()
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(date.formatted).font(TypeRole.caption.font).foregroundStyle(colors.textSecondary)
                        if let day = model.describe(date) {
                            Text(day.title).font(TypeRole.title.font).foregroundStyle(colors.textPrimary)
                        }
                    }
                    .padding(.horizontal, Spacing.m)
                    #if os(watchOS)
                    VStack(spacing: Spacing.s) {
                        ForEach(offices, id: \.self) { office in
                            NavigationLink(value: office) { OfficeCard(office: office, isSuggested: office == suggested, minHeight: 90) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.s)
                    #else
                    Carousel(items: offices, selection: $shown) { office in
                        NavigationLink(value: office) {
                            OfficeCard(office: office, isSuggested: office == suggested, minHeight: 260)
                        }
                        .buttonStyle(.plain)
                    }
                    #endif
                    if let error = model.loadError {
                        Text(error).font(TypeRole.caption.font).foregroundStyle(colors.notice).padding(.horizontal, Spacing.m)
                    }
                }
                .padding(.vertical, Spacing.m)
            }
            .navigationTitle("Today")
            .navigationDestination(for: Office.self) { office in
                ReaderView(office: office, date: date)
            }
            .onAppear { if shown == nil { shown = suggested } }
        }
    }
}
