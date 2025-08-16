//
//  TaskRunAsyncSequenceTests.swift
//  TaskBox
//
//  Created by VAndrJ on 16.08.2025.
//

import Testing

@testable import TaskBox

@Suite
struct TaskRunAsyncSequenceTests {
    @Test("run to async sequence receives all values")
    func testRunToAsyncSequenceReceivesAllValues() async {
        var receivedValues: [Int] = []
        var completedCalled = false
        var errorCalled = false
        let values = [1, 2, 3, 4, 5]
        let asyncSequence = AsyncStream<Int> { continuation in
            Task {
                for value in values {
                    continuation.yield(value)
                }
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: { value in
                receivedValues.append(value)
            },
            onError: { _ in
                errorCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(receivedValues == values)
        #expect(completedCalled == true)
        #expect(errorCalled == false)
    }

    @Test("run to async sequence handles errors")
    func testRunToAsyncSequenceHandlesErrors() async {
        var receivedValues: [String] = []
        var receivedError: Error?
        var completedCalled = false
        struct TestError: Error, Equatable {}
        let asyncSequence = AsyncThrowingStream<String, Error> { continuation in
            Task {
                continuation.yield("value1")
                continuation.yield("value2")
                continuation.finish(throwing: TestError())
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: { value in
                receivedValues.append(value)
            },
            onError: { error in
                receivedError = error
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(receivedValues == ["value1", "value2"])
        #expect(receivedError is TestError)
        #expect(completedCalled == true)
    }

    @Test("run to async sequence handles errors completion")
    func testRunToAsyncSequenceHandlesErrorsCompletion() async {
        var receivedValues: [String] = []
        var completedCalled = false
        struct TestError: Error, Equatable {}
        let asyncSequence = AsyncThrowingStream<String, Error> { continuation in
            Task {
                continuation.yield("value1")
                continuation.yield("value2")
                continuation.finish(throwing: TestError())
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: { value in
                receivedValues.append(value)
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(receivedValues == ["value1", "value2"])
        #expect(completedCalled == true)
    }

    @Test("run to async sequence with default callbacks")
    func testRunToAsyncSequenceWithDefaultCallbacks() async {
        var receivedValues: [Double] = []
        let values = [1.0, 2.5, 3.14]
        let asyncSequence = AsyncStream<Double> { continuation in
            Task {
                for value in values {
                    continuation.yield(value)
                }
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: { value in
                receivedValues.append(value)
            }
        )

        await task.value

        #expect(receivedValues == values)
    }

    @Test("run to empty async sequence calls completion")
    func testRunToEmptyAsyncSequence() async {
        var valueCallCount = 0
        var completedCalled = false
        var errorCalled = false
        let asyncSequence = AsyncStream<Int> { continuation in
            continuation.finish()
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: { _ in
                valueCallCount += 1
            },
            onError: { _ in
                errorCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(valueCallCount == 0)
        #expect(completedCalled == true)
        #expect(errorCalled == false)
    }

    @Test("run to async sequence respects task name and priority")
    func testRunToAsyncSequenceWithNameAndPriority() async {
        let taskName = "async-sequence-task"
        let taskPriority = TaskPriority.high
        var receivedValue: String?
        let asyncSequence = AsyncStream<String> { continuation in
            continuation.yield("test")
            continuation.finish()
        }
        let task = Task.run(
            name: taskName,
            priority: taskPriority,
            sequence: asyncSequence,
            onValue: { value in
                receivedValue = value
            }
        )

        await task.value

        #expect(receivedValue == "test")
        #expect(task.isCancelled == false)
    }

    @Test("run to async sequence can be stored in TaskBox")
    func testRunToAsyncSequenceWithTaskBox() async {
        let box = TaskBox()
        var receivedValues: [Int] = []
        let asyncSequence = AsyncStream<Int> { continuation in
            Task {
                continuation.yield(10)
                continuation.yield(20)
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: { value in
                receivedValues.append(value)
            }
        )

        task.store(in: box)
        await task.value

        #expect(receivedValues == [10, 20])
    }

    @Test("run to async sequence with different element types")
    func testRunToAsyncSequenceWithDifferentTypes() async {
        var stringValues: [String] = []
        let stringSequence = AsyncStream<String> { continuation in
            continuation.yield("hello")
            continuation.yield("world")
            continuation.finish()
        }
        let stringTask = Task.run(
            sequence: stringSequence,
            onValue: { value in
                stringValues.append(value)
            }
        )

        await stringTask.value

        #expect(stringValues == ["hello", "world"])

        struct TestData: Sendable, Equatable {
            let id: Int
            let name: String
        }
        var structValues: [TestData] = []
        let structSequence = AsyncStream<TestData> { continuation in
            continuation.yield(TestData(id: 1, name: "first"))
            continuation.yield(TestData(id: 2, name: "second"))
            continuation.finish()
        }
        let structTask = Task.run(
            sequence: structSequence,
            onValue: { value in
                structValues.append(value)
            }
        )

        await structTask.value

        #expect(structValues == [TestData(id: 1, name: "first"), TestData(id: 2, name: "second")])
    }

    @Test("run to async sequence callback execution order")
    func testAsyncSequenceCallbackExecutionOrder() async {
        var callOrder: [String] = []
        let asyncSequence = AsyncStream<Int> { continuation in
            Task {
                continuation.yield(1)
                continuation.yield(2)
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: { value in
                callOrder.append("onValue-\(value)")
            },
            onCompleted: {
                callOrder.append("onCompleted")
            }
        )

        await task.value

        #expect(callOrder == ["onValue-1", "onValue-2", "onCompleted"])
    }

    @Test("run to async sequence error callback execution order")
    func testAsyncSequenceErrorCallbackExecutionOrder() async {
        var callOrder: [String] = []
        struct TestError: Error {}
        let asyncSequence = AsyncThrowingStream<Int, Error> { continuation in
            Task {
                continuation.yield(1)
                try? await Task.sleep(nanoseconds: .millisecond)
                callOrder.append("beforeError")
                try? await Task.sleep(nanoseconds: .millisecond)
                continuation.finish(throwing: TestError())
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: { value in
                callOrder.append("onValue-\(value)")
            },
            onError: { _ in
                callOrder.append("onError")
            },
            onCompleted: {
                callOrder.append("onCompleted")
            }
        )

        await task.value

        #expect(callOrder == ["onValue-1", "beforeError", "onError", "onCompleted"])
    }

    @Test("run to async sequence handles cancellation during iteration")
    func testAsyncSequenceCancellationDuringIteration() async {
        var receivedValues: [Int] = []
        var completedCalled = false
        let asyncSequence = AsyncStream<Int> { continuation in
            Task {
                continuation.yield(1)
                continuation.yield(2)
                try? await Task.sleep(nanoseconds: .second)
                continuation.yield(3)
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: { value in
                receivedValues.append(value)
            },
            onCompleted: {
                completedCalled = true
            }
        )
        Task {
            try? await Task.sleep(nanoseconds: .millisecond * 10)
            task.cancel()
        }

        await task.value

        #expect(receivedValues.count >= 1)
        #expect(completedCalled == true)
    }

    @Test("run to async sequence with immediate error")
    func testAsyncSequenceWithImmediateError() async {
        var valueCallCount = 0
        var errorCalled = false
        var completedCalled = false
        struct ImmediateError: Error {}
        let asyncSequence = AsyncThrowingStream<String, Error> { continuation in
            continuation.finish(throwing: ImmediateError())
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: { _ in
                valueCallCount += 1
            },
            onError: { _ in
                errorCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(valueCallCount == 0)
        #expect(errorCalled == true)
        #expect(completedCalled == true)
    }

    @Test("run to async sequence calls onCanceled when task is cancelled")
    func testAsyncSequenceCancellationCallsOnCanceled() async {
        var receivedValues: [Int] = []
        var cancelledCalled = false
        var completedCalled = false
        let asyncSequence = AsyncStream<Int> { continuation in
            Task {
                continuation.yield(1)
                try? await Task.sleep(nanoseconds: .second)
                continuation.yield(2)
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: { value in
                receivedValues.append(value)
            },
            onCanceled: {
                cancelledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )
        Task {
            try? await Task.sleep(nanoseconds: .millisecond * 10)
            task.cancel()
        }

        await task.value

        #expect(receivedValues == [1])
        #expect(cancelledCalled == true)
        #expect(completedCalled == true)
    }

    @Test("run to async sequence calls onCanceled when task is cancelled after error")
    func testAsyncSequenceCancellationAfterError() async {
        var receivedValues: [String] = []
        var errorCalled = false
        var cancelledCalled = false
        var completedCalled = false
        struct TestError: Error {}
        let asyncSequence = AsyncThrowingStream<String, Error> { continuation in
            Task {
                continuation.yield("value1")
                try? await Task.sleep(nanoseconds: .second)
                continuation.finish(throwing: TestError())
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: { value in
                receivedValues.append(value)
            },
            onError: { _ in
                errorCalled = true
            },
            onCanceled: {
                cancelledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )
        Task {
            try? await Task.sleep(nanoseconds: .millisecond * 10)
            task.cancel()
        }

        await task.value

        #expect(receivedValues == ["value1"])
        #expect(errorCalled == false)
        #expect(cancelledCalled == true)
        #expect(completedCalled == true)
    }

    @Test("run to async sequence onCanceled not called on normal completion")
    func testAsyncSequenceOnCanceledNotCalledOnNormalCompletion() async {
        var receivedValues: [Int] = []
        var cancelledCalled = false
        var completedCalled = false
        let values = [1, 2, 3]
        let asyncSequence = AsyncStream<Int> { continuation in
            Task {
                for value in values {
                    continuation.yield(value)
                }
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: { value in
                receivedValues.append(value)
            },
            onCanceled: {
                cancelledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(receivedValues == values)
        #expect(cancelledCalled == false)
        #expect(completedCalled == true)
    }

    @Test("run to async sequence onCanceled not called on error without cancellation")
    func testAsyncSequenceOnCanceledNotCalledOnError() async {
        var receivedValue: String?
        var errorCalled = false
        var cancelledCalled = false
        var completedCalled = false
        struct TestError: Error {}
        let asyncSequence = AsyncThrowingStream<String, Error> { continuation in
            Task {
                continuation.yield("value")
                continuation.finish(throwing: TestError())
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: { value in
                receivedValue = value
            },
            onError: { _ in
                errorCalled = true
            },
            onCanceled: {
                cancelledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(receivedValue == "value")
        #expect(errorCalled == true)
        #expect(cancelledCalled == false)
        #expect(completedCalled == true)
    }

    @Test("run to async sequence cancellation callback execution order")
    func testAsyncSequenceCancellationCallbackExecutionOrder() async {
        var callOrder: [String] = []
        let asyncSequence = AsyncStream<Int> { continuation in
            Task {
                continuation.yield(1)
                try? await Task.sleep(nanoseconds: .second)
                continuation.yield(2)
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: { value in
                callOrder.append("onValue-\(value)")
            },
            onCanceled: {
                callOrder.append("onCanceled")
            },
            onCompleted: {
                callOrder.append("onCompleted")
            }
        )
        Task {
            try? await Task.sleep(nanoseconds: .millisecond * 10)
            task.cancel()
        }

        await task.value

        #expect(callOrder == ["onValue-1", "onCanceled", "onCompleted"])
    }

    @Test("run to async sequence with immediate cancellation")
    func testAsyncSequenceWithImmediateCancellation() async {
        var valueCallCount = 0
        var cancelledCalled = false
        var completedCalled = false
        let asyncSequence = AsyncStream<Int> { continuation in
            Task {
                try? await Task.sleep(nanoseconds: .second)
                continuation.yield(1)
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: { _ in
                valueCallCount += 1
            },
            onCanceled: {
                cancelledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        task.cancel()
        await task.value

        #expect(valueCallCount == 0)
        #expect(cancelledCalled == true)
        #expect(completedCalled == true)
    }

    @Test("run to async sequence calls onCanceled when cancelled during error")
    func testAsyncSequenceCancellationDuringError() async {
        var receivedValues: [String] = []
        var errorCalled = false
        var cancelledCalled = false
        var completedCalled = false
        struct TestError: Error {}
        let asyncSequence = AsyncThrowingStream<String, Error> { continuation in
            Task {
                continuation.yield("value1")
                try? await Task.sleep(nanoseconds: .millisecond * 5)
                continuation.finish(throwing: TestError())
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: { value in
                receivedValues.append(value)
            },
            onError: { _ in
                errorCalled = true
            },
            onCanceled: {
                cancelledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        Task {
            try? await Task.sleep(nanoseconds: .millisecond * 5)
            task.cancel()
        }

        await task.value

        #expect(receivedValues == ["value1"])
        #expect(errorCalled == false)
        #expect(cancelledCalled == true)
        #expect(completedCalled == true)
    }

    @Test("run to async sequence cancellation check between values")
    func testAsyncSequenceCancellationBetweenValues() async {
        var receivedValues: [String] = []
        var cancelledCalled = false
        var completedCalled = false
        let asyncSequence = AsyncStream<String> { continuation in
            Task {
                continuation.yield("first")
                try? await Task.sleep(nanoseconds: .millisecond * 100)
                continuation.yield("second")
                continuation.yield("third")
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: { value in
                receivedValues.append(value)
            },
            onCanceled: {
                cancelledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )
        Task {
            while receivedValues.isEmpty {
                try? await Task.sleep(nanoseconds: .millisecond)
            }
            task.cancel()
        }

        await task.value

        #expect(receivedValues == ["first"])
        #expect(cancelledCalled == true)
        #expect(completedCalled == true)
    }

    @Test("run to void async sequence receives all values")
    func testRunToVoidAsyncSequenceReceivesAllValues() async {
        var valueCount = 0
        var completedCalled = false
        var errorCalled = false
        let numberOfValues = 5
        let asyncSequence = AsyncStream<Void> { continuation in
            Task {
                for _ in 0..<numberOfValues {
                    continuation.yield(())
                }
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: {
                valueCount += 1
            },
            onError: { _ in
                errorCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(valueCount == numberOfValues)
        #expect(completedCalled == true)
        #expect(errorCalled == false)
    }

    @Test("run to void async sequence handles errors")
    func testRunToVoidAsyncSequenceHandlesErrors() async {
        var valueCount = 0
        var receivedError: Error?
        var completedCalled = false
        struct TestError: Error, Equatable {}
        let asyncSequence = AsyncThrowingStream<Void, Error> { continuation in
            Task {
                continuation.yield(())
                continuation.yield(())
                continuation.finish(throwing: TestError())
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: {
                valueCount += 1
            },
            onError: { error in
                receivedError = error
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(valueCount == 2)
        #expect(receivedError is TestError)
        #expect(completedCalled == true)
    }

    @Test("run to void async sequence handles errors completion")
    func testRunToVoidAsyncSequenceHandlesErrorsCompletion() async {
        var valueCount = 0
        var completedCalled = false
        struct TestError: Error, Equatable {}
        let asyncSequence = AsyncThrowingStream<Void, Error> { continuation in
            Task {
                continuation.yield(())
                continuation.yield(())
                continuation.finish(throwing: TestError())
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: {
                valueCount += 1
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(valueCount == 2)
        #expect(completedCalled == true)
    }

    @Test("run to void async sequence with default callbacks")
    func testRunToVoidAsyncSequenceWithDefaultCallbacks() async {
        var valueCount = 0
        let numberOfValues = 3
        let asyncSequence = AsyncStream<Void> { continuation in
            Task {
                for _ in 0..<numberOfValues {
                    continuation.yield(())
                }
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: {
                valueCount += 1
            }
        )

        await task.value

        #expect(valueCount == numberOfValues)
    }

    @Test("run to empty void async sequence calls completion")
    func testRunToEmptyVoidAsyncSequence() async {
        var valueCallCount = 0
        var completedCalled = false
        var errorCalled = false
        let asyncSequence = AsyncStream<Void> { continuation in
            continuation.finish()
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: {
                valueCallCount += 1
            },
            onError: { _ in
                errorCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(valueCallCount == 0)
        #expect(completedCalled == true)
        #expect(errorCalled == false)
    }

    @Test("run to void async sequence respects task name and priority")
    func testRunToVoidAsyncSequenceWithNameAndPriority() async {
        let taskName = "void-async-sequence-task"
        let taskPriority = TaskPriority.high
        var valueReceived = false
        let asyncSequence = AsyncStream<Void> { continuation in
            continuation.yield(())
            continuation.finish()
        }
        let task = Task.run(
            name: taskName,
            priority: taskPriority,
            sequence: asyncSequence,
            onValue: {
                valueReceived = true
            }
        )

        await task.value

        #expect(valueReceived == true)
        #expect(task.isCancelled == false)
    }

    @Test("run to void async sequence can be stored in TaskBox")
    func testRunToVoidAsyncSequenceWithTaskBox() async {
        let box = TaskBox()
        var valueCount = 0
        let asyncSequence = AsyncStream<Void> { continuation in
            Task {
                continuation.yield(())
                continuation.yield(())
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: {
                valueCount += 1
            }
        )

        task.store(in: box)
        await task.value

        #expect(valueCount == 2)
    }

    @Test("run to void async sequence callback execution order")
    func testVoidAsyncSequenceCallbackExecutionOrder() async {
        var callOrder: [String] = []
        let asyncSequence = AsyncStream<Void> { continuation in
            Task {
                continuation.yield(())
                continuation.yield(())
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: {
                callOrder.append("onValue")
            },
            onCompleted: {
                callOrder.append("onCompleted")
            }
        )

        await task.value

        #expect(callOrder == ["onValue", "onValue", "onCompleted"])
    }

    @Test("run to void async sequence error callback execution order")
    func testVoidAsyncSequenceErrorCallbackExecutionOrder() async {
        var callOrder: [String] = []
        struct TestError: Error {}
        let asyncSequence = AsyncThrowingStream<Void, Error> { continuation in
            Task {
                continuation.yield(())
                try? await Task.sleep(nanoseconds: .millisecond)
                callOrder.append("beforeError")
                try? await Task.sleep(nanoseconds: .millisecond)
                continuation.finish(throwing: TestError())
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: {
                callOrder.append("onValue")
            },
            onError: { _ in
                callOrder.append("onError")
            },
            onCompleted: {
                callOrder.append("onCompleted")
            }
        )

        await task.value

        #expect(callOrder == ["onValue", "beforeError", "onError", "onCompleted"])
    }

    @Test("run to void async sequence handles cancellation during iteration")
    func testVoidAsyncSequenceCancellationDuringIteration() async {
        var valueCount = 0
        var completedCalled = false
        let asyncSequence = AsyncStream<Void> { continuation in
            Task {
                continuation.yield(())
                continuation.yield(())
                try? await Task.sleep(nanoseconds: .second)
                continuation.yield(())
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: {
                valueCount += 1
            },
            onCompleted: {
                completedCalled = true
            }
        )
        Task {
            try? await Task.sleep(nanoseconds: .millisecond * 10)
            task.cancel()
        }

        await task.value

        #expect(valueCount >= 1)
        #expect(completedCalled == true)
    }

    @Test("run to void async sequence with immediate error")
    func testVoidAsyncSequenceWithImmediateError() async {
        var valueCallCount = 0
        var errorCalled = false
        var completedCalled = false
        struct ImmediateError: Error {}
        let asyncSequence = AsyncThrowingStream<Void, Error> { continuation in
            continuation.finish(throwing: ImmediateError())
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: {
                valueCallCount += 1
            },
            onError: { _ in
                errorCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(valueCallCount == 0)
        #expect(errorCalled == true)
        #expect(completedCalled == true)
    }

    @Test("run to void async sequence calls onCanceled when task is cancelled")
    func testVoidAsyncSequenceCancellationCallsOnCanceled() async {
        var valueCount = 0
        var cancelledCalled = false
        var completedCalled = false
        let asyncSequence = AsyncStream<Void> { continuation in
            Task {
                continuation.yield(())
                try? await Task.sleep(nanoseconds: .second)
                continuation.yield(())
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: {
                valueCount += 1
            },
            onCanceled: {
                cancelledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )
        Task {
            try? await Task.sleep(nanoseconds: .millisecond * 10)
            task.cancel()
        }

        await task.value

        #expect(valueCount == 1)
        #expect(cancelledCalled == true)
        #expect(completedCalled == true)
    }

    @Test("run to void async sequence calls onCanceled when task is cancelled after error")
    func testVoidAsyncSequenceCancellationAfterError() async {
        var valueCount = 0
        var errorCalled = false
        var cancelledCalled = false
        var completedCalled = false
        struct TestError: Error {}
        let asyncSequence = AsyncThrowingStream<Void, Error> { continuation in
            Task {
                continuation.yield(())
                try? await Task.sleep(nanoseconds: .second)
                continuation.finish(throwing: TestError())
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: {
                valueCount += 1
            },
            onError: { _ in
                errorCalled = true
            },
            onCanceled: {
                cancelledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )
        Task {
            try? await Task.sleep(nanoseconds: .millisecond * 10)
            task.cancel()
        }

        await task.value

        #expect(valueCount == 1)
        #expect(errorCalled == false)
        #expect(cancelledCalled == true)
        #expect(completedCalled == true)
    }

    @Test("run to void async sequence onCanceled not called on normal completion")
    func testVoidAsyncSequenceOnCanceledNotCalledOnNormalCompletion() async {
        var valueCount = 0
        var cancelledCalled = false
        var completedCalled = false
        let numberOfValues = 3
        let asyncSequence = AsyncStream<Void> { continuation in
            Task {
                for _ in 0..<numberOfValues {
                    continuation.yield(())
                }
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: {
                valueCount += 1
            },
            onCanceled: {
                cancelledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(valueCount == numberOfValues)
        #expect(cancelledCalled == false)
        #expect(completedCalled == true)
    }

    @Test("run to void async sequence onCanceled not called on error without cancellation")
    func testVoidAsyncSequenceOnCanceledNotCalledOnError() async {
        var valueReceived = false
        var errorCalled = false
        var cancelledCalled = false
        var completedCalled = false
        struct TestError: Error {}
        let asyncSequence = AsyncThrowingStream<Void, Error> { continuation in
            Task {
                continuation.yield(())
                continuation.finish(throwing: TestError())
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: {
                valueReceived = true
            },
            onError: { _ in
                errorCalled = true
            },
            onCanceled: {
                cancelledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(valueReceived == true)
        #expect(errorCalled == true)
        #expect(cancelledCalled == false)
        #expect(completedCalled == true)
    }

    @Test("run to void async sequence cancellation callback execution order")
    func testVoidAsyncSequenceCancellationCallbackExecutionOrder() async {
        var callOrder: [String] = []
        let asyncSequence = AsyncStream<Void> { continuation in
            Task {
                continuation.yield(())
                try? await Task.sleep(nanoseconds: .second)
                continuation.yield(())
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: {
                callOrder.append("onValue")
            },
            onCanceled: {
                callOrder.append("onCanceled")
            },
            onCompleted: {
                callOrder.append("onCompleted")
            }
        )
        Task {
            try? await Task.sleep(nanoseconds: .millisecond * 10)
            task.cancel()
        }

        await task.value

        #expect(callOrder == ["onValue", "onCanceled", "onCompleted"])
    }

    @Test("run to void async sequence with immediate cancellation")
    func testVoidAsyncSequenceWithImmediateCancellation() async {
        var valueCallCount = 0
        var cancelledCalled = false
        var completedCalled = false
        let asyncSequence = AsyncStream<Void> { continuation in
            Task {
                try? await Task.sleep(nanoseconds: .second)
                continuation.yield(())
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: {
                valueCallCount += 1
            },
            onCanceled: {
                cancelledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        task.cancel()
        await task.value

        #expect(valueCallCount == 0)
        #expect(cancelledCalled == true)
        #expect(completedCalled == true)
    }

    @Test("run to void async sequence calls onCanceled when cancelled during error")
    func testVoidAsyncSequenceCancellationDuringError() async {
        var valueCount = 0
        var errorCalled = false
        var cancelledCalled = false
        var completedCalled = false
        struct TestError: Error {}
        let asyncSequence = AsyncThrowingStream<Void, Error> { continuation in
            Task {
                continuation.yield(())
                try? await Task.sleep(nanoseconds: .millisecond * 5)
                continuation.finish(throwing: TestError())
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: {
                valueCount += 1
            },
            onError: { _ in
                errorCalled = true
            },
            onCanceled: {
                cancelledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        Task {
            try? await Task.sleep(nanoseconds: .millisecond * 5)
            task.cancel()
        }

        await task.value

        #expect(valueCount == 1)
        #expect(errorCalled == false)
        #expect(cancelledCalled == true)
        #expect(completedCalled == true)
    }

    @Test("run to void async sequence cancellation check between values")
    func testVoidAsyncSequenceCancellationBetweenValues() async {
        var valueCount = 0
        var cancelledCalled = false
        var completedCalled = false
        let asyncSequence = AsyncStream<Void> { continuation in
            Task {
                continuation.yield(())
                try? await Task.sleep(nanoseconds: .millisecond * 100)
                continuation.yield(())
                continuation.yield(())
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: {
                valueCount += 1
            },
            onCanceled: {
                cancelledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )
        Task {
            while valueCount == 0 {
                try? await Task.sleep(nanoseconds: .millisecond)
            }
            task.cancel()
        }

        await task.value

        #expect(valueCount == 1)
        #expect(cancelledCalled == true)
        #expect(completedCalled == true)
    }

    @Test("run to void async sequence signal counting")
    func testVoidAsyncSequenceSignalCounting() async {
        var signalCount = 0
        var completedCalled = false
        let numberOfSignals = 10
        let asyncSequence = AsyncStream<Void> { continuation in
            Task {
                for _ in 0..<numberOfSignals {
                    continuation.yield(())
                    try? await Task.sleep(nanoseconds: .millisecond)
                }
                continuation.finish()
            }
        }
        let task = Task.run(
            sequence: asyncSequence,
            onValue: {
                signalCount += 1
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(signalCount == numberOfSignals)
        #expect(completedCalled == true)
    }
}
