import CryptoKit
import Foundation

protocol LyricsFetching {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: LyricsFetching {}

struct PublicLyricsPayload: Codable, Equatable {
    let version: Int
    let updatedAt: String
    let checksum: String
    let markdown: String
}

private struct CachedLyricsPayload: Codable {
    let payload: PublicLyricsPayload
    let eTag: String?
}

final class LyricsRepository {
    private enum Configuration {
        static let configResourceName = "AppConfig"
        static let configResourceExtension = "plist"
        static let publicLyricsURLKey = "LyricsPublicURL"
        static let cacheFileName = "lyrics-cache.json"
        static let ifNoneMatchHeader = "If-None-Match"
        static let eTagHeader = "ETag"
    }

    private let publicLyricsURL: URL?
    private let session: LyricsFetching
    private let fileManager: FileManager
    private let cacheURL: URL

    init(
        publicLyricsURL: URL? = LyricsRepository.configuredPublicLyricsURL(),
        session: LyricsFetching = URLSession.shared,
        fileManager: FileManager = .default,
        cacheDirectory: URL? = nil
    ) {
        self.publicLyricsURL = publicLyricsURL
        self.session = session
        self.fileManager = fileManager

        let defaultCacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        self.cacheURL = (cacheDirectory ?? defaultCacheDirectory ?? fileManager.temporaryDirectory)
            .appendingPathComponent(Configuration.cacheFileName)
    }

    func loadSongs() async -> [Song] {
        if let remotePayload = try? await fetchRemotePayload() {
            return SongLoader.parseMarkdown(remotePayload.markdown)
        }

        if let cachedPayload = loadCachedPayload() {
            return SongLoader.parseMarkdown(cachedPayload.markdown)
        }

        return SongLoader.loadBundledSongs()
    }

    func loadCachedPayload() -> PublicLyricsPayload? {
        guard let data = try? Data(contentsOf: cacheURL),
              let cached = try? JSONDecoder().decode(CachedLyricsPayload.self, from: data) else {
            return nil
        }

        return cached.payload
    }

    private func fetchRemotePayload() async throws -> PublicLyricsPayload? {
        guard let publicLyricsURL else {
            return nil
        }

        var request = URLRequest(url: publicLyricsURL)
        if let cached = loadCachedEnvelope(), let eTag = cached.eTag {
            request.setValue(eTag, forHTTPHeaderField: Configuration.ifNoneMatchHeader)
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 304 {
            return loadCachedPayload()
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let payload = try JSONDecoder().decode(PublicLyricsPayload.self, from: data)
        try validate(payload)
        try cache(payload, eTag: httpResponse.value(forHTTPHeaderField: Configuration.eTagHeader))
        return payload
    }

    private func validate(_ payload: PublicLyricsPayload) throws {
        guard payload.version > 0, !payload.markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw URLError(.cannotParseResponse)
        }

        let digest = SHA256.hash(data: Data(payload.markdown.utf8))
        let computedChecksum = digest.map { String(format: "%02x", $0) }.joined()

        guard payload.checksum == computedChecksum else {
            throw URLError(.cannotDecodeContentData)
        }
    }

    private func cache(_ payload: PublicLyricsPayload, eTag: String?) throws {
        let envelope = CachedLyricsPayload(payload: payload, eTag: eTag)
        let data = try JSONEncoder().encode(envelope)
        let directoryURL = cacheURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try data.write(to: cacheURL, options: .atomic)
    }

    private func loadCachedEnvelope() -> CachedLyricsPayload? {
        guard let data = try? Data(contentsOf: cacheURL) else {
            return nil
        }

        return try? JSONDecoder().decode(CachedLyricsPayload.self, from: data)
    }

    private static func configuredPublicLyricsURL() -> URL? {
        guard let configURL = Bundle.main.url(
            forResource: Configuration.configResourceName,
            withExtension: Configuration.configResourceExtension
        ),
              let config = NSDictionary(contentsOf: configURL),
              let rawValue = config[Configuration.publicLyricsURLKey] as? String else {
            return nil
        }

        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            return nil
        }

        return URL(string: trimmedValue)
    }
}
