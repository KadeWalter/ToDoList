//
//  MockTaskDataSource.swift
//  ToDoListTests
//
//  Created by Kade Walter on 7/25/26.
//

import Foundation
@testable import ToDoList

nonisolated final class MockTaskDataSource: TaskDataSourceProtocol, @unchecked Sendable {
    var remoteTasks: [RemoteTask] = []
    var errorToThrow: Error?
    private(set) var getRemoteTasksCallCount = 0

    func getRemoteTasks() async throws -> [RemoteTask] {
        getRemoteTasksCallCount += 1
        if let errorToThrow { throw errorToThrow }
        return remoteTasks
    }
}
