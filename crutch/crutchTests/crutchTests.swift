//
//  crutchTests.swift
//  crutchTests
//
//  Created by Jeff Levensailor on 11/4/25.
//

import CryptoKit
import Foundation
import Testing
@testable import crutch

struct crutchTests {

    @Test func parserCreatesSongsFromMarkdownBlocks() async throws {
        let markdown = """
        # First Song
        ###
        line one
        line two
        ###

        # Second Song
        ###
        second line
        ###
        """

        let songs = SongLoader.parseMarkdown(markdown)

        #expect(songs.count == 2)
        #expect(songs[0].title == "First Song")
        #expect(songs[0].lyrics == "line one\nline two")
        #expect(songs[1].title == "Second Song")
        #expect(songs[1].lyrics == "second line")
    }

    @Test func parserConvertsLiteralNewlineEscapesInsideLyrics() async throws {
        let markdown = """
        # Escaped Song
        ###
        line one\\nline two
        ###
        """

        let songs = SongLoader.parseMarkdown(markdown)

        #expect(songs.count == 1)
        #expect(songs[0].lyrics == "line one\nline two")
    }

    @Test func paginatorSplitsByPageMarkerLinesAndDropsMarkers() async throws {
        let pages = LyricsPaginator.splitByPageMarkers("""
        first page
        #####
        second page
        trailing #####
        third page
        """)

        #expect(pages == ["first page", "second page", "third page"])
    }

    @Test func paginatorReturnsSingleEmptyPageForEmptyLyrics() async throws {
        let pages = LyricsPaginator.splitByPageMarkers("")

        #expect(pages == [""])
    }
    
    @Test func repositoryLoadsAndCachesRemotePayload() async throws {
        let markdown = """
        # Remote Song
        ###
        remote line
        ###
        """
        let payload = PublicLyricsPayload(
            version: 1,
            updatedAt: "2026-04-27T00:00:00Z",
            checksum: sha256(markdown),
            markdown: markdown
        )
        let data = try JSONEncoder().encode(payload)
        let fetcher = MockLyricsFetcher(results: [
            .success(data, statusCode: 200, headers: ["ETag": "lyrics-v1"]),
            .failure(URLError(.notConnectedToInternet))
        ])
        let repository = LyricsRepository(
            publicLyricsURL: URL(string: "https://example.com/api/public/lyrics")!,
            session: fetcher,
            cacheDirectory: temporaryDirectory()
        )

        let remoteSongs = await repository.loadSongs()
        let cachedSongs = await repository.loadSongs()

        #expect(remoteSongs.map(\.title) == ["Remote Song"])
        #expect(cachedSongs.map(\.title) == ["Remote Song"])
    }
    
    @Test func repositoryRejectsMalformedRemotePayload() async throws {
        let markdown = """
        # Bad Song
        ###
        bad line
        ###
        """
        let payload = PublicLyricsPayload(
            version: 1,
            updatedAt: "2026-04-27T00:00:00Z",
            checksum: "not-a-real-checksum",
            markdown: markdown
        )
        let data = try JSONEncoder().encode(payload)
        let fetcher = MockLyricsFetcher(results: [
            .success(data, statusCode: 200, headers: [:])
        ])
        let repository = LyricsRepository(
            publicLyricsURL: URL(string: "https://example.com/api/public/lyrics")!,
            session: fetcher,
            cacheDirectory: temporaryDirectory()
        )

        let songs = await repository.loadSongs()

        #expect(songs.map(\.title) != ["Bad Song"])
    }

}

private final class MockLyricsFetcher: LyricsFetching {
    enum Result {
        case success(Data, statusCode: Int, headers: [String: String])
        case failure(Error)
    }
    
    private var results: [Result]
    
    init(results: [Result]) {
        self.results = results
    }
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard !results.isEmpty else {
            throw URLError(.badServerResponse)
        }
        
        let result = results.removeFirst()
        switch result {
        case let .success(data, statusCode, headers):
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: headers
            )!
            return (data, response)
        case let .failure(error):
            throw error
        }
    }
}

private func sha256(_ value: String) -> String {
    SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
}

private func temporaryDirectory() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
}
