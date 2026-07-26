//
//  MockURLSession.swift
//  ToDoListTests
//
//  Created by Kade Walter on 7/25/26.
//

import Foundation
@testable import ToDoList

/// Returns canned data/response (or throws) without touching the network.
nonisolated final class MockURLSession: URLSessionProtocol, @unchecked Sendable {
    var data: Data
    var response: URLResponse
    var errorToThrow: Error?

    init(
        data: Data = Data(),
        statusCode: Int = 200,
        response: URLResponse? = nil,
        errorToThrow: Error? = nil
    ) {
        self.data = data
        self.response = response ?? HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        self.errorToThrow = errorToThrow
    }

    func data(from url: URL, delegate: (any URLSessionTaskDelegate)?) async throws -> (Data, URLResponse) {
        if let errorToThrow { throw errorToThrow }
        return (data, response)
    }
}
