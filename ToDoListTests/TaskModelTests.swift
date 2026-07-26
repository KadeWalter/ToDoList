//
//  TaskModelTests.swift
//  ToDoListTests
//

import XCTest
import Foundation
@testable import ToDoList

final class TaskModelTests: XCTestCase {

    func testInitAppliesDefaults() {
        let task = TaskModel(title: "Buy milk")
        XCTAssertEqual(task.title, "Buy milk")
        XCTAssertFalse(task.completed)
        XCTAssertNil(task.remoteID)
        XCTAssertNil(task.userId)
    }

    func testInitGeneratesUniqueIDs() {
        XCTAssertNotEqual(TaskModel(title: "A").id, TaskModel(title: "B").id)
    }

    func testToggleCompletedFlipsFalseToTrue() {
        var task = TaskModel(title: "T", completed: false)
        task.toggleCompleted()
        XCTAssertTrue(task.completed)
    }

    func testToggleCompletedFlipsTrueToFalse() {
        var task = TaskModel(title: "T", completed: true)
        task.toggleCompleted()
        XCTAssertFalse(task.completed)
    }

    func testEquatableConsidersAllFields() {
        let id = UUID()
        let a = TaskModel(id: id, title: "T", completed: false, remoteID: 1, userId: 2)
        let b = TaskModel(id: id, title: "T", completed: false, remoteID: 1, userId: 2)
        XCTAssertEqual(a, b)

        var c = a
        c.completed = true
        XCTAssertNotEqual(a, c)
    }

    func testToggleCompletedTwiceReturnsToOriginalValue() {
        var task = TaskModel(title: "T", completed: false)
        task.toggleCompleted()
        task.toggleCompleted()
        XCTAssertFalse(task.completed)
    }

    func testIdenticalContentWithDifferentIDsIsNotEqual() {
        let a = TaskModel(title: "T", completed: true, remoteID: 1, userId: 2)
        let b = TaskModel(title: "T", completed: true, remoteID: 1, userId: 2)
        XCTAssertNotEqual(a, b, "Identity is the UUID, not the contents")
    }

    func testEquatableDistinguishesNilFromPresentRemoteIdentity() {
        let id = UUID()
        let local = TaskModel(id: id, title: "T")
        let synced = TaskModel(id: id, title: "T", remoteID: 1, userId: 1)
        XCTAssertNotEqual(local, synced)
    }

    func testHasValidTitleRejectsBlankAndWhitespaceOnlyTitles() {
        for title in ["", " ", "   ", "\n", "\t", " \n\t "] {
            XCTAssertFalse(
                TaskModel(title: title).hasValidTitle,
                "Expected \(title.debugDescription) to be rejected"
            )
        }
    }

    func testHasValidTitleAcceptsAnyNonWhitespaceContent() {
        for title in ["A", "  padded  ", "🎉", "0"] {
            XCTAssertTrue(
                TaskModel(title: title).hasValidTitle,
                "Expected \(title.debugDescription) to be accepted"
            )
        }
    }

    func testSanitizeStripsSurroundingWhitespaceOnly() {
        XCTAssertEqual(TaskModel.sanitize("  Buy milk  "), "Buy milk")
        XCTAssertEqual(TaskModel.sanitize("Buy  milk"), "Buy  milk", "Interior spacing is preserved")
        XCTAssertEqual(TaskModel.sanitize("\n\tBuy milk\n"), "Buy milk")
        XCTAssertEqual(TaskModel.sanitize("   "), "")
    }

    func testInitDoesNotTrimOrRejectTitles() {
        // Validation lives in ToDoListViewModel.addTask; the model stores whatever
        // it is handed, which is what lets remote titles round-trip verbatim.
        XCTAssertEqual(TaskModel(title: "  padded  ").title, "  padded  ")
        XCTAssertEqual(TaskModel(title: "").title, "")
    }

    func testMutatingACopyLeavesTheOriginalUntouched() {
        let original = TaskModel(title: "T", completed: false)
        var copy = original
        copy.toggleCompleted()
        copy.title = "Changed"

        XCTAssertFalse(original.completed)
        XCTAssertEqual(original.title, "T")
        XCTAssertEqual(copy.id, original.id)
    }
}
