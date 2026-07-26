//
//  TaskItem.swift
//  ToDoList
//
//  Created by Kade Walter on 7/23/26.
//

import Foundation
import CoreData

/// Managed object subclass for the `TaskItem` entity — the Core Data persistence
/// record. Domain behavior lives on the value type `TaskModel`; this type only
/// guarantees stored-record defaults. Mapping between the two lives in
/// `TaskItem+TaskModel.swift`.
@objc(TaskItem)
public class TaskItem: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskItem> {
        NSFetchRequest<TaskItem>(entityName: "TaskItem")
    }

    @NSManaged public var id: UUID
    @NSManaged public var remoteID: NSNumber?
    @NSManaged public var userId: NSNumber?
    @NSManaged public var completed: Bool
    @NSManaged public var title: String

    /// Defaults applied to every newly inserted record
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        completed = false
    }
}

extension TaskItem: Identifiable {}
