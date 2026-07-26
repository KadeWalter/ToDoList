//
//  TaskItem+TaskModel.swift
//  ToDoList
//
//  Created by Kade Walter on 7/23/26.
//

import CoreData

// Mapping between the Core Data record (`TaskItem`) and the domain value type (`TaskModel`).
nonisolated extension TaskItem {

    func toModel() -> TaskModel {
        TaskModel(
            id: id,
            title: title,
            completed: completed,
            remoteID: remoteID?.intValue,
            userId: userId?.intValue
        )
    }

    func apply(_ model: TaskModel) {
        applyRemoteFields(model)
        // This prevents overwrite of local completed state when refetching tasks from API
        completed = model.completed
    }
    
    func applyRemoteFields(_ model: TaskModel) {
        title = model.title
        remoteID = model.remoteID.map { NSNumber(value: $0) }
        userId = model.userId.map { NSNumber(value: $0) }
    }
}
