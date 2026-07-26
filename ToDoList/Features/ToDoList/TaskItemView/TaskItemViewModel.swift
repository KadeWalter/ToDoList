//
//  TaskItemViewModel.swift
//  ToDoList
//
//  Created by Kade Walter on 7/24/26.
//

import Foundation

class TaskItemViewModel {
    let task: TaskModel
    private let onUpdate: (TaskModel) -> Void

    init(task: TaskModel, onUpdate: @escaping (TaskModel) -> Void) {
        self.task = task
        self.onUpdate = onUpdate
    }

    func updateTaskCompleted() {
        var updateTask = task
        updateTask.toggleCompleted()
        onUpdate(updateTask)
    }
}
