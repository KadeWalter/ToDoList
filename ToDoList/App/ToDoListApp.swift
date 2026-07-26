//
//  ToDoListApp.swift
//  ToDoList
//
//  Created by Kade Walter on 7/23/26.
//

import SwiftUI

@main
struct ToDoListApp: App {
    @State private var viewModel = ToDoListViewModel(taskRepository: TaskRepository())
    
    var body: some Scene {
        WindowGroup {
            ToDoListView(viewModel: viewModel)
        }
    }
}
