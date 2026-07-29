//
//  CancellableTask.swift
//  TaskBox
//
//  Created by VAndrJ on 16.08.2025.
//

import Foundation

/// A protocol representing a thread-safe cancellable `Task`.
///
/// This protocol provides a type-erased abstraction that allows `Task` instances to be stored in `TaskBox` and cancelled without knowing their specific underlying types.
///
/// Conforming types must make `cancel()` safe to call from any concurrency domain.
public protocol CancellableTask: Sendable {
    func cancel()
}

extension Task: CancellableTask {
    public func store(in box: TaskBox) {
        box.insert(self)
    }
}
