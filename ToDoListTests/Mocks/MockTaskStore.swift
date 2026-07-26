//
//  MockTaskStore.swift
//  ToDoListTests
//
//  Created by Kade Walter on 7/25/26.
//

import Foundation
@testable import ToDoList

@MainActor
final class MockTaskStore: TaskStoreProtocol {
    var storedTasks: [TaskModel] = []
    var errorToThrow: Error?
    private(set) var savedBatches: [[TaskModel]] = []

    func fetchTasks() throws -> [TaskModel] {
        if let errorToThrow { throw errorToThrow }
        return storedTasks
    }

    @discardableResult
    func createTask(title: String) throws -> TaskModel {
        if let errorToThrow { throw errorToThrow }
        let task = TaskModel(title: title)
        storedTasks.append(task)
        return task
    }

    func update(_ task: TaskModel) throws {
        if let errorToThrow { throw errorToThrow }
        if let index = storedTasks.firstIndex(where: { $0.id == task.id }) {
            storedTasks[index] = task
        }
    }

    func deleteTask(id: TaskModel.ID) throws {
        if let errorToThrow { throw errorToThrow }
        storedTasks.removeAll { $0.id == id }
    }

    func deleteAllTasks() throws {
        if let errorToThrow { throw errorToThrow }
        storedTasks.removeAll()
    }

    func save(_ tasks: [TaskModel]) throws {
        if let errorToThrow { throw errorToThrow }
        savedBatches.append(tasks)
        storedTasks = tasks
    }
}
