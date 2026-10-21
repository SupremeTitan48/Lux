import BCP1662
import LuxCore
import LuxDesignSystem
import SwiftUI

/// Calendar: pick a date, see what the day is, and open its offices.
struct CalendarView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var scheme
    @State private var selection = Date()
    @State private var shown: Office? = .morningPrayer

    var body: some View {
        let date = CivilDate(selection, in: .current)
        let colors = LuxColors(scheme)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    DatePicker("Date", selection: $selection, in: Self.range, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .padding(Spacing.m)
                        .frame(maxWidth: 420)
                        .background(colors.surfaceSecondary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(colors.divider))
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, Spacing.m)
                    if let day = model.describe(date) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(date.formatted).font(TypeRole.caption.font).foregroundStyle(colors.textSecondary)
                            Text(day.title).font(TypeRole.title.font).foregroundStyle(colors.textPrimary)
                            ForEach(day.concurrent, id: \.self) { id in
                                Text("Also \(ObservanceNames.name(ObservanceID(id)))")
                                    .font(TypeRole.caption.font)
                                    .foregroundStyle(Palette.seasonAccent(day.season).color(for: scheme))
                            }
                        }
                        .padding(.horizontal, Spacing.m)
                        Carousel(items: [Office.morningPrayer, .eveningPrayer], selection: $shown) { office in
                            NavigationLink(value: office) { OfficeCard(office: office, minHeight: 180) }
                                .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, Spacing.m)
            }
            .navigationTitle("Calendar")
            .navigationDestination(for: Office.self) { office in
                ReaderView(office: office, date: date)
            }
        }
    }

    /// The 1662 rules are computed from 1753, after the calendar reform.
    static let range: ClosedRange<Date> = {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(from: DateComponents(year: 1753, month: 1, day: 1))!
        let end = calendar.date(from: DateComponents(year: 9999, month: 12, day: 31))!
        return start...end
    }()
}
