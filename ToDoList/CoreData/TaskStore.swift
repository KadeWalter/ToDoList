//
//  TaskStore.swift
//  ToDoList
//
//  Created by Kade Walter on 7/23/26.
//

import CoreData

enum TaskStoreError: Error {
    case taskNotFound(UUID)
}
    
extension TaskStoreError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .taskNotFound(let id):
            return "The task was not found. Task id: \(id)"
        }
    }
}

/// Local Core Data store for tasks
protocol TaskStoreProtocol {
    func fetchTasks() throws -> [TaskModel]
    @discardableResult func createTask(title: String) throws -> TaskModel
    func update(_ task: TaskModel) throws
    func deleteTask(id: TaskModel.ID) throws
    func deleteAllTasks() throws
    func save(_ tasks: [TaskModel]) throws
}

final class TaskStore: TaskStoreProtocol {
    private let persistence: PersistenceController
    
    private var context: NSManagedObjectContext { persistence.viewContext }
    
    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }
    
    func fetchTasks() throws -> [TaskModel] {
        let request = TaskItem.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskItem.title, ascending: true)
        ]
        return try context.fetch(request).map { $0.toModel() }
    }
    
    @discardableResult
    func createTask(title: String) throws -> TaskModel {
        let item = TaskItem(context: context)
        // id / completed defaults are set in TaskItem.awakeFromInsert().
        item.title = title
        try persistence.save(context)
        return item.toModel()
    }
    
    func update(_ task: TaskModel) throws {
        guard let item = try item(with: task.id) else {
            throw TaskStoreError.taskNotFound(task.id)
        }
        item.apply(task)
        try persistence.save(context)
    }
    
    func deleteTask(id: TaskModel.ID) throws {
        guard let item = try item(with: id) else { return }
        context.delete(item)
        try persistence.save(context)
    }
    
    func deleteAllTasks() throws {
        let items = try context.fetch(TaskItem.fetchRequest())
        for item in items {
            context.delete(item)
        }
        try persistence.save(context)
    }
    
    func save(_ tasks: [TaskModel]) throws {
        // Match incoming tasks to existing records by remoteID so a re-fetch
        // updates in place instead of creating duplicates.
        var itemsByRemoteID = try Self.existingItems(for: tasks, in: context)

        for task in tasks {
            if let remoteID = task.remoteID, let existing = itemsByRemoteID[remoteID] {
                existing.applyRemoteFields(task)
            } else {
                let item = TaskItem(context: context)
                item.apply(task)
                if let remoteID = task.remoteID {
                    // Track it so any later duplicate in the same batch matches too.
                    itemsByRemoteID[remoteID] = item
                }
            }
        }

        try persistence.save(context)
    }
}

// MARK: Helper functions
extension TaskStore {
    /// Fetches, in a single query, the existing records whose `remoteID` matches any
    /// of the incoming tasks — keyed by `remoteID`
    private nonisolated static func existingItems(
        for tasks: [TaskModel],
        in context: NSManagedObjectContext
    ) throws -> [Int: TaskItem] {
        let remoteIDs = tasks.compactMap(\.remoteID)
        guard !remoteIDs.isEmpty else { return [:] }

        let request = TaskItem.fetchRequest()
        request.predicate = NSPredicate(
            format: "remoteID IN %@",
            remoteIDs.map { NSNumber(value: $0) }
        )

        return try Dictionary(
            context.fetch(request).compactMap { item in
                item.remoteID.map { ($0.intValue, item) }
            },
            uniquingKeysWith: { first, _ in first }
        )
    }

    private func item(with id: UUID) throws -> TaskItem? {
        let request = TaskItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
