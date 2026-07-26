//
//  TaskDataSourceTests.swift
//  ToDoListTests
//

import XCTest
import Foundation
@testable import ToDoList

final class TaskDataSourceTests: XCTestCase {

    func testGetRemoteTasksReturnsDecodedTasks() async throws {
        let network = MockNetworkManager()
        network.remoteTasks = [RemoteTask(id: 1, userId: 1, title: "a", completed: false)]
        let sut = TaskDataSource(networkManager: network)

        let result = try await sut.getRemoteTasks()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first!.id, 1)
        XCTAssertEqual(network.fetchCallCount, 1)
    }

    func testGetRemoteTasksPropagatesError() async {
        let network = MockNetworkManager()
        network.errorToThrow = APIErrors.invalidResponse
        let sut = TaskDataSource(networkManager: network)

        await XCTAssertThrowsErrorAsync(try await sut.getRemoteTasks()) { error in
            XCTAssertEqual(error as? APIErrors, .invalidResponse)
        }
    }

    func testGetRemoteTasksReturnsEmptyArrayWithoutError() async throws {
        let network = MockNetworkManager()
        network.remoteTasks = []
        let sut = TaskDataSource(networkManager: network)

        let result = try await sut.getRemoteTasks()

        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(network.fetchCallCount, 1)
    }

    func testGetRemoteTasksRequestsTheTodosEndpoint() async throws {
        let network = MockNetworkManager()
        let sut = TaskDataSource(networkManager: network)

        _ = try await sut.getRemoteTasks()

        XCTAssertEqual(
            network.lastEndpoint?.absoluteString,
            "https://jsonplaceholder.typicode.com/todos"
        )
    }

    func testEachCallHitsTheNetworkRatherThanCaching() async throws {
        let network = MockNetworkManager()
        let sut = TaskDataSource(networkManager: network)

        _ = try await sut.getRemoteTasks()
        _ = try await sut.getRemoteTasks()

        XCTAssertEqual(network.fetchCallCount, 2)
    }
}
