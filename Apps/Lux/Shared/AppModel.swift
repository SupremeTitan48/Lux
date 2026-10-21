import BCP1662
import Foundation
import LuxCore
import LuxKJV
import Observation

/// App-wide state: the tradition, loaded once, and the reader's settings.
@MainActor
@Observable
final class AppModel {
    let tradition: BCP1662Tradition?
    let loadError: String?

    init() {
        do {
            tradition = try BCP1662Tradition.bundled(scripture: [try KJVProvider.bundled()])
            loadError = nil
        } catch {
            tradition = nil
            loadError = "The prayer book texts could not be loaded or failed verification: \(error)"
        }
    }

    var today: CivilDate { CivilDate(Date(), in: .current) }

    func describe(_ date: CivilDate) -> DayDescription? {
        try? tradition?.describe(date)
    }

    func compose(_ office: Office, on date: CivilDate) -> Result<ServiceDocument, Error> {
        guard let tradition else { return .failure(CompositionError.contentMissing("tradition")) }
        return Result { try tradition.compose(office, on: date, options: CompositionOptions(scriptureTranslationID: KJVProvider.identifier)) }
    }

    /// The office most fitting for now: Morning Prayer before noon.
    func suggestedOffice(at instant: Date = Date()) -> Office {
        Calendar.current.component(.hour, from: instant) < 12 ? .morningPrayer : .eveningPrayer
    }
}

extension Office {
    var displayName: String {
        switch self {
        case .morningPrayer: "Morning Prayer"
        case .eveningPrayer: "Evening Prayer"
        default: rawValue
        }
    }
}

extension CivilDate {
    var formatted: String {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        let date = Calendar(identifier: .gregorian).date(from: components) ?? Date()
        return date.formatted(date: .complete, time: .omitted)
    }
}
