//
//  ToDoListView.swift
//  ToDoList
//
//  Created by Kade Walter on 7/23/26.
//

import SwiftUI

struct ToDoListView: View {
    @Bindable var viewModel: ToDoListViewModel
    @State private var isAddingTask = false
    @State private var isConfirmingDeleteAll = false
    
    var body: some View {
        NavigationStack {
            mainContent
                .padding()
                .navigationTitle("Tasks")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarButtons
                }
                .addTaskAlert(isPresented: $isAddingTask) { title in
                    viewModel.addTask(title: title)
                }
                .deleteAllTasksConfirmationAlert(isPresented: $isConfirmingDeleteAll) {
                    viewModel.deleteAllTasks()
                }
                .errorAlert(message: $viewModel.errorMessage)
                .onAppear {
                    viewModel.loadTasks()
                }
        }
    }
}
 
// MARK: - Task list
extension ToDoListView {
    private var mainContent: some View {
        VStack(spacing: 20) {
            if viewModel.tasks.isEmpty {
                Text("Add your first task!")
                Spacer()
            } else {
                taskList
            }
            requestDemoTasksButton
        }
    }
    
    private var taskList: some View {
        List {
            ForEach(viewModel.tasks) { task in
                taskRow(for: task)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
    }

    private func taskRow(for task: TaskModel) -> some View {
        TaskItemView(
            viewModel: TaskItemViewModel(task: task) { updatedTask in
                viewModel.updateTask(updatedTask)
            }
        )
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        .listRowBackground(Color.clear)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.deleteTask(task)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Button views
extension ToDoListView {
    private var addButton: some View {
        Button {
            isAddingTask = true
        } label: {
            Label("Add", systemImage: "plus")
        }
    }
    
    private var deleteAllTasksButton: some View {
        Button {
            isConfirmingDeleteAll = true
        } label: {
            Label("Delete all", systemImage: "trash")
        }
    }

    private var toolbarButtons: some View {
        HStack {
            addButton
            if !viewModel.tasks.isEmpty {
                deleteAllTasksButton
            }
        }
    }

    private var requestDemoTasksButton: some View {
        Button {
            Task {
                await viewModel.fetchRemoteTasks()
            }
        } label: {
            if viewModel.loadingState.isLoading {
                ProgressView()
            } else {
                Text("Request Demo Tasks")
            }
        }
        .buttonStyle(.glass)
        .disabled(viewModel.loadingState.isLoading)
    }
}

#Preview {
    ToDoListView(viewModel: .preview())
}
