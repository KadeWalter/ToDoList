//
//  TaskRepositoryTests.swift
//  ToDoListTests
//

import XCTest
import Foundation
@testable import ToDoList

@MainActor
final class TaskRepositoryTests: XCTestCase {

    private func makeSUT(
        remote: MockTaskDataSource = MockTaskDataSource(),
        store: MockTaskStore? = nil
    ) -> TaskRepository {
        TaskRepository(remote: remote, store: store ?? MockTaskStore())
    }

    func testFetchTasksDelegatesToStore() async throws {
        let store = MockTaskStore()
        store.storedTasks = [TaskModel(title: "A")]
        let sut = makeSUT(store: store)
        XCTAssertEqual(try sut.fetchTasks().count, 1)
    }

    func testRefreshTasksGetsMapsSavesAndReturnsLocal() async throws {
        let remote = MockTaskDataSource()
        remote.remoteTasks = [
            RemoteTask(id: 1, userId: 1, title: "A", completed: false),
            RemoteTask(id: 2, userId: 1, title: "B", completed: true)
        ]
        let store = MockTaskStore()
        let sut = makeSUT(remote: remote, store: store)

        let result = try await sut.refreshTasks()

        XCTAssertEqual(remote.getRemoteTasksCallCount, 1)
        XCTAssertEqual(store.savedBatches.count, 1)
        XCTAssertEqual(store.savedBatches.first?.map(\.remoteID), [1, 2])
        XCTAssertEqual(result.count, 2)
    }

    func testRefreshTasksPropagatesRemoteError() async {
        let remote = MockTaskDataSource()
        remote.errorToThrow = APIErrors.invalidResponse
        let sut = makeSUT(remote: remote)

        await XCTAssertThrowsErrorAsync(try await sut.refreshTasks()) { error in
            XCTAssertEqual(error as? APIErrors, .invalidResponse)
        }
    }

    func testCreateTaskDelegatesToStore() async throws {
        let store = MockTaskStore()
        let sut = makeSUT(store: store)
        _ = try sut.createTask(title: "New")
        XCTAssertEqual(store.storedTasks.map(\.title), ["New"])
    }

    func testUpdateDelegatesToStore() async throws {
        let store = MockTaskStore()
        let task = TaskModel(title: "T")
        store.storedTasks = [task]
        let sut = makeSUT(store: store)

        var edited = task
        edited.toggleCompleted()
        try sut.update(edited)

        XCTAssertTrue(store.storedTasks.first!.completed)
    }

    func testDeleteAndDeleteAllDelegateToStore() async throws {
        let store = MockTaskStore()
        let a = TaskModel(title: "A")
        store.storedTasks = [a, TaskModel(title: "B")]
        let sut = makeSUT(store: store)

        try sut.deleteTask(id: a.id)
        XCTAssertEqual(store.storedTasks.map(\.title), ["B"])

        try sut.deleteAllTasks()
        XCTAssertTrue(store.storedTasks.isEmpty)
    }

    func testRefreshTasksWithEmptyRemoteStillSavesAndReturnsStoreContents() async throws {
        let remote = MockTaskDataSource()
        remote.remoteTasks = []
        let store = MockTaskStore()
        let sut = makeSUT(remote: remote, store: store)

        let result = try await sut.refreshTasks()

        XCTAssertEqual(store.savedBatches.count, 1)
        XCTAssertTrue(try XCTUnwrap(store.savedBatches.first).isEmpty)
        XCTAssertTrue(result.isEmpty)
    }

    func testRefreshTasksPropagatesStoreError() async {
        let remote = MockTaskDataSource()
        remote.remoteTasks = [RemoteTask(id: 1, userId: 1, title: "A", completed: false)]
        let store = MockTaskStore()
        store.errorToThrow = TestError.boom
        let sut = makeSUT(remote: remote, store: store)

        await XCTAssertThrowsErrorAsync(try await sut.refreshTasks()) { error in
            XCTAssertEqual(error as? TestError, .boom)
        }
    }

