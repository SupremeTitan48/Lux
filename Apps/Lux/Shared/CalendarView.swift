import LuxCore
import LuxDesignSystem
import SwiftUI

/// Calendar: pick a date and open its offices.
struct CalendarView: View {
    @Environment(AppModel.self) private var model
    @State private var selection = Date()

    var body: some View {
        let date = CivilDate(selection, in: .current)
        NavigationStack {
            List {
                Section {
                    DatePicker("Date", selection: $selection, in: Self.range, displayedComponents: .date)
                        #if !os(watchOS)
                        .datePickerStyle(.graphical)
                        #endif
                }
                if let day = model.describe(date) {
                    Section(day.title) {
                        ForEach([Office.morningPrayer, .eveningPrayer], id: \.self) { office in
                            NavigationLink(office.displayName) { ReaderView(office: office, date: date) }
                        }
                        ForEach(day.concurrent, id: \.self) { id in
                            Text("Also: \(id)").font(TypeRole.caption.font)
                        }
                    }
                }
            }
            .navigationTitle("Calendar")
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
