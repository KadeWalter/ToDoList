//
//  ToDoList+PreviewSupport.swift
//  ToDoList
//
//  Created by Kade Walter on 7/24/26.
//

#if DEBUG
import Foundation

extension TaskModel {
    /// Sample tasks for SwiftUI previews.
    static let samples: [TaskModel] = [
        TaskModel(title: "Buy groceries"),
        TaskModel(title: "Walk the dog", completed: true),
        TaskModel(title: "Finish the take-home")
    ]
}

/// In-memory preview/test double for the repository
final class PreviewTaskRepository: TaskRepositoryProtocol {
    private(set) var tasks: [TaskModel]

    init(tasks: [TaskModel] = TaskModel.samples) {
        self.tasks = tasks
    }

    func fetchTasks() throws -> [TaskModel] { tasks }

    func refreshTasks() async throws -> [TaskModel] { tasks }

    @discardableResult
    func createTask(title: String) throws -> TaskModel {
        let task = TaskModel(title: title)
        tasks.append(task)
        return task
    }

    func update(_ task: TaskModel) throws {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
    }

    func deleteTask(id: TaskModel.ID) throws {
        tasks.removeAll { $0.id == id }
    }

    func deleteAllTasks() throws {
        tasks.removeAll()
    }
}

extension ToDoListViewModel {
    /// A mock-backed view model seeded with sample tasks, for previews.
    static func preview(tasks: [TaskModel] = TaskModel.samples) -> ToDoListViewModel {
        let viewModel = ToDoListViewModel(taskRepository: PreviewTaskRepository(tasks: tasks))
        viewModel.loadTasks()
        return viewModel
    }
}
#endif
