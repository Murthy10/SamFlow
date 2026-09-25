import Foundation

/// Append-only log of finished sessions.
///
/// Deliberately narrow: the app writes a session once, when it ends, and reads
/// the whole log back. There is no update or partial query, because there is no
/// feature that needs one.
public protocol SessionStore: Sendable {
    func load() throws -> [FocusSession]
    func append(_ session: FocusSession) throws
}

/// Stores the log as a single JSON file under Application Support.
public struct JSONFileSessionStore: SessionStore {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    /// `~/Library/Application Support/SamFlow/sessions.json`
    public static func applicationSupport(bundleName: String = "SamFlow") throws -> JSONFileSessionStore {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent(bundleName, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return JSONFileSessionStore(url: directory.appendingPathComponent("sessions.json"))
    }

    public func load() throws -> [FocusSession] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        guard !data.isEmpty else { return [] }
        return try Self.decoder.decode([FocusSession].self, from: data)
    }

    public func append(_ session: FocusSession) throws {
        var sessions = try load()
        sessions.append(session)
        let data = try Self.encoder.encode(sessions)
        // Atomic so a crash mid-write cannot truncate the log.
        try data.write(to: url, options: .atomic)
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}

/// Test double.
public final class InMemorySessionStore: SessionStore, @unchecked Sendable {
    private let lock = NSLock()
    private var sessions: [FocusSession]

    public init(sessions: [FocusSession] = []) {
        self.sessions = sessions
    }

    public func load() throws -> [FocusSession] {
        lock.withLock { sessions }
    }

    public func append(_ session: FocusSession) throws {
        lock.withLock { sessions.append(session) }
    }
}
