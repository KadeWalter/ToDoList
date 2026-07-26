//
//  PersistenceController.swift
//  ToDoList
//
//  Created by Kade Walter on 7/23/26.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    private let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ToDoList")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    var viewContext: NSManagedObjectContext { container.viewContext }

    /// Saves the context (defaults to the view context) only when it has pending
    /// changes. Throws instead of crashing so callers can handle failure.
    func save(_ context: NSManagedObjectContext? = nil) throws {
        let context = context ?? viewContext
        guard context.hasChanges else { return }
        try context.save()
    }
}
