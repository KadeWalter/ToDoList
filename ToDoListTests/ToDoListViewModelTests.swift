//
//  ToDoListViewModelTests.swift
//  ToDoListTests
//

import XCTest
import Foundation
@testable import ToDoList

@MainActor
final class ToDoListViewModelTests: XCTestCase {

    func testLoadTasksPopulatesTasks() async {
        let repo = MockTaskRepository()
        repo.localTasks = [TaskModel(title: "A"), TaskModel(title: "B")]
        let sut = ToDoListViewModel(taskRepository: repo)

        sut.loadTasks()

        XCTAssertEqual(sut.tasks.count, 2)
        XCTAssertNil(sut.errorMessage)
    }

    func testLoadTasksSetsErrorMessageOnFailure() async {
        let repo = MockTaskRepository()
        repo.errorToThrow = TestError.boom
        let sut = ToDoListViewModel(taskRepository: repo)

        sut.loadTasks()

        XCTAssertNotNil(sut.errorMessage)
    }

    func testFetchRemoteTasksTransitionsToLoadedWithTasks() async {
        let repo = MockTaskRepository()
        repo.remoteTasks = [TaskModel(title: "A")]
        let sut = ToDoListViewModel(taskRepository: repo)

        await sut.fetchRemoteTasks()

        XCTAssertEqual(sut.tasks.count, 1)
        XCTAssertFalse(sut.loadingState.isLoading)
        if case .loaded = sut.loadingState {} else {
            XCTFail("Expected .loaded, got \(sut.loadingState)")
        }
    }

    func testFetchRemoteTasksTransitionsToFailedOnError() async {
        let repo = MockTaskRepository()
        repo.errorToThrow = TestError.boom
        let sut = ToDoListViewModel(taskRepository: repo)

        await sut.fetchRemoteTasks()

        if case .failed = sut.loadingState {} else {
            XCTFail("Expected .failed, got \(sut.loadingState)")
        }
        XCTAssertNotNil(sut.errorMessage)
    }

    func testAddTaskCreatesAndReloads() async {
        let repo = MockTaskRepository()
        let sut = ToDoListViewModel(taskRepository: repo)

        sut.addTask(title: "New task")

        XCTAssertEqual(repo.createdTitles, ["New task"])
        XCTAssertEqual(sut.tasks.map(\.title), ["New task"])
    }

    func testAddTaskIgnoresBlankTitle() async {
        let repo = MockTaskRepository()
        let sut = ToDoListViewModel(taskRepository: repo)

        sut.addTask(title: "    ")

        XCTAssertTrue(repo.createdTitles.isEmpty)
        XCTAssertTrue(sut.tasks.isEmpty)
    }

    func testAddTaskTrimsWhitespace() async {
        let repo = MockTaskRepository()
        let sut = ToDoListViewModel(taskRepository: repo)

        sut.addTask(title: "  Trimmed  ")

        XCTAssertEqual(repo.createdTitles, ["Trimmed"])
    }

    func testUpdatePersistsAndReflectsInList() async {
        let repo = MockTaskRepository()
        var task = TaskModel(title: "T", completed: false)
        repo.localTasks = [task]
        let sut = ToDoListViewModel(taskRepository: repo)
        sut.loadTasks()

        task.toggleCompleted()
        sut.updateTask(task)

        XCTAssertEqual(repo.updatedTasks.count, 1)
        XCTAssertTrue(sut.tasks.first!.completed)
    }

    func testDeleteRemovesTaskLocallyAndRemotely() async {
        let repo = MockTaskRepository()
        let task = TaskModel(title: "T")
        repo.localTasks = [task]
        let sut = ToDoListViewModel(taskRepository: repo)
        sut.loadTasks()

        sut.deleteTask(task)

        XCTAssertEqual(repo.deletedIDs, [task.id])
        XCTAssertTrue(sut.tasks.isEmpty)
    }

    func testDeleteAllClearsTasks() async {
        let repo = MockTaskRepository()
        repo.localTasks = [TaskModel(title: "A"), TaskModel(title: "B")]
        let sut = ToDoListViewModel(taskRepository: repo)
        sut.loadTasks()

        sut.deleteAllTasks()

        XCTAssertEqual(repo.deleteAllCallCount, 1)
        XCTAssertTrue(sut.tasks.isEmpty)
    }

