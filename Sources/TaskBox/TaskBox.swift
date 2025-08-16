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
/// When the `TaskBox` instance is deallocated, all stored `Tasks` are automatically canceled.
public final class TaskBox {
    private var tasks: [any CancellableTask] = []

    public init() {}

    /// Inserts a cancellable task into the box for later management.
    ///
    /// - Parameter task: The `CancellableTask` to be managed by the box.
    public func insert(_ task: any CancellableTask) {
        tasks.append(task)
    }

    /// Cancels all managed tasks and removes them from the box.
    ///
    /// This method can be used to immediately stop all ongoing tasks managed by this box.
    public func cancelAll() {
        tasks.forEach {
            $0.cancel()
        }
        tasks.removeAll()
    }

    isolated deinit {
        cancelAll()
    }
}
