//
//  Test+Support.swift
//  TaskBox
//
//  Created by VAndrJ on 16.08.2025.
//

import Foundation

extension UInt64 {
    static let millisecond: UInt64 = 1_000_000
    static let second: UInt64 = 1_000_000_000
}

enum TestWaitError: Error {
    case timedOut
}

@MainActor
func waitUntil(
    timeout: TimeInterval = 1,
    pollInterval: UInt64 = .millisecond,
    _ condition: () -> Bool
) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        guard Date() < deadline else {
            throw TestWaitError.timedOut
        }
        try await Task.sleep(nanoseconds: pollInterval)
    }
}
