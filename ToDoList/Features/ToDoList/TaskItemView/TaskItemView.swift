//
//  TaskItemView.swift
//  ToDoList
//
//  Created by Kade Walter on 7/24/26.
//

import SwiftUI

struct TaskItemView: View {
    let viewModel: TaskItemViewModel
    
    var body: some View {
        HStack(spacing: 15) {
            checkbox
            taskTitle
            Spacer()
        }
    }
    
    private var taskTitle: some View {
        Text(viewModel.task.title)
            .font(.headline)
    }
    
    @ViewBuilder
    private var checkbox: some View {
        let color: Color = viewModel.task.completed ? .greenPrimary : .clear
        let accentColor: Color = viewModel.task.completed ? .greenAccent : .primary
        ZStack {
            RoundedRectangle(cornerRadius: 8.0)
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay {
                    RoundedRectangle(cornerRadius: 8.0)
                        .strokeBorder(accentColor, lineWidth: 2)
                }
                .onTapGesture {
                    viewModel.updateTaskCompleted()
                }
            
            if viewModel.task.completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                    .foregroundStyle(accentColor)
            }
        }
    }
}

#Preview {
    TaskItemView(
        viewModel: TaskItemViewModel(
            task: TaskModel(title: "Buy groceries"),
            onUpdate: { _ in }
        )
    )
}
