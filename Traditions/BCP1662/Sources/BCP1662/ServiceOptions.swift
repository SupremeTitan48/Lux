import LuxCore

/// The choices the 1662 offices leave to the person praying, as settings.
///
/// None of them changes a word of the source. Each either selects among texts
/// the book prints as alternatives, leaves out a prayer the person chooses not
/// to say, or (for an officiant who is not a priest) leaves out what the book
/// reserves to a priest. See Documentation/SERVICE_OPTIONS.md.
extension BCP1662Tradition {
    public enum OptionID {
        public static let absolution = "absolution"
        public static let statePrayers = "state-prayers"
        public static let morningFirstCanticle = "mp.first-canticle"
        public static let morningSecondCanticle = "mp.second-canticle"
        public static let eveningFirstCanticle = "ep.first-canticle"
        public static let eveningSecondCanticle = "ep.second-canticle"
    }

    /// The choice that leaves a pair of canticles to be chosen in the office.
    public static let bothCanticles = "both"

    public var serviceOptions: [ServiceOption] { BCP1662Tradition.options }

    static let options: [ServiceOption] = [
        ServiceOption(
            id: OptionID.absolution, title: "In place of the Absolution",
            summary: "The Absolution is “to be pronounced by the Priest alone”. A deacon or lay person leaves it out; by long custom some say instead the Collect for the twenty-first Sunday after Trinity, which asks God for the same pardon.",
            group: "The Officiant", offices: [.morningPrayer, .eveningPrayer], officiants: [.deacon, .layPerson],
            choices: [.init(id: "omit", label: "Leave it out"),
                      .init(id: "trinity-21", label: "Collect for Trinity 21")],
            defaultChoice: "omit"),
        ServiceOption(
            id: OptionID.statePrayers, title: "Prayers for the King and the Royal Family",
            summary: "The two prayers are given as printed in 1762, naming King George and Queen Charlotte.",
            group: "Prayers", offices: [.morningPrayer, .eveningPrayer],
            choices: [.init(id: "include", label: "Include"), .init(id: "omit", label: "Leave out")],
            defaultChoice: "include"),
        canticles(OptionID.morningFirstCanticle, title: "After the first lesson", office: .morningPrayer,
                  first: ("te-deum", "Te Deum"), second: ("benedicite", "Benedicite")),
        canticles(OptionID.morningSecondCanticle, title: "After the second lesson", office: .morningPrayer,
                  first: ("benedictus", "Benedictus"), second: ("jubilate", "Jubilate Deo"),
                  summary: "The Jubilate is always said when the Benedictus is read in the second lesson or the Gospel."),
        canticles(OptionID.eveningFirstCanticle, title: "After the first lesson", office: .eveningPrayer,
                  first: ("magnificat", "Magnificat"), second: ("cantate", "Cantate Domino"),
                  summary: "Cantate Domino is not said on the nineteenth day of the month."),
        canticles(OptionID.eveningSecondCanticle, title: "After the second lesson", office: .eveningPrayer,
                  first: ("nunc-dimittis", "Nunc dimittis"), second: ("deus-misereatur", "Deus misereatur"),
                  summary: "Deus misereatur is not said on the twelfth day of the month."),
    ]

    private static func canticles(_ id: String, title: String, office: Office, first: (String, String), second: (String, String),
                                  summary: String? = nil) -> ServiceOption {
        ServiceOption(id: id, title: title, summary: summary, group: "Canticles", offices: [office],
                      choices: [.init(id: first.0, label: first.1), .init(id: second.0, label: second.1),
                                .init(id: bothCanticles, label: "Choose in the office")],
                      defaultChoice: first.0)
    }
}