    func testRefreshTasksDoesNotSaveWhenRemoteFails() async {
        let remote = MockTaskDataSource()
        remote.errorToThrow = APIErrors.invalidResponse
        let store = MockTaskStore()
        let sut = makeSUT(remote: remote, store: store)

        await XCTAssertThrowsErrorAsync(try await sut.refreshTasks())

        XCTAssertTrue(store.savedBatches.isEmpty)
    }

    func testCreateTaskPropagatesStoreError() async {
        let store = MockTaskStore()
        store.errorToThrow = TestError.boom
        let sut = makeSUT(store: store)

        XCTAssertThrowsError(try sut.createTask(title: "New")) { error in
            XCTAssertEqual(error as? TestError, .boom)
        }
    }

    func testCreateTaskRejectsEmptyTitle() async {
        let store = MockTaskStore()
        let sut = makeSUT(store: store)

        XCTAssertThrowsError(try sut.createTask(title: "")) { error in
            XCTAssertEqual(error as? TaskValidationError, .emptyTitle)
        }
        XCTAssertTrue(store.storedTasks.isEmpty)
    }

    func testCreateTaskRejectsWhitespaceOnlyTitle() async {
        let store = MockTaskStore()
        let sut = makeSUT(store: store)

        for title in ["   ", "\n", "\t", " \n\t "] {
            XCTAssertThrowsError(try sut.createTask(title: title)) { error in
                XCTAssertEqual(error as? TaskValidationError, .emptyTitle)
            }
        }
        XCTAssertTrue(store.storedTasks.isEmpty)
    }

    func testCreateTaskTrimsBeforeReachingTheStore() async throws {
        let store = MockTaskStore()
        let sut = makeSUT(store: store)

        _ = try sut.createTask(title: "  Buy milk  ")

        XCTAssertEqual(store.storedTasks.map(\.title), ["Buy milk"])
    }

    func testRefreshTasksDropsRemoteTasksWithEmptyTitles() async throws {
        let remote = MockTaskDataSource()
        remote.remoteTasks = [
            RemoteTask(id: 1, userId: 1, title: "Keep me", completed: false),
            RemoteTask(id: 2, userId: 1, title: "", completed: false),
            RemoteTask(id: 3, userId: 1, title: "   ", completed: true),
            RemoteTask(id: 4, userId: 1, title: "Keep me too", completed: false)
        ]
        let store = MockTaskStore()
        let sut = makeSUT(remote: remote, store: store)

        _ = try await sut.refreshTasks()

        let saved = try XCTUnwrap(store.savedBatches.first)
        XCTAssertEqual(saved.map(\.title), ["Keep me", "Keep me too"])
        XCTAssertEqual(saved.map(\.remoteID), [1, 4])
    }

    func testRefreshTasksTrimsRemoteTitlesLikeTheLocalCreatePath() async throws {
        let remote = MockTaskDataSource()
        remote.remoteTasks = [RemoteTask(id: 1, userId: 1, title: "  padded  ", completed: false)]
        let store = MockTaskStore()
        let sut = makeSUT(remote: remote, store: store)

        _ = try await sut.refreshTasks()
        
        XCTAssertEqual(try XCTUnwrap(store.savedBatches.first).map(\.title), ["padded"])
    }

    func testRefreshTasksWithOnlyUntitledRemoteTasksSavesNothing() async throws {
        let remote = MockTaskDataSource()
        remote.remoteTasks = [
            RemoteTask(id: 1, userId: 1, title: "", completed: false),
            RemoteTask(id: 2, userId: 1, title: " ", completed: false)
        ]
        let store = MockTaskStore()
        let sut = makeSUT(remote: remote, store: store)

        let result = try await sut.refreshTasks()

        XCTAssertTrue(try XCTUnwrap(store.savedBatches.first).isEmpty)
        XCTAssertTrue(result.isEmpty)
    }

    func testMutatingCallsNeverTouchTheRemoteSource() async throws {
        let remote = MockTaskDataSource()
        let store = MockTaskStore()
        let sut = makeSUT(remote: remote, store: store)

        let task = try sut.createTask(title: "A")
        try sut.update(task)
        try sut.deleteTask(id: task.id)
        try sut.deleteAllTasks()

        XCTAssertEqual(remote.getRemoteTasksCallCount, 0)
    }
}
