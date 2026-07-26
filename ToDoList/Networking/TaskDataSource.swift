//
//  TaskDataSource.swift
//  ToDoList
//
//  Created by Kade Walter on 7/23/26.
//

import Foundation

protocol TaskDataSourceProtocol: Sendable {
    func getRemoteTasks() async throws -> [RemoteTask]
}

/// Remote data source for tasks
nonisolated final class TaskDataSource: TaskDataSourceProtocol {
    private let networkManager: NetworkManaging
    private let endpoint = URL(string: "https://jsonplaceholder.typicode.com/todos")

    init(networkManager: NetworkManaging) {
        self.networkManager = networkManager
    }

    func getRemoteTasks() async throws -> [RemoteTask] {
        return try await networkManager.fetch(as: [RemoteTask].self, endpoint: endpoint)
    }
}
