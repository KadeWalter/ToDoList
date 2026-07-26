//
//  RemoteTaskTests.swift
//  ToDoListTests
//

import XCTest
import Foundation
@testable import ToDoList

final class RemoteTaskTests: XCTestCase {

    func testDecodesSingleObjectFromTodosJSON() throws {
        let json = Data("""
        { "userId": 7, "id": 42, "title": "delectus aut autem", "completed": true }
        """.utf8)
        let task = try JSONDecoder().decode(RemoteTask.self, from: json)
        XCTAssertEqual(task.id, 42)
        XCTAssertEqual(task.userId, 7)
        XCTAssertEqual(task.title, "delectus aut autem")
        XCTAssertTrue(task.completed)
    }

    func testDecodesArray() throws {
        let json = Data("""
        [ { "userId": 1, "id": 1, "title": "a", "completed": false },
          { "userId": 1, "id": 2, "title": "b", "completed": true } ]
        """.utf8)
        let tasks = try JSONDecoder().decode([RemoteTask].self, from: json)
        XCTAssertEqual(tasks.count, 2)
        XCTAssertEqual(tasks[1].id, 2)
    }

    func testToModelMapsFieldsAndPreservesServerIdentity() {
        let task = RemoteTask(id: 99, userId: 5, title: "Task", completed: true)
        let model = task.toModel()
        XCTAssertEqual(model.title, "Task")
        XCTAssertTrue(model.completed)
        XCTAssertEqual(model.remoteID, 99)
        XCTAssertEqual(model.userId, 5)
    }

    func testDecodesEmptyArray() throws {
        let tasks = try JSONDecoder().decode([RemoteTask].self, from: Data("[]".utf8))
        XCTAssertTrue(tasks.isEmpty)
    }

    func testDecodeThrowsWhenRequiredFieldIsMissing() {
        let json = Data("""
        { "userId": 1, "id": 1, "completed": false }
        """.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(RemoteTask.self, from: json))
    }

    func testDecodeThrowsWhenFieldHasWrongType() {
        let json = Data("""
        { "userId": 1, "id": "not-a-number", "title": "a", "completed": false }
        """.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(RemoteTask.self, from: json))
    }

    func testDecodeIgnoresUnknownFields() throws {
        // The API adding a field shouldn't break the client.
        let json = Data("""
        { "userId": 1, "id": 1, "title": "a", "completed": false, "dueDate": "2026-01-01" }
        """.utf8)
        let task = try JSONDecoder().decode(RemoteTask.self, from: json)
        XCTAssertEqual(task.id, 1)
    }

    func testToModelGeneratesADistinctLocalIDPerCall() {
        let remote = RemoteTask(id: 1, userId: 1, title: "a", completed: false)

        XCTAssertNotEqual(remote.toModel().id, remote.toModel().id)
        XCTAssertEqual(remote.toModel().remoteID, remote.toModel().remoteID)
    }

    func testToModelPreservesEmptyTitle() {
        let model = RemoteTask(id: 1, userId: 1, title: "", completed: false).toModel()
        XCTAssertEqual(model.title, "")
    }

    func testToModelTrimsSurroundingWhitespace() {
        let model = RemoteTask(id: 1, userId: 1, title: "  padded  ", completed: false).toModel()
        XCTAssertEqual(model.title, "padded")
    }

    func testToModelCollapsesWhitespaceOnlyTitleToEmpty() {
        // Which is what makes `hasValidTitle` catch it downstream in the repository.
        let model = RemoteTask(id: 1, userId: 1, title: " \n\t ", completed: false).toModel()
        XCTAssertEqual(model.title, "")
        XCTAssertFalse(model.hasValidTitle)
    }

    func testToModelPreservesInteriorSpacing() {
        let model = RemoteTask(id: 1, userId: 1, title: "buy  the  milk", completed: false).toModel()
        XCTAssertEqual(model.title, "buy  the  milk")
    }
}
