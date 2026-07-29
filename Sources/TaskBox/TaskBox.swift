//
//  TaskBox.swift
//  TaskBox
//
//  Created by VAndrJ on 16.08.2025.
//

import Foundation

/// A container for managing multiple `Tasks` cancellation.
///
/// The `TaskBox` class provides a thread-safe way to store, insert, and cancel groups of `Tasks`.
/// Its synchronous API can be used from any concurrency domain.
/// When the `TaskBox` instance is deallocated, cancellation is automatically requested for all stored `Tasks`.
public final class TaskBox: @unchecked Sendable {
    // All access to `tasks` is protected by `lock`.
    private let lock = NSLock()
    private var tasks: [any CancellableTask] = []

    public init() {}

    /// Inserts a cancellable task into the box for later management.
    ///
    /// - Parameter task: The `CancellableTask` to be managed by the box.
    public func insert(_ task: any CancellableTask) {
        lock.withLock {
            tasks.append(task)
        }
    }

    /// Requests cancellation for all managed tasks and removes them from the box.
    ///
    /// Task cancellation is cooperative. Each task must observe and respond to the cancellation request,
    /// so ongoing work is not guaranteed to stop immediately.
    ///
    /// Tasks inserted after this method takes its snapshot remain stored for a later cancellation request.
    public func cancelAll() {
        let tasksToCancel = lock.withLock {
            let snapshot = tasks
            tasks.removeAll()
            return snapshot
        }
        for task in tasksToCancel {
            task.cancel()
        }
    }

    deinit {
        cancelAll()
    }
}

extension TaskBox: CustomDebugStringConvertible {
    public var debugDescription: String {
        lock.withLock {
            "TaskBox(tasks: \(tasks.count))"
        }
    }
}