    func testAddTaskIgnoresNewlineOnlyTitle() async {
        let repo = MockTaskRepository()
        let sut = ToDoListViewModel(taskRepository: repo)

        sut.addTask(title: "\n\t ")

        XCTAssertTrue(repo.createdTitles.isEmpty)
        XCTAssertTrue(sut.tasks.isEmpty)
    }

    func testAddTaskIgnoresBlankTitleWithoutRaisingAnError() async {
        let repo = MockTaskRepository()
        let sut = ToDoListViewModel(taskRepository: repo)

        for title in ["", "   ", "\n\t"] {
            sut.addTask(title: title)
        }

        XCTAssertTrue(repo.createdTitles.isEmpty)
        XCTAssertNil(sut.errorMessage)
    }

    func testAddTaskSetsErrorMessageAndLeavesListUnchangedOnFailure() async {
        let (sut, _) = makeLoadedSUT(tasks: [TaskModel(title: "Existing")])

        sut.addTask(title: "New")

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.tasks.map(\.title), ["Existing"])
    }

    func testUpdateTaskSetsErrorMessageAndLeavesListUnchangedOnFailure() async {
        var task = TaskModel(title: "T", completed: false)
        let (sut, _) = makeLoadedSUT(tasks: [task])

        task.toggleCompleted()
        sut.updateTask(task)

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.tasks.first!.completed)
    }

    func testUpdateTaskForUnknownTaskLeavesListUnchanged() async {
        let repo = MockTaskRepository()
        repo.localTasks = [TaskModel(title: "A")]
        let sut = ToDoListViewModel(taskRepository: repo)
        sut.loadTasks()

        sut.updateTask(TaskModel(title: "Ghost", completed: true))

        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.tasks.map(\.title), ["A"])
    }

    func testDeleteTaskKeepsTaskInListOnFailure() async {
        let task = TaskModel(title: "T")
        let (sut, _) = makeLoadedSUT(tasks: [task])

        sut.deleteTask(task)

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.tasks.count, 1)
    }

    func testDeleteAllKeepsTasksOnFailure() async {
        let (sut, _) = makeLoadedSUT(tasks: [TaskModel(title: "A"), TaskModel(title: "B")])

        sut.deleteAllTasks()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.tasks.count, 2)
    }

    func testLoadTasksKeepsPreviousTasksOnFailure() async {
        let (sut, _) = makeLoadedSUT(tasks: [TaskModel(title: "A")])

        sut.loadTasks()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.tasks.map(\.title), ["A"])
    }

    func testFetchRemoteTasksKeepsPreviousTasksOnFailure() async {
        let (sut, _) = makeLoadedSUT(tasks: [TaskModel(title: "A")])

        await sut.fetchRemoteTasks()

        XCTAssertEqual(sut.tasks.map(\.title), ["A"])
        if case .failed = sut.loadingState {} else {
            XCTFail("Expected .failed, got \(sut.loadingState)")
        }
    }

    func testFetchRemoteTasksWithEmptyResponseClearsList() async {
        let repo = MockTaskRepository()
        repo.localTasks = [TaskModel(title: "Stale")]
        let sut = ToDoListViewModel(taskRepository: repo)
        sut.loadTasks()

        repo.remoteTasks = []
        await sut.fetchRemoteTasks()

        XCTAssertTrue(sut.tasks.isEmpty)
        XCTAssertFalse(sut.loadingState.isLoading)
    }

    func testFetchRemoteTasksLeavesStaleErrorMessageAfterRecovery() async {
        let (sut, repo) = makeLoadedSUT(tasks: [])
        await sut.fetchRemoteTasks()
        XCTAssertNotNil(sut.errorMessage)

        // A later success restores `loadingState` but does not clear `errorMessage`.
        repo.errorToThrow = nil
        repo.remoteTasks = [TaskModel(title: "A")]
        await sut.fetchRemoteTasks()

        XCTAssertEqual(sut.tasks.count, 1)
        XCTAssertNotNil(sut.errorMessage)
    }
}

// MARK: Helper Function
extension ToDoListViewModelTests {
    /// Loads `tasks` through the repository, then arms it to fail every later call.
    private func makeLoadedSUT(
        tasks: [TaskModel]
    ) -> (ToDoListViewModel, MockTaskRepository) {
        let repo = MockTaskRepository()
        repo.localTasks = tasks
        let sut = ToDoListViewModel(taskRepository: repo)
        sut.loadTasks()
        repo.errorToThrow = TestError.boom
        return (sut, repo)
    }
}
