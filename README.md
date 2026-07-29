# TaskBox

[![StandWithUkraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/badges/StandWithUkraine.svg)](https://github.com/vshymanskyy/StandWithUkraine/blob/main/docs/README.md)
[![Support Ukraine](https://img.shields.io/badge/Support-Ukraine-FFD500?style=flat&labelColor=005BBB)](https://opensource.fb.com/support-ukraine)

[![Language](https://img.shields.io/badge/language-Swift%206.2-orangered.svg?style=flat)](https://www.swift.org)
[![SPM](https://img.shields.io/badge/SPM-compatible-limegreen.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20macOS%20%7C%20visionOS-lightgray.svg?style=flat)](https://developer.apple.com/discover)

A lightweight Swift package for organizing, managing, and canceling tasks.

## Features

- 📦 **Task Management**: Store and manage Tasks in a container
- 🧬 **Organized Task Workflows**: Wrap unstructured tasks in consistent outcome and completion callbacks
- ♻️ **Automatic Cancellation Requests**: Cancellation is requested when `TaskBox` is deallocated
- 🪶 **Simple API**: Minimal interface for Task management

## Requirements

- iOS 13.0+ / watchOS 6.0+ / tvOS 13.0+ / macOS 11.0+ / visionOS 1.0+
- Swift 6.2+
- Xcode 26.0+

## Installation

### Swift Package Manager

Add TaskBox to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/VAndrJ/TaskBox.git", from: "1.0.0"),
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL

## Usage

```swift
import TaskBox

// Create a TaskBox to manage your tasks
let box = TaskBox()

// Create and store tasks
Task {
    await someAsyncOperation()
}.store(in: box)
Task {
    await anotherAsyncOperation()
}.store(in: box)

// Cancel all tasks when needed
box.cancelAll()

// Or cancellation is automatically requested when TaskBox is deallocated
```

Cancellation is cooperative. `TaskBox` calls `cancel()` on each stored task, but the underlying work stops only when it observes and responds to that request.

## Organized Task Workflows

`Task.run` still creates an unstructured Swift concurrency task. It does not establish the parent-child lifetime or cancellation rules of structured concurrency.

Instead, it adds organization around an unstructured task by giving operations and async sequences consistent callbacks for values, success, errors, cancellation, and completion.

### 🧱 Basic Organized Task

Create an unstructured task with organized callbacks for success, cancellation, and completion:

```swift
let box = TaskBox()
...
Task.run(
    operation: {
        await fetchData()
    },
    onSuccess: { [weak self] result in
        self?.processData(result)
    },
    onCanceled: {
        // Handle cancellation logic
    },
    onCompleted: {
        // Cleanup after task completion
    }
).store(in: box)
```

### ⚠️ Throwing Operations

Handle operations that can throw errors with dedicated error callbacks:

```swift
Task.run(
    operation: {
        let result = try await riskyCall()
        return result
    },
    onSuccess: { result in
        // Handle successful result
    },
    onError: { error in
        // Handle errors
    }
).store(in: box)
```

🆚 _Comparison with Regular Tasks_

For comparison, here's how you would typically handle the same operation with regular Swift Tasks and the potential issues:

```swift
class SomeClass {
    var task: Task<Void, Never>? // Need to declare type explicitly
    
    func startOperation() {
        // Problem: self is captured implicitly, keeping the instance alive until completion
        task = Task {
            let data = try await fetchData() // if the fetchData throws, the task will complete
            processData(data) // self captured here
        }
    }
    
    // More reliable approach, but verbose and error-prone:
    func startOperationSafely() {
        task = Task { [weak self] in
            do {
                let data = try await fetchData()
                            
                // Need to manually check for cancellation
                guard !Task.isCancelled else {
                    return
                }
                self?.processData(data)
            } catch {
                // Need to manually check for cancellation
                guard !Task.isCancelled else {
                    return
                }
                // Handle error
            }
            // Process completion
        }
    }
    
    private func processData(_ data: Data) {
        // Process data
    }
    
    deinit {
        // Need to remember to cancel manually
        task?.cancel()
    }
}
```

**Problems with regular Tasks:**
- 🔗 **Implicit self capture** can cause delayed deallocation
- 🧹 **Manual cleanup** in deinit

**TaskBox advantages:**
- ✅ **Automatic cancellation requests** when TaskBox is deallocated
- ✅ **Organized callbacks** for success, error, cancellation, and completion

### ⛓️ Async Sequences

Process async sequences with organized callbacks for each value:

```swift
Task.run(
    sequence: dataStream, // Your AsyncSequence
    onValue: { value in
        // Handle each value from the sequence
    },
    onError: { error in
        // Handle errors
    },
    onCanceled: {
        // Handle cancellation
    },
    onCompleted: {
        // Stream finished
    }
).store(in: box)
```

🆚 _Comparison with Regular Tasks for AsyncSequence_

For comparison, here's how an AsyncSequence is typically handled with regular Tasks and their common pitfalls:

```swift
class StreamProcessor {
    var task: Task<Void, Never>?
    
    func startProcessing() {
        // ❌ Problem: self is captured implicitly
        // If dataStream never ends, self will never be deallocated
        task = Task {
            for await value in dataStream {
                processData(value) // self captured here
            }
        }
    }
    
    // ❌ Attempting to fix with weak self, but still wrong:
    func startProcessingSemiFixed() {
        task = Task { [weak self] in
            guard let self else {
                return 
            }
            for await value in dataStream {
                processData(value) // self is STILL captured strongly here
            }
        }
    }
    
    // ✅ Correct approach:
    func startProcessingCorrect() {
        task = Task { [weak self] in
            for await value in dataStream {
                // Need to check weak self on EVERY iteration for proper memory management
                guard let self else { 
                    return 
                }
                
                processData(value)
            }
            // process completion
        }
    }
    
    deinit {
        // Need to remember manual cleanup
        task?.cancel()
    }
}
```

**Common AsyncSequence Problems:**
- 🔄 **Infinite streams** can prevent deallocation with implicit self capture
- 🧠 **Abandoned memory** from forgetting weak self patterns

**TaskBox AsyncSequence advantages:**
- ✅ **Clear separation of concerns** - stream listening vs value processing
- ✅ **Organized error handling** for failures


### Actor Isolation

`TaskBox` does not impose a global actor. Its state is protected by a lock, and its synchronous API can be used safely from `MainActor`,
custom actors, and nonisolated code. Custom `CancellableTask` conformers must be `Sendable` and make `cancel()` safe to call from any
concurrency domain.

The `Task.run` factory methods are explicitly nonisolated. Their operation and callback closures inherit isolation from the call site:
calls from `MainActor` remain MainActor-isolated, while calls from another actor retain that actor's isolation.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
