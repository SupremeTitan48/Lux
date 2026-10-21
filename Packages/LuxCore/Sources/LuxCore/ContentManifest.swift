import Foundation

/// The manifest at the root of a tradition's bundled content: which files
/// make up the content and their SHA-256 digests, and which source witness
/// they were generated from.
public struct ContentManifest: Hashable, Sendable, Codable {
    public struct File: Hashable, Sendable, Codable {
        public var path: String
        public var sha256: String
    }

    public struct Source: Hashable, Sendable, Codable {
        public var id: String
        public var file: String
        public var sha256: String
    }

    public var schemaVersion: Int
    public var tradition: String
    public var contentVersion: String
    public var title: String
    public var source: Source
    /// Further witnesses used for parts the primary source lacks (for
    /// example a lectionary taken from another printing).
    public var additionalSources: [Source]?
    public var files: [File]

    public enum IntegrityError: Error, Hashable, Sendable {
        case missing(String)
        case digestMismatch(path: String, expected: String, actual: String)
        case unsupportedSchema(Int)
    }

    public static let supportedSchemaVersion = 1

    /// Verifies every listed file under `directory`.
    public func verify(in directory: URL) throws {
        guard schemaVersion == ContentManifest.supportedSchemaVersion else {
            throw IntegrityError.unsupportedSchema(schemaVersion)
        }
        for file in files {
            let url = directory.appendingPathComponent(file.path)
            guard let data = try? Data(contentsOf: url) else { throw IntegrityError.missing(file.path) }
            let actual = SHA256Digest.hexHash(data)
            guard actual == file.sha256 else {
                throw IntegrityError.digestMismatch(path: file.path, expected: file.sha256, actual: actual)
            }
        }
    }
}
