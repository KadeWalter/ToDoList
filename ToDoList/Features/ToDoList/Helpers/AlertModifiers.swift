//
//  AlertModifiers.swift
//  ToDoList
//
//  Created by Kade Walter on 7/24/26.
//

import SwiftUI

/// Presents a "New Task" alert with a title field.
struct AddTaskAlertModifier: ViewModifier {
    @State private var title = ""
    @Binding var isPresented: Bool
    let onAdd: (String) -> Void

    func body(content: Content) -> some View {
        content.alert("New Task", isPresented: $isPresented) {
            TextField("Title", text: $title)
            Button("Add") {
                onAdd(title)
                title = ""
            }
            Button("Cancel", role: .cancel) {
                title = ""
            }
        }
    }
}

/// Presents an error alert whenever `message` is non-nil.
struct ErrorAlertModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content.alert(
            "Something went wrong",
            isPresented: $message.isPresent(),
            presenting: message
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { text in
            Text(text)
        }
    }
}

/// Confirms a destructive "delete all" before invoking `onConfirm`.
struct DeleteAllTasksConfirmationModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content.alert("Delete all tasks?", isPresented: $isPresented) {
            Button("Delete All", role: .destructive, action: onConfirm)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes every task and can't be undone.")
        }
    }
}

extension View {
    func addTaskAlert(
        isPresented: Binding<Bool>,
        onAdd: @escaping (String) -> Void
    ) -> some View {
        modifier(AddTaskAlertModifier(isPresented: isPresented, onAdd: onAdd))
    }

    func errorAlert(message: Binding<String?>) -> some View {
        modifier(ErrorAlertModifier(message: message))
    }

    func deleteAllTasksConfirmationAlert(
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(DeleteAllTasksConfirmationModifier(isPresented: isPresented, onConfirm: onConfirm))
    }
}
