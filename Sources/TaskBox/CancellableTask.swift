//
//  CancellableTask.swift
//  TaskBox
//
//  Created by VAndrJ on 16.08.2025.
//

import Foundation

/// A protocol representing a cancellable `Task`.
///
/// This protocol provides a type-erased abstraction that allows `Task` instances to be stored in `TaskBox` and cancelled without knowing their specific underlying types.
public protocol CancellableTask {
    func cancel()
}

extension Task: CancellableTask {
    public func store(in box: TaskBox) {
        box.insert(self)
    }
}
