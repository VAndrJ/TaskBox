//
//  Task+Run.swift
//  TaskBox
//
//  Created by VAndrJ on 16.08.2025.
//

import Foundation

extension Task where Success == Void, Failure == Never {
    /// Creates a new `Task` that executes an async operation and provides structured callbacks for different outcomes.
    ///
    /// This method provides a clean, structured way to handle async operations with distinct callbacks for success, cancellation, and completion scenarios.
    /// It's designed to help organize async code while maintaining clear control over memory management and actor isolation.
    ///
    /// ## Memory Management Considerations
    ///
    /// **Important:** This method intentionally does NOT use `@_implicitSelfCapture` to ensure that callers are
    /// explicitly aware when they capture `self` in the closures. This deliberate design choice helps prevent
    /// accidental memory retention issues and delayed deallocation, as it requires explicit capture decisions.
    ///
    /// When using this method, you have full control over how `self` is captured:
    /// - Use `[weak self]` for weak references to avoid retain cycles.
    /// - Use `[unowned self]` when you're certain `self` will outlive the task.
    /// - Capture `self` strongly if intentional, though this may negate TaskBox benefits.
    ///
    /// ## Execution Flow
    ///
    /// 1. **Success case:** If the task isn't canceled, `onSuccess` is called.
    /// 2. **Cancellation case:** If the task is canceled, `onCanceled` is called instead.
    /// 3. **Always:** The `onCompleted` callback is always called last, regardless of success or cancellation.
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// Task.run(
    ///     operation: {
    ///         // Perform some async operation
    ///     },
    ///     onSuccess: { result in
    ///         // Handle successful result
    ///     },
    ///     onCanceled: {
    ///         // Handle cancellation logic
    ///     },
    ///     onCompleted: {
    ///         // Handle completion logic
    ///     }
    /// ).store(in: box)
    /// ```
    ///
    /// - Parameters:
    ///   - name: Optional name for the `Task`.
    ///   - priority: The priority level for task execution.
    ///   - operation: The main async operation to perform.
    ///   - onSuccess: Called when the operation completes successfully with the result.
    ///   - onCanceled: Called when the `Task` is canceled. Defaults to empty closure.
    ///   - onCompleted: Called after all other callbacks, regardless of outcome. Defaults to empty closure.
    ///
    /// - Returns: The created `Task`, which can be stored to control cancellation.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    public static func run<Result: Sendable>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        @_inheritActorContext operation: sending @escaping @isolated(any) () async -> Result,
        @_inheritActorContext onSuccess: sending @escaping @isolated(any) (Result) async -> Void,
        @_inheritActorContext onCanceled: sending @escaping @isolated(any) () async -> Void = {},
        @_inheritActorContext onCompleted: sending @escaping @isolated(any) () async -> Void = {}
    ) -> Self {
        return Task(
            name: name,
            priority: priority
        ) {
            let result = await operation()
            if !CancellationCheckTask.isCancelled {
                await onSuccess(result)
            } else {
                await onCanceled()
            }
            await onCompleted()
        }
    }

    /// Creates a new `Task` that executes an async operation that returns `Void` and provides structured callbacks for different outcomes.
    ///
    /// This method provides a clean, structured way to handle async operations that don't return a value, with distinct callbacks for success, cancellation, and completion scenarios.
    /// It's designed to help organize async code while maintaining clear control over memory management and actor isolation.
    ///
    /// ## Memory Management Considerations
    ///
    /// **Important:** This method intentionally does NOT use `@_implicitSelfCapture` to ensure that callers are
    /// explicitly aware when they capture `self` in the closures. This deliberate design choice helps prevent
    /// accidental memory retention issues and delayed deallocation, as it requires explicit capture decisions.
    ///
    /// When using this method, you have full control over how `self` is captured:
    /// - Use `[weak self]` for weak references to avoid retain cycles.
    /// - Use `[unowned self]` when you're certain `self` will outlive the task.
    /// - Capture `self` strongly if intentional, though this may negate TaskBox benefits.
    ///
    /// ## Execution Flow
    ///
    /// 1. **Success case:** If the task isn't canceled, `onSuccess` is called.
    /// 2. **Cancellation case:** If the task is canceled, `onCanceled` is called instead.
    /// 3. **Always:** The `onCompleted` callback is always called last, regardless of success or cancellation.
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// Task.run(
    ///     operation: {
    ///         // Perform some async operation that doesn't return a value
    ///         await someVoidAsyncOperation()
    ///     },
    ///     onSuccess: {
    ///         // Handle successful completion
    ///     },
    ///     onCanceled: {
    ///         // Handle cancellation logic
    ///     },
    ///     onCompleted: {
    ///         // Handle completion logic
    ///     }
    /// ).store(in: box)
    /// ```
    ///
    /// - Parameters:
    ///   - name: Optional name for the `Task`.
    ///   - priority: The priority level for task execution.
    ///   - operation: The main async operation to perform that returns `Void`.
    ///   - onSuccess: Called when the operation completes successfully.
    ///   - onCanceled: Called when the `Task` is canceled. Defaults to empty closure.
    ///   - onCompleted: Called after all other callbacks, regardless of outcome. Defaults to empty closure.
    ///
    /// - Returns: The created `Task`, which can be stored to control cancellation.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    public static func run(
        name: String? = nil,
        priority: TaskPriority? = nil,
        @_inheritActorContext operation: sending @escaping @isolated(any) () async -> Void,
        @_inheritActorContext onSuccess: sending @escaping @isolated(any) () async -> Void,
        @_inheritActorContext onCanceled: sending @escaping @isolated(any) () async -> Void = {},
        @_inheritActorContext onCompleted: sending @escaping @isolated(any) () async -> Void = {}
    ) -> Self {
        return Task(
            name: name,
            priority: priority
        ) {
            await operation()
            if !CancellationCheckTask.isCancelled {
                await onSuccess()
            } else {
                await onCanceled()
            }
            await onCompleted()
        }
    }

    /// Creates a new `Task` that executes a throwing async operation with structured callbacks for different outcomes and error handling.
    ///
    /// This method provides a clean, structured way to handle throwing async operations with distinct callbacks for success, error, cancellation, and completion scenarios.
    /// It's designed to help organize async code while maintaining clear control over memory management and actor isolation.
    ///
    /// ## Memory Management Considerations
    ///
    /// **Important:** This method intentionally does NOT use `@_implicitSelfCapture` to ensure that callers are
    /// explicitly aware when they capture `self` in the closures. This deliberate design choice helps prevent
    /// accidental memory retention issues and delayed deallocation, as it requires explicit capture decisions.
    ///
    /// When using this method, you have full control over how `self` is captured:
    /// - Use `[weak self]` for weak references to avoid retain cycles.
    /// - Use `[unowned self]` when you're certain `self` will outlive the task.
    /// - Capture `self` strongly if intentional, though this may negate TaskBox benefits.
    ///
    /// ## Execution Flow
    ///
    /// 1. **Success case:** If the task isn't canceled and the operation completes successfully, `onSuccess` is called.
    /// 2. **Error case:** If the task isn't canceled but the operation throws an error, `onError` is called.
    /// 3. **Cancellation case:** If the task is canceled (either before completion or after an error), `onCanceled` is called.
    /// 4. **Always:** The `onCompleted` callback is called last, regardless of the outcome.
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// Task.run(
    ///     operation: {
    ///         // Perform some async operation that may throw
    ///     },
    ///     onSuccess: { result in
    ///         // Handle successful result
    ///     },
    ///     onError: { error in
    ///         // Handle error
    ///     },
    ///     onCanceled: {
    ///         // Handle cancellation logic
    ///     },
    ///     onCompleted: {
    ///         // Handle completion logic
    ///     }
    /// ).store(in: box)
    /// ```
    ///
    /// - Parameters:
    ///   - name: Optional name for the `Task`.
    ///   - priority: The priority level for task execution.
    ///   - operation: The main async operation to perform that may throw an error.
    ///   - onSuccess: Called when the operation completes successfully.
    ///   - onError: Called when the operation throws an error.
    ///   - onCanceled: Called when the task is canceled. Defaults to empty closure.
    ///   - onCompleted: Called after all other callbacks, regardless of outcome. Defaults to empty closure.
    ///
    /// - Returns: The created `Task`, which can be stored to control cancellation.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    public static func run<Result: Sendable>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        @_inheritActorContext operation: sending @escaping @isolated(any) () async throws -> Result,
        @_inheritActorContext onSuccess: sending @escaping @isolated(any) (Result) async -> Void,
        @_inheritActorContext onError: sending @escaping @isolated(any) (any Error) async -> Void,
        @_inheritActorContext onCanceled: sending @escaping @isolated(any) () async -> Void = {},
        @_inheritActorContext onCompleted: sending @escaping @isolated(any) () async -> Void = {}
    ) -> Self {
        return Task(
            name: name,
            priority: priority
        ) {
            do {
                let result = try await operation()
                if !CancellationCheckTask.isCancelled {
                    await onSuccess(result)
                } else {
                    await onCanceled()
                }
            } catch {
                if !CancellationCheckTask.isCancelled {
                    await onError(error)
                } else {
                    await onCanceled()
                }
            }
            await onCompleted()
        }
    }

    /// Creates a new `Task` that executes a throwing async operation with structured callbacks for different outcomes and error handling.
    ///
    /// This method provides a clean, structured way to handle throwing async operations that don't return a value, with distinct callbacks for success, error, cancellation, and completion scenarios.
    /// It's designed to help organize async code while maintaining clear control over memory management and actor isolation.
    ///
    /// ## Memory Management Considerations
    ///
    /// **Important:** This method intentionally does NOT use `@_implicitSelfCapture` to ensure that callers are
    /// explicitly aware when they capture `self` in the closures. This deliberate design choice helps prevent
    /// accidental memory retention issues and delayed deallocation, as it requires explicit capture decisions.
    ///
    /// When using this method, you have full control over how `self` is captured:
    /// - Use `[weak self]` for weak references to avoid retain cycles.
    /// - Use `[unowned self]` when you're certain `self` will outlive the task.
    /// - Capture `self` strongly if intentional, though this may negate TaskBox benefits.
    ///
    /// ## Execution Flow
    ///
    /// 1. **Success case:** If the task isn't canceled and the operation completes successfully, `onSuccess` is called.
    /// 2. **Error case:** If the task isn't canceled but the operation throws an error, `onError` is called.
    /// 3. **Cancellation case:** If the task is canceled (either before completion or after an error), `onCanceled` is called.
    /// 4. **Always:** The `onCompleted` callback is called last, regardless of the outcome.
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// Task.run(
    ///     operation: {
    ///         // Perform some async operation that may throw
    ///     },
    ///     onSuccess: {
    ///         // Handle successful completion
    ///     },
    ///     onError: { error in
    ///         // Handle error
    ///     },
    ///     onCanceled: {
    ///         // Handle cancellation logic
    ///     },
    ///     onCompleted: {
    ///         // Handle completion logic
    ///     }
    /// ).store(in: box)
    /// ```
    ///
    /// - Parameters:
    ///   - name: Optional name for the `Task`.
    ///   - priority: The priority level for task execution.
    ///   - operation: The main async operation to perform that may throw an error.
    ///   - onSuccess: Called when the operation completes successfully.
    ///   - onError: Called when the operation throws an error.
    ///   - onCanceled: Called when the task is canceled. Defaults to empty closure.
    ///   - onCompleted: Called after all other callbacks, regardless of outcome. Defaults to empty closure.
    ///
    /// - Returns: The created `Task`, which can be stored to control cancellation.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    public static func run(
        name: String? = nil,
        priority: TaskPriority? = nil,
        @_inheritActorContext operation: sending @escaping @isolated(any) () async throws -> Void,
        @_inheritActorContext onSuccess: sending @escaping @isolated(any) () async -> Void,
        @_inheritActorContext onError: sending @escaping @isolated(any) (any Error) async -> Void,
        @_inheritActorContext onCanceled: sending @escaping @isolated(any) () async -> Void = {},
        @_inheritActorContext onCompleted: sending @escaping @isolated(any) () async -> Void = {}
    ) -> Self {
        return Task(
            name: name,
            priority: priority
        ) {
            do {
                try await operation()
                if !CancellationCheckTask.isCancelled {
                    await onSuccess()
                } else {
                    await onCanceled()
                }
            } catch {
                if !CancellationCheckTask.isCancelled {
                    await onError(error)
                } else {
                    await onCanceled()
                }
            }
            await onCompleted()
        }
    }

    /// Creates a new `Task` that runs an async sequence and provides structured callbacks for each value, cancellation, and completion.
    ///
    /// This method provides a clean, structured way to handle async sequences with distinct callbacks for each value received,
    /// cancellation, and completion scenarios. It's designed to help organize async sequence handling while maintaining clear
    /// control over memory management and actor isolation.
    ///
    /// ## Memory Management Considerations
    ///
    /// **Important:** This method intentionally does NOT use `@_implicitSelfCapture` to ensure that callers are
    /// explicitly aware when they capture `self` in the closures. This deliberate design choice helps prevent
    /// accidental memory retention issues and delayed deallocation, as it requires explicit capture decisions.
    ///
    /// When using this method, you have full control over how `self` is captured:
    /// - Use `[weak self]` for weak references to avoid retain cycles.
    /// - Use `[unowned self]` when you're certain `self` will outlive the task.
    /// - Capture `self` strongly if intentional, though this may negate TaskBox benefits.
    ///
    /// ## Execution Flow
    ///
    /// 1. **Value case:** Each time a value is received from the async sequence, `onValue` is called.
    /// 2. **Error case:** If the task isn't canceled but the sequence throws an error, `onError` is called.
    /// 3. **Cancellation case:** If the task is canceled, `onCanceled` is called.
    /// 4. **Always:** The `onCompleted` callback is always called last, regardless of error or cancellation.
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// Task.run(
    ///     sequence: producer,
    ///     onValue: { value in
    ///         // Handle received value
    ///     },
    ///     onError: { error in
    ///         // Handle error
    ///     },
    ///     onCanceled: {
    ///         // Handle cancellation logic
    ///     },
    ///     onCompleted: {
    ///         // Handle completion logic
    ///     }
    /// ).store(in: box)
    /// ```
    ///
    /// - Parameters:
    ///   - name: Optional name for the `Task`.
    ///   - priority: The priority level for task execution.
    ///   - sequence: The async sequence to run.
    ///   - onValue: Called when a value is received from the async sequence.
    ///   - onError: Called when an error is received. Defaults to empty closure.
    ///   - onCanceled: Called when the task is canceled. Defaults to empty closure.
    ///   - onCompleted: Called after all other callbacks, regardless of outcome. Defaults to empty closure.
    ///
    /// - Returns: The created `Task`, which can be stored to control cancellation.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    public static func run<Sequence: AsyncSequence>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        sequence: sending Sequence,
        @_inheritActorContext onValue: sending @escaping @isolated(any) (Sequence.Element) async -> Void,
        @_inheritActorContext onError: sending @escaping @isolated(any) (any Error) async -> Void = { _ in },
        @_inheritActorContext onCanceled: sending @escaping @isolated(any) () async -> Void = {},
        @_inheritActorContext onCompleted: sending @escaping @isolated(any) () async -> Void = {}
    ) -> Self where Sequence.Element: Sendable {
        return Task(
            name: name,
            priority: priority
        ) {
            var wasCancelled = false
            do {
                for try await unsafe value in sequence {
                    if CancellationCheckTask.isCancelled {
                        wasCancelled = true
                        break
                    }
                    await onValue(value)
                }
            } catch {
                if CancellationCheckTask.isCancelled {
                    wasCancelled = true
                } else {
                    await onError(error)
                }
            }
            if !wasCancelled && CancellationCheckTask.isCancelled {
                wasCancelled = true
            }
            if wasCancelled {
                await onCanceled()
            }
            await onCompleted()
        }
    }

    /// Creates a new `Task` that runs an async sequence with `Void` elements and provides structured callbacks for each value, cancellation, and completion.
    ///
    /// This method provides a clean, structured way to handle async sequences that emit `Void` values (typically used for signaling events
    /// rather than data), with distinct callbacks for each value received, cancellation, and completion scenarios. It's designed to help
    /// organize async sequence handling while maintaining clear control over memory management and actor isolation.
    ///
    /// ## Memory Management Considerations
    ///
    /// **Important:** This method intentionally does NOT use `@_implicitSelfCapture` to ensure that callers are
    /// explicitly aware when they capture `self` in the closures. This deliberate design choice helps prevent
    /// accidental memory retention issues and delayed deallocation, as it requires explicit capture decisions.
    ///
    /// When using this method, you have full control over how `self` is captured:
    /// - Use `[weak self]` for weak references to avoid retain cycles.
    /// - Use `[unowned self]` when you're certain `self` will outlive the task.
    /// - Capture `self` strongly if intentional, though this may negate TaskBox benefits.
    ///
    /// ## Execution Flow
    ///
    /// 1. **Value case:** Each time a `Void` value is received from the async sequence, `onValue` is called.
    /// 2. **Error case:** If the task isn't canceled but the sequence throws an error, `onError` is called.
    /// 3. **Cancellation case:** If the task is canceled, `onCanceled` is called.
    /// 4. **Always:** The `onCompleted` callback is always called last, regardless of error or cancellation.
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// Task.run(
    ///     sequence: voidProducer,
    ///     onValue: {
    ///         // Handle received void signal/event
    ///     },
    ///     onError: { error in
    ///         // Handle error
    ///     },
    ///     onCanceled: {
    ///         // Handle cancellation logic
    ///     },
    ///     onCompleted: {
    ///         // Handle completion logic
    ///     }
    /// ).store(in: box)
    /// ```
    ///
    /// - Parameters:
    ///   - name: Optional name for the `Task`.
    ///   - priority: The priority level for task execution.
    ///   - sequence: The async sequence to run that emits `Void` values.
    ///   - onValue: Called when a `Void` value is received from the async sequence.
    ///   - onError: Called when an error is received. Defaults to empty closure.
    ///   - onCanceled: Called when the task is canceled. Defaults to empty closure.
    ///   - onCompleted: Called after all other callbacks, regardless of outcome. Defaults to empty closure.
    ///
    /// - Returns: The created `Task`, which can be stored to control cancellation.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    public static func run<Sequence: AsyncSequence>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        sequence: sending Sequence,
        @_inheritActorContext onValue: sending @escaping @isolated(any) () async -> Void,
        @_inheritActorContext onError: sending @escaping @isolated(any) (any Error) async -> Void = { _ in },
        @_inheritActorContext onCanceled: sending @escaping @isolated(any) () async -> Void = {},
        @_inheritActorContext onCompleted: sending @escaping @isolated(any) () async -> Void = {}
    ) -> Self where Sequence.Element == Void {
        return Task(
            name: name,
            priority: priority
        ) {
            var wasCancelled = false
            do {
                for try await unsafe _ in sequence {
                    if CancellationCheckTask.isCancelled {
                        wasCancelled = true
                        break
                    }
                    await onValue()
                }
            } catch {
                if CancellationCheckTask.isCancelled {
                    wasCancelled = true
                } else {
                    await onError(error)
                }
            }
            if !wasCancelled && CancellationCheckTask.isCancelled {
                wasCancelled = true
            }
            if wasCancelled {
                await onCanceled()
            }
            await onCompleted()
        }
    }
}

private typealias CancellationCheckTask = Task<Never, Never>
