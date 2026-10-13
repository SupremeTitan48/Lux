import LuxCore
import LuxDesignSystem
import SwiftUI

/// Today: what the day is, and the way into its offices.
struct TodayView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let date = model.today
        let colors = LuxColors(scheme)
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(date.formatted).font(TypeRole.caption.font).foregroundStyle(colors.textSecondary)
                        if let day = model.describe(date) {
                            Text(day.title).font(TypeRole.title.font).foregroundStyle(colors.textPrimary)
                        }
                    }
                    .padding(.vertical, Spacing.s)
                }
                Section("Daily Offices") {
                    ForEach([Office.morningPrayer, .eveningPrayer], id: \.self) { office in
                        NavigationLink(value: office) {
                            Label(office.displayName, systemImage: office == .morningPrayer ? "sunrise" : "sunset")
                                .font(TypeRole.body.font)
                        }
                    }
                }
                if let error = model.loadError {
                    Section { Text(error).foregroundStyle(colors.notice) }
                }
            }
            .navigationTitle("Today")
            .navigationDestination(for: Office.self) { office in
                ReaderView(office: office, date: date)
            }
        }
    }
}
