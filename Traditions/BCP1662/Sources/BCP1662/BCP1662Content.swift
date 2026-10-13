import Foundation
import LuxCore

/// The structured texts of the 1662 Book of Common Prayer bundled with this
/// package, verified against their manifest when loaded.
public struct BCP1662Content: Sendable {
    public let manifest: ContentManifest
    let psalter: PsalterFile
    let collects: CollectsFile
    let morningPrayer: ServiceFile
    let eveningPrayer: ServiceFile
    let athanasianCreed: ServiceFile
    let easterAnthems: ServiceFile
    let generalRubrics: ServiceFile

    public var sourceID: String { manifest.source.id }

    public enum LoadError: Error {
        case resourcesMissing
    }

    /// Loads the bundled content. Verification hashes every file (a few
    /// hundred kilobytes); pass `verify: false` only where integrity was
    /// already established.
    public static func bundled(verify: Bool = true) throws -> BCP1662Content {
        guard let root = Bundle.module.url(forResource: "Content", withExtension: nil) else {
            throw LoadError.resourcesMissing
        }
        return try BCP1662Content(directory: root, verify: verify)
    }

    public init(directory: URL, verify: Bool = true) throws {
        let decoder = JSONDecoder()
        func load<T: Decodable>(_ type: T.Type, _ path: String) throws -> T {
            try decoder.decode(T.self, from: Data(contentsOf: directory.appendingPathComponent(path)))
        }
        manifest = try load(ContentManifest.self, "manifest.json")
        if verify { try manifest.verify(in: directory) }
        psalter = try load(PsalterFile.self, "psalter.json")
        collects = try load(CollectsFile.self, "collects.json")
        morningPrayer = try load(ServiceFile.self, "services/morning-prayer.json")
        eveningPrayer = try load(ServiceFile.self, "services/evening-prayer.json")
        athanasianCreed = try load(ServiceFile.self, "services/athanasian-creed.json")
        easterAnthems = try load(ServiceFile.self, "propers/easter-anthems.json")
        generalRubrics = try load(ServiceFile.self, "rubrics/general.json")
    }

    func observance(_ id: ObservanceID) -> CollectsFile.Observance? {
        collects.observances.first { $0.id == id.rawValue }
    }
}
