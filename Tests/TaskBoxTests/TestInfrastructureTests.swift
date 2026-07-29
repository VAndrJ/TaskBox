//
//  TestInfrastructureTests.swift
//  TaskBox
//
//  Created by VAndrJ on 29.07.2026.
//

import Testing

@Suite(.timeLimit(.minutes(1)))
struct TestInfrastructureTests {
    @Test("bounded wait reports timeout instead of hanging")
    func testWaitUntilTimeout() async {
        do {
            try await waitUntil(timeout: 0) { false }
            Issue.record("Expected waitUntil to time out")
        } catch TestWaitError.timedOut {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
