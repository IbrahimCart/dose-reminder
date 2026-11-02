import Foundation

/// Saves the log as a JSON file on the device. Nothing leaves the phone.
public struct JSONFileStore {
    public let url: URL

    public init(url: URL) { self.url = url }

    public static func standard() -> JSONFileStore {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return JSONFileStore(url: dir.appendingPathComponent("doses.json"))
    }

    public func load() -> DoseLog? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(DoseLog.self, from: data)
    }

    public func save(_ log: DoseLog) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(log).write(to: url, options: .atomic)
    }
}
