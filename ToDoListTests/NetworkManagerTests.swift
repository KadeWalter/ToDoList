//
//  NetworkManagerTests.swift
//  ToDoListTests
//

import XCTest
import Foundation
@testable import ToDoList

final class NetworkManagerTests: XCTestCase {

    private let endpoint = URL(string: "https://example.com/todos")!

    private let validJSON = Data("""
    [ { "userId": 1, "id": 1, "title": "a", "completed": false } ]
    """.utf8)

    func testFetchDecodesOnSuccess() async throws {
        let sut = NetworkManager(urlSession: MockURLSession(data: validJSON, statusCode: 200))
        let result = try await sut.fetch(as: [RemoteTask].self, endpoint: endpoint)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first!.id, 1)
    }

    func testFetchThrowsInvalidUrlForNilEndpoint() async {
        let sut = NetworkManager(urlSession: MockURLSession())
        await XCTAssertThrowsErrorAsync(try await sut.fetch(as: [RemoteTask].self, endpoint: nil)) { error in
            XCTAssertEqual(error as? APIErrors, .invalidUrl)
        }
    }

    func testFetchThrowsInvalidResponseForNon2xxStatus() async {
        let sut = NetworkManager(urlSession: MockURLSession(data: validJSON, statusCode: 500))
        await XCTAssertThrowsErrorAsync(try await sut.fetch(as: [RemoteTask].self, endpoint: endpoint)) { error in
            XCTAssertEqual(error as? APIErrors, .invalidResponse)
        }
    }

    func testFetchThrowsInvalidResponseForNonHTTPResponse() async {
        let nonHTTP = URLResponse(url: endpoint, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let sut = NetworkManager(urlSession: MockURLSession(data: validJSON, response: nonHTTP))
        await XCTAssertThrowsErrorAsync(try await sut.fetch(as: [RemoteTask].self, endpoint: endpoint)) { error in
            XCTAssertEqual(error as? APIErrors, .invalidResponse)
        }
    }

    func testFetchThrowsDecodingFailedForBadJSON() async {
        let sut = NetworkManager(urlSession: MockURLSession(data: Data("not json".utf8), statusCode: 200))
        await XCTAssertThrowsErrorAsync(try await sut.fetch(as: [RemoteTask].self, endpoint: endpoint)) { error in
            XCTAssertEqual(error as? APIErrors, .decodingFailed)
        }
    }

    func testFetchPropagatesTransportError() async {
        let sut = NetworkManager(urlSession: MockURLSession(errorToThrow: TestError.boom))
        await XCTAssertThrowsErrorAsync(try await sut.fetch(as: [RemoteTask].self, endpoint: endpoint)) { error in
            XCTAssertEqual(error as? TestError, .boom)
        }
    }

    func testFetchAcceptsStatusCodesAtBothEndsOfTheSuccessRange() async throws {
        for statusCode in [200, 201, 299] {
            let sut = NetworkManager(urlSession: MockURLSession(data: validJSON, statusCode: statusCode))
            let result = try await sut.fetch(as: [RemoteTask].self, endpoint: endpoint)
            XCTAssertEqual(result.count, 1, "Expected \(statusCode) to be treated as success")
        }
    }

    func testFetchRejectsStatusCodesJustOutsideTheSuccessRange() async {
        for statusCode in [199, 300, 404] {
            let sut = NetworkManager(urlSession: MockURLSession(data: validJSON, statusCode: statusCode))
            await XCTAssertThrowsErrorAsync(
                try await sut.fetch(as: [RemoteTask].self, endpoint: endpoint),
                "Expected \(statusCode) to be rejected"
            ) { error in
                XCTAssertEqual(error as? APIErrors, .invalidResponse)
            }
        }
    }

    func testFetchThrowsDecodingFailedForEmptyBody() async {
        let sut = NetworkManager(urlSession: MockURLSession(data: Data(), statusCode: 200))
        await XCTAssertThrowsErrorAsync(try await sut.fetch(as: [RemoteTask].self, endpoint: endpoint)) { error in
            XCTAssertEqual(error as? APIErrors, .decodingFailed)
        }
    }

    func testFetchThrowsDecodingFailedWhenBodyShapeDoesNotMatch() async {
        // Valid JSON, wrong shape: a single object where an array is expected.
        let single = Data("""
        { "userId": 1, "id": 1, "title": "a", "completed": false }
        """.utf8)
        let sut = NetworkManager(urlSession: MockURLSession(data: single, statusCode: 200))
        await XCTAssertThrowsErrorAsync(try await sut.fetch(as: [RemoteTask].self, endpoint: endpoint)) { error in
            XCTAssertEqual(error as? APIErrors, .decodingFailed)
        }
    }

    func testFetchValidatesStatusBeforeDecoding() async {
        // Garbage body behind an error status should surface the status failure,
        // not a decoding failure — otherwise a 500 page masquerades as a parse bug.
        let sut = NetworkManager(urlSession: MockURLSession(data: Data("<html>".utf8), statusCode: 500))
        await XCTAssertThrowsErrorAsync(try await sut.fetch(as: [RemoteTask].self, endpoint: endpoint)) { error in
            XCTAssertEqual(error as? APIErrors, .invalidResponse)
        }
    }

    func testFetchDecodesEmptyArrayAsSuccess() async throws {
        let sut = NetworkManager(urlSession: MockURLSession(data: Data("[]".utf8), statusCode: 200))
        let result = try await sut.fetch(as: [RemoteTask].self, endpoint: endpoint)
        XCTAssertTrue(result.isEmpty)
    }
}
