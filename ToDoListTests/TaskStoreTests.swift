//
//  TaskStoreTests.swift
//  ToDoListTests
//
//  Exercises the real Core Data logic against an in-memory store.
//

import XCTest
import Foundation
@testable import ToDoList

@MainActor
final class TaskStoreTests: XCTestCase {
    
    private var sut: TaskStore!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = TaskStore(persistence: PersistenceController(inMemory: true))
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    func testCreateTaskPersistsWithDefaults() async throws {
        let created = try sut.createTask(title: "Buy milk")

        let tasks = try sut.fetchTasks()
        XCTAssertEqual(tasks.count, 1)
        let task = tasks.first!
        XCTAssertEqual(task.id, created.id)
        XCTAssertEqual(task.title, "Buy milk")
        XCTAssertFalse(task.completed)
        XCTAssertNil(task.remoteID)
    }

    func testFetchTasksSortsByTitle() async throws {
        try sut.createTask(title: "Banana")
        try sut.createTask(title: "Apple")
        try sut.createTask(title: "Cherry")

        XCTAssertEqual(try sut.fetchTasks().map(\.title), ["Apple", "Banana", "Cherry"])
    }

    func testUpdatePersistsAndKeepsIdentity() async throws {
        var task = try sut.createTask(title: "T")
        task.toggleCompleted()
        try sut.update(task)

        let fetched = try sut.fetchTasks().first!
        XCTAssertTrue(fetched.completed)
        XCTAssertEqual(fetched.id, task.id)
    }

    func testUpdateThrowsForMissingTask() async {
        XCTAssertThrowsError(try sut.update(TaskModel(title: "ghost"))) { error in
            XCTAssertTrue(error is TaskStoreError)
        }
    }

    func testDeleteRemovesOnlyTheTarget() async throws {
        let a = try sut.createTask(title: "A")
        try sut.createTask(title: "B")

        try sut.deleteTask(id: a.id)

        XCTAssertEqual(try sut.fetchTasks().map(\.title), ["B"])
    }

    func testDeleteAllRemovesEverything() async throws {
        try sut.createTask(title: "A")
        try sut.createTask(title: "B")

        try sut.deleteAllTasks()

        XCTAssertTrue(try sut.fetchTasks().isEmpty)
    }

    func testSaveInsertsRemoteBatch() async throws {
        try sut.save([
            TaskModel(title: "A", remoteID: 1),
            TaskModel(title: "B", remoteID: 2)
        ])
        XCTAssertEqual(try sut.fetchTasks().count, 2)
    }

    func testSaveDeduplicatesByRemoteID() async throws {
        try sut.save([TaskModel(title: "A", remoteID: 1)])
        try sut.save([TaskModel(title: "A-updated", remoteID: 1)])

        let tasks = try sut.fetchTasks()
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first!.title, "A-updated")
    }

    func testSaveKeepsLocalCompletionOnExistingTasks() async throws {
        let fakeRemoteTasks = [TaskModel(title: "A", completed: true, remoteID: 1)]
        try sut.save(fakeRemoteTasks)
        var task = try XCTUnwrap(sut.fetchTasks().first)
        task.toggleCompleted()
        try sut.update(task)
        try sut.save(fakeRemoteTasks)

        XCTAssertFalse(try XCTUnwrap(sut.fetchTasks().first).completed)
    }

    func testSaveAppliesCompletionToNewTasks() async throws {
        try sut.save([TaskModel(title: "A", completed: true, remoteID: 1)])

        XCTAssertTrue(try XCTUnwrap(sut.fetchTasks().first).completed)
    }

    func testSaveDeduplicatesWithinASingleBatch() async throws {
        try sut.save([
            TaskModel(title: "First", remoteID: 1),
            TaskModel(title: "Second", remoteID: 1)
        ])
        XCTAssertEqual(try sut.fetchTasks().count, 1)
    }

    func testFetchTasksOnEmptyStoreReturnsEmpty() async throws {
        XCTAssertTrue(try sut.fetchTasks().isEmpty)
    }

    func testFetchTasksSortsCaseSensitively() async throws {
        try sut.createTask(title: "apple")
        try sut.createTask(title: "Banana")
        
        XCTAssertEqual(try sut.fetchTasks().map(\.title), ["Banana", "apple"])
    }

    func testCreateTaskAllowsDuplicateTitlesWithDistinctIDs() async throws {
        let first = try sut.createTask(title: "Same")
        let second = try sut.createTask(title: "Same")

        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(try sut.fetchTasks().count, 2)
    }

    func testUpdatePreservesRemoteIdentity() async throws {
        try sut.save([TaskModel(title: "A", remoteID: 7, userId: 3)])
        var task = try XCTUnwrap(sut.fetchTasks().first)

        task.toggleCompleted()
        try sut.update(task)

        let updated = try XCTUnwrap(sut.fetchTasks().first)
        XCTAssertTrue(updated.completed)
        XCTAssertEqual(updated.remoteID, 7)
        XCTAssertEqual(updated.userId, 3)
    }

    func testDeleteTaskWithUnknownIDDoesNothing() async throws {
        try sut.createTask(title: "A")

        XCTAssertNoThrow(try sut.deleteTask(id: UUID()))
        XCTAssertEqual(try sut.fetchTasks().map(\.title), ["A"])
    }

    func testDeleteAllOnEmptyStoreDoesNotThrow() async throws {
        XCTAssertNoThrow(try sut.deleteAllTasks())
        XCTAssertTrue(try sut.fetchTasks().isEmpty)
    }

    func testSaveWithEmptyBatchLeavesStoreUntouched() async throws {
        try sut.createTask(title: "Local")

        try sut.save([])

        XCTAssertEqual(try sut.fetchTasks().map(\.title), ["Local"])
    }

    func testSaveLeavesLocallyCreatedTasksUntouched() async throws {
        let local = try sut.createTask(title: "Buy milk")

        try sut.save([TaskModel(title: "Remote", remoteID: 1)])

        let tasks = try sut.fetchTasks()
        XCTAssertEqual(tasks.count, 2)
        let survivor = try XCTUnwrap(tasks.first { $0.id == local.id })
        XCTAssertEqual(survivor.title, "Buy milk")
        XCTAssertNil(survivor.remoteID)
    }

    func testSaveHandlesBatchOfBothNewAndExistingTasks() async throws {
        try sut.save([TaskModel(title: "A", remoteID: 1)])

        try sut.save([
            TaskModel(title: "A-updated", remoteID: 1),
            TaskModel(title: "B", remoteID: 2)
        ])

        XCTAssertEqual(try sut.fetchTasks().map(\.title), ["A-updated", "B"])
    }

    func testSaveTreatsTasksWithoutRemoteIDAsNewInserts() async throws {
        // Nothing to match on, so an identical batch inserts again. `refreshTasks`
        // never takes this path — every RemoteTask carries an id — but the behavior
        // is worth pinning down in case a caller ever passes local models here.
        let batch = [TaskModel(title: "No remote id")]
        try sut.save(batch)
        try sut.save(batch)

        XCTAssertEqual(try sut.fetchTasks().count, 2)
    }
}
