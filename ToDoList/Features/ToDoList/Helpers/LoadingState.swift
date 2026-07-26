//
//  LoadingState.swift
//  ToDoList
//
//  Created by Kade Walter on 7/24/26.
//

enum LoadingState {
    case loading
    case loaded
    case failed

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
}
