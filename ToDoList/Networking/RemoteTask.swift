//
//  RemoteTask.swift
//  ToDoList
//
//  Created by Kade Walter on 7/23/26.
//

import Foundation

/// A task exactly as returned by the `/todos` API
nonisolated struct RemoteTask: Decodable, Sendable {
    let id: Int
    let userId: Int
    let title: String
    let completed: Bool
}

extension RemoteTask {
    /// Maps this API object into a new TaskModel
    func toModel() -> TaskModel {
        TaskModel(
            title: TaskModel.sanitize(title),
            completed: completed,
            remoteID: id,
            userId: userId
        )
    }
}
