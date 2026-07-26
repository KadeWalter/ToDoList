//
//  Binding+Extension.swift
//  ToDoList
//
//  Created by Kade Walter on 7/25/26.
//

import SwiftUI

extension Binding {
    /// Bridges an optional-value binding to a `Bool` binding for presentation
    /// APIs (`alert`, `sheet`, `confirmationDialog`, …): reads `true` while the
    /// value is non-nil, and clears the value to `nil` on dismissal.
    func isPresent<Wrapped>() -> Binding<Bool> where Value == Wrapped? {
        Binding<Bool>(
            get: { wrappedValue != nil },
            set: { isPresented in
                if !isPresented { wrappedValue = nil }
            }
        )
    }
}
