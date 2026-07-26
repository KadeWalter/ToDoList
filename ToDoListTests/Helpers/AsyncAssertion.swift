//
//  AsyncAssertion.swift
//  ToDoListTests
//
//  XCTest's XCTAssertThrowsError is synchronous; this is the async equivalent.
//

import XCTest

/// Asserts that an `async` expression throws
func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: String = "Expected an error to be thrown, but none was.",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (Error) -> Void = { _ in }
) async {
    do {
        _ = try await expression()
        XCTFail(message, file: file, line: line)
    } catch {
        errorHandler(error)
    }
}
