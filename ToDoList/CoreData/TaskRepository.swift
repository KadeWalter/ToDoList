//
//  TaskRepository.swift
//  ToDoList
//
//  Created by Kade Walter on 7/23/26.
//

import Foundation

enum TaskValidationError: Error, Equatable {
    case emptyTitle
}

extension TaskValidationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "A task needs a title."
        }
    }
}

/// Composes the remote data source (`TaskDataSource`) and the local Core Data
/// store (`TaskStore`) behind one interface, so the ViewModel depends on exactly
/// one thing and never has to know where a task came from.
protocol TaskRepositoryProtocol {
    func fetchTasks() throws -> [TaskModel]
    @discardableResult func refreshTasks() async throws -> [TaskModel]
    @discardableResult func createTask(title: String) throws -> TaskModel
    func update(_ task: TaskModel) throws
    func deleteTask(id: TaskModel.ID) throws
    func deleteAllTasks() throws
}

final class TaskRepository: TaskRepositoryProtocol {
    private let remote: TaskDataSourceProtocol
    private let store: TaskStoreProtocol

    init(
        remote: TaskDataSourceProtocol = TaskDataSource(
            networkManager: NetworkManager(
                urlSession: URLSession.shared
            )
        ),
        store: TaskStoreProtocol = TaskStore()
    ) {
        self.remote = remote
        self.store = store
    }

    func fetchTasks() throws -> [TaskModel] {
        try store.fetchTasks()
    }

    @discardableResult
    func refreshTasks() async throws -> [TaskModel] {
        let dtos = try await remote.getRemoteTasks()
        // Drop untitled records rather than failing the whole refresh
        let tasks = dtos.map { $0.toModel() }.filter(\.hasValidTitle)
        try store.save(tasks)
        return try store.fetchTasks()
    }

    @discardableResult
    func createTask(title: String) throws -> TaskModel {
        let sanitized = TaskModel.sanitize(title)
        guard !sanitized.isEmpty else {
            throw TaskValidationError.emptyTitle
        }
        return try store.createTask(title: sanitized)
    }

    func update(_ task: TaskModel) throws {
        try store.update(task)
    }

    func deleteTask(id: TaskModel.ID) throws {
        try store.deleteTask(id: id)
    }

    func deleteAllTasks() throws {
        try store.deleteAllTasks()
    }
}
