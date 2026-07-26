//
//  TaskItemViewModelTests.swift
//  ToDoListTests
//

import XCTest
import Foundation
@testable import ToDoList

@MainActor
final class TaskItemViewModelTests: XCTestCase {

    func testUpdateTaskCompletedTogglesToCompletedAndReportsUp() async {
        let task = TaskModel(title: "T", completed: false)
        let recorder = UpdateRecorder()
        let sut = TaskItemViewModel(task: task) { recorder.task = $0 }

        sut.updateTaskCompleted()

        XCTAssertEqual(recorder.task!.id, task.id)
        XCTAssertTrue(recorder.task!.completed)
    }

    func testUpdateTaskCompletedTogglesCompletedOff() async {
        let task = TaskModel(title: "T", completed: true)
        let recorder = UpdateRecorder()
        let sut = TaskItemViewModel(task: task) { recorder.task = $0 }

        sut.updateTaskCompleted()

        XCTAssertEqual(recorder.task!.id, task.id)
        XCTAssertFalse(recorder.task!.completed)
    }

    func testViewModelHoldsAnImmutableSnapshotSoRepeatedTogglesAgree() async {
        let recorder = CallRecorder()
        let sut = TaskItemViewModel(task: TaskModel(title: "T", completed: false)) {
            recorder.tasks.append($0)
        }

        sut.updateTaskCompleted()
        sut.updateTaskCompleted()

        // `task` is a `let` snapshot, so both calls toggle from the original value
        // rather than alternating. The row is rebuilt from the parent's list after
        // each update, which is what keeps this correct in the running app — if
        // this view model ever outlives a render pass, this becomes a bug.
        XCTAssertEqual(recorder.tasks.map(\.completed), [true, true])
    }

    func testUpdatePreservesEveryFieldExceptCompleted() async {
        let task = TaskModel(title: "T", completed: false, remoteID: 9, userId: 4)
        let recorder = UpdateRecorder()
        let sut = TaskItemViewModel(task: task) { recorder.task = $0 }

        sut.updateTaskCompleted()

        let reported = recorder.task!
        XCTAssertEqual(reported.id, task.id)
        XCTAssertEqual(reported.title, "T")
        XCTAssertEqual(reported.remoteID, 9)
        XCTAssertEqual(reported.userId, 4)
        XCTAssertTrue(reported.completed)
    }

    func testExposedTaskIsUnchangedByToggling() async {
        let sut = TaskItemViewModel(task: TaskModel(title: "T", completed: false)) { _ in }

        sut.updateTaskCompleted()

        // The view renders from `viewModel.task`; it only changes when the parent
        // hands down a rebuilt row.
        XCTAssertFalse(sut.task.completed)
    }
}

// MARK: Helper Classes
extension TaskItemViewModelTests {
    /// Captures the value the row reports back up.
    final class UpdateRecorder {
        var task: TaskModel?
    }
    
    /// Captures every value the row reports back up, in order.
    final class CallRecorder {
        var tasks: [TaskModel] = []
    }
}
