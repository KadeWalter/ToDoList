//
//  NetworkingManager.swift
//  ToDoList
//
//  Created by Kade Walter on 7/23/26.
//

import Foundation

protocol NetworkManaging: Sendable {
    func fetch<T: Decodable>(as type: T.Type, endpoint: URL?) async throws -> T
}

nonisolated final class NetworkManager: NetworkManaging {

    private let urlSession: URLSessionProtocol

    init(urlSession: URLSessionProtocol) {
        self.urlSession = urlSession
    }

    func fetch<T: Decodable>(as type: T.Type, endpoint: URL?) async throws -> T {
        guard let endpoint else {
            throw APIErrors.invalidUrl
        }

        let (data, response) = try await urlSession.data(from: endpoint, delegate: nil)

        try validateResponse(response: response)

        return try decodeData(as: type, data: data)
    }

    private func validateResponse(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw APIErrors.invalidResponse
        }
    }

    private func decodeData<T: Decodable>(as type: T.Type, data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw APIErrors.decodingFailed
        }
    }
}
