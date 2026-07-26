//
//  TaskModel.swift
//  ToDoList
//
//  Created by Kade Walter on 7/23/26.
//

import Foundation

/// The domain / UI representation of a task.
///
/// A plain value type, deliberately decoupled from Core Data: it carries the task's
/// data and its completion behavior, and is `Sendable` so it can cross concurrency
/// boundaries freely. The repository maps `TaskItem` (Core Data) and `RemoteTask`
/// (API) to and from this type, so the ViewModel and View never see a managed
/// object or a network model — which also lets the ViewModel be unit-tested with a
/// stub repository and no Core Data stack.
nonisolated struct TaskModel: Identifiable, Sendable, Equatable {
    let id: UUID
    var title: String
    var completed: Bool
    let remoteID: Int?
    let userId: Int?
    
    init(
        id: UUID = UUID(),
        title: String,
        completed: Bool = false,
        remoteID: Int? = nil,
        userId: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.completed = completed
        self.remoteID = remoteID
        self.userId = userId
    }
}

// MARK: Update `completed`
extension TaskModel {
    mutating func toggleCompleted() {
        completed.toggle()
    }
}

// MARK: Title validation
extension TaskModel {
    /// A task needs non-whitespace content to be worth showing — a blank row can't
    /// be read, and its only affordance is a checkbox with nothing to label it.
    var hasValidTitle: Bool {
        !Self.sanitize(title).isEmpty
    }

    /// The single definition of what a title is trimmed to, shared by the local
    /// create path and the remote refresh so the two can't drift apart.
    static func sanitize(_ title: String) -> String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
