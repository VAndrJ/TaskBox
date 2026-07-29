//
//  TaskBox.swift
//  TaskBox
//
//  Created by VAndrJ on 16.08.2025.
//

import Foundation

/// A container for managing multiple `Tasks` cancellation.
///
/// The `TaskBox` class provides a simple way to store, insert, and cancel groups of `Tasks`.
/// When the `TaskBox` instance is deallocated, cancellation is automatically requested for all stored `Tasks`.
@MainActor
public final class TaskBox {
    private var tasks: [any CancellableTask] = []

    public init() {}

    /// Inserts a cancellable task into the box for later management.
    ///
    /// - Parameter task: The `CancellableTask` to be managed by the box.
    public func insert(_ task: any CancellableTask) {
        tasks.append(task)
    }

    /// Requests cancellation for all managed tasks and removes them from the box.
    ///
    /// Task cancellation is cooperative. Each task must observe and respond to the cancellation request,
    /// so ongoing work is not guaranteed to stop immediately.
    public func cancelAll() {
        let tasksToCancel = tasks
        tasks.removeAll()
        for task in tasksToCancel {
            task.cancel()
        }
    }

    isolated deinit {
        cancelAll()
    }
}

extension TaskBox: CustomDebugStringConvertible {
    public var debugDescription: String { "TaskBox(tasks: \(tasks.count))" }
}
