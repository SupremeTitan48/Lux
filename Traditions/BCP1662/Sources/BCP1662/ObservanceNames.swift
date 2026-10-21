import LuxCore

/// Display names for observances, in modern spelling. These are editorial
/// labels for headers and lists; the printed titles are kept in the content
/// and are what the service text uses.
public enum ObservanceNames {
    static let ordinals = ["", "First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh", "Eighth", "Ninth",
                           "Tenth", "Eleventh", "Twelfth", "Thirteenth", "Fourteenth", "Fifteenth", "Sixteenth",
                           "Seventeenth", "Eighteenth", "Nineteenth", "Twentieth", "Twenty-first", "Twenty-second",
                           "Twenty-third", "Twenty-fourth", "Twenty-fifth", "Twenty-sixth"]

    static let fixed: [String: String] = [
        "christmas": "Christmas Day", "stephen": "Saint Stephen’s Day", "john-evangelist": "Saint John the Evangelist’s Day",
        "innocents": "The Innocents’ Day", "christmas-1": "The Sunday after Christmas Day",
        "christmas-2": "The Second Sunday after Christmas Day",
        "wednesday-before-easter": "Wednesday before Easter", "thursday-before-easter": "Thursday before Easter",
        "circumcision": "The Circumcision of Christ", "epiphany": "The Epiphany",
        "septuagesima": "Septuagesima Sunday", "sexagesima": "Sexagesima Sunday", "quinquagesima": "Quinquagesima Sunday",
        "ash-wednesday": "Ash Wednesday", "palm-sunday": "The Sunday next before Easter", "good-friday": "Good Friday",
        "easter-even": "Easter Even", "easter": "Easter Day", "easter-monday": "Monday in Easter Week",
        "easter-tuesday": "Tuesday in Easter Week", "ascension": "Ascension Day",
        "ascension-sunday": "The Sunday after Ascension Day", "whitsunday": "Whitsunday",
        "whit-monday": "Monday in Whitsun Week", "whit-tuesday": "Tuesday in Whitsun Week", "trinity": "Trinity Sunday",
        "andrew": "Saint Andrew’s Day", "thomas": "Saint Thomas the Apostle", "conversion-of-paul": "The Conversion of Saint Paul",
        "purification": "The Purification of Saint Mary the Virgin", "matthias": "Saint Matthias’s Day",
        "annunciation": "The Annunciation of the Blessed Virgin Mary", "mark": "Saint Mark’s Day",
        "philip-and-james": "Saint Philip and Saint James’s Day", "barnabas": "Saint Barnabas the Apostle",
        "john-baptist": "Saint John Baptist’s Day", "peter": "Saint Peter’s Day", "james": "Saint James the Apostle",
        "bartholomew": "Saint Bartholomew the Apostle", "matthew": "Saint Matthew the Apostle",
        "michael": "Saint Michael and All Angels", "luke": "Saint Luke the Evangelist",
        "simon-and-jude": "Saint Simon and Saint Jude", "all-saints": "All Saints’ Day",
    ]

    public static func name(_ id: ObservanceID) -> String {
        if let name = fixed[id.rawValue] { return name }
        let parts = id.rawValue.split(separator: "-")
        if parts.count == 2, let n = Int(parts[1]), n < ordinals.count {
            let ordinal = ordinals[n]
            switch parts[0] {
            case "advent": return "The \(ordinal) Sunday in Advent"
            case "epiphany": return "The \(ordinal) Sunday after the Epiphany"
            case "lent": return "The \(ordinal) Sunday in Lent"
            case "easter": return "The \(ordinal) Sunday after Easter"
            case "trinity": return "The \(ordinal) Sunday after Trinity"
            default: break
            }
        }
        return id.rawValue
    }

    static func weekdayName(_ weekday: Weekday) -> String {
        ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][weekday.rawValue]
    }
}
