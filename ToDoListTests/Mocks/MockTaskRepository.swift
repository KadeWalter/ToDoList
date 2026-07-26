//
//  MockTaskRepository.swift
//  ToDoListTests
//
//  Test doubles for each protocol seam.
//

import Foundation
@testable import ToDoList

@MainActor
final class MockTaskRepository: TaskRepositoryProtocol {
    var localTasks: [TaskModel] = []
    var remoteTasks: [TaskModel] = []
    var errorToThrow: Error?

    private(set) var refreshCallCount = 0
    private(set) var createdTitles: [String] = []
    private(set) var updatedTasks: [TaskModel] = []
    private(set) var deletedIDs: [TaskModel.ID] = []
    private(set) var deleteAllCallCount = 0

    func fetchTasks() throws -> [TaskModel] {
        if let errorToThrow { throw errorToThrow }
        return localTasks
    }

    @discardableResult
    func refreshTasks() async throws -> [TaskModel] {
        refreshCallCount += 1
        if let errorToThrow { throw errorToThrow }
        localTasks = remoteTasks
        return localTasks
    }

    @discardableResult
    func createTask(title: String) throws -> TaskModel {
        if let errorToThrow { throw errorToThrow }
        createdTitles.append(title)
        let task = TaskModel(title: title)
        localTasks.append(task)
        return task
    }

    func update(_ task: TaskModel) throws {
        if let errorToThrow { throw errorToThrow }
        updatedTasks.append(task)
        if let index = localTasks.firstIndex(where: { $0.id == task.id }) {
            localTasks[index] = task
        }
    }

    func deleteTask(id: TaskModel.ID) throws {
        if let errorToThrow { throw errorToThrow }
        deletedIDs.append(id)
        localTasks.removeAll { $0.id == id }
    }

    func deleteAllTasks() throws {
        if let errorToThrow { throw errorToThrow }
        deleteAllCallCount += 1
        localTasks.removeAll()
    }
}
