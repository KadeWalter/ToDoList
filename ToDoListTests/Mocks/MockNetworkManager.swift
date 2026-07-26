//
//  MockNetworkManager.swift
//  ToDoListTests
//
//  Created by Kade Walter on 7/25/26.
//

import Foundation
@testable import ToDoList

/// `fetch` always resolves to the configured `remoteTasks` (or throws).
/// `TaskDataSource` only ever requests `[RemoteTask]`, so the cast is safe.
nonisolated final class MockNetworkManager: NetworkManaging, @unchecked Sendable {
    var remoteTasks: [RemoteTask] = []
    var errorToThrow: Error?
    private(set) var fetchCallCount = 0
    private(set) var lastEndpoint: URL?

    func fetch<T>(as type: T.Type, endpoint: URL?) async throws -> T where T: Decodable {
        fetchCallCount += 1
        lastEndpoint = endpoint
        if let errorToThrow { throw errorToThrow }
        return remoteTasks as! T
    }
}
