//
//  ToDoListViewModel.swift
//  ToDoList
//
//  Created by Kade Walter on 7/23/26.
//

import Foundation

@Observable
class ToDoListViewModel {

    var tasks: [TaskModel] = []
    var errorMessage: String?
    var loadingState: LoadingState = .loaded

    private let taskRepository: TaskRepositoryProtocol

    init(taskRepository: TaskRepositoryProtocol) {
        self.taskRepository = taskRepository
    }

    /// Loads the tasks already persisted locally in CoreData.
    func loadTasks() {
        do {
            tasks = try taskRepository.fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Fetches tasks from the API.
    func fetchRemoteTasks() async {
        loadingState = .loading
        do {
            tasks = try await taskRepository.refreshTasks()
            loadingState = .loaded
        } catch {
            errorMessage = error.localizedDescription
            loadingState = .failed
        }
    }

    func addTask(title: String) {
        let trimmed = TaskModel.sanitize(title)
        guard !trimmed.isEmpty else { return }
        do {
            try taskRepository.createTask(title: trimmed)
            // Re-read so the new task lands in its sorted (alphabetical) position.
            tasks = try taskRepository.fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateTask(_ task: TaskModel) {
        do {
            try taskRepository.update(task)
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = task
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTask(_ task: TaskModel) {
        do {
            try taskRepository.deleteTask(id: task.id)
            tasks.removeAll { $0.id == task.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAllTasks() {
        do {
            try taskRepository.deleteAllTasks()
            tasks.removeAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
