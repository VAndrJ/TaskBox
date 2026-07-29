//
//  TaskRunTests.swift
//  TaskBox
//
//  Created by VAndrJ on 16.08.2025.
//

import Testing

@testable import TaskBox

@Suite(.timeLimit(.minutes(1)))
struct TaskRunNonThrowingTests {
    @Test("run executes operation and calls onSuccess when not cancelled")
    func testRunSuccessFlow() async {
        var successCalled = false
        var cancelledCalled = false
        var completedCalled = false
        var resultValue: String?
        let expectedResult = "test result"
        let task = Task.run(
            operation: {
                return expectedResult
            },
            onSuccess: { result in
                successCalled = true
                resultValue = result
            },
            onCanceled: {
                cancelledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(successCalled == true)
        #expect(cancelledCalled == false)
        #expect(completedCalled == true)
        #expect(resultValue == expectedResult)
    }

    @Test("run calls onCanceled when task is cancelled before completion")
    func testRunCancelledFlow() async {
        var successCalled = false
        var cancelledCalled = false
        var completedCalled = false
        let task = Task.run(
            operation: {
                try? await Task.sleep(nanoseconds: .second)
                return "result"
            },
            onSuccess: { _ in
                successCalled = true
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

        #expect(successCalled == false)
        #expect(cancelledCalled == true)
        #expect(completedCalled == true)
    }

    @Test("run calls onCompleted when task is cancelled before completion")
    func testRunCancelledCompletionFlow() async {
        var successCalled = false
        var completedCalled = false
        let task = Task.run(
            operation: {
                try? await Task.sleep(nanoseconds: .second)
                return "result"
            },
            onSuccess: { _ in
                successCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        task.cancel()
        await task.value

        #expect(successCalled == false)
        #expect(completedCalled == true)
    }

    @Test("run calls onCompleted regardless of cancellation")
    func testRunAlwaysCallsCompleted() async {
        var completedCalled = false
        let task = Task.run(
            operation: {
                return 42
            },
            onSuccess: { _ in
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(completedCalled == true)
    }

    @Test("run with default callbacks works correctly")
    func testRunWithDefaultCallbacks() async {
        var successCalled = false
        var resultValue: Int?
        let task = Task.run(
            operation: {
                return 123
            },
            onSuccess: { result in
                successCalled = true
                resultValue = result
            }
        )

        await task.value

        #expect(successCalled == true)
        #expect(resultValue == 123)
    }

    @Test("run respects task name and priority")
    func testRunWithNameAndPriority() async {
        let taskName = "test-task"
        let taskPriority = TaskPriority.high
        let task = Task.run(
            name: taskName,
            priority: taskPriority,
            operation: {
                return "result"
            },
            onSuccess: { _ in }
        )

        await task.value

        #expect(task.isCancelled == false)
    }

    @Test("run can be stored in TaskBox")
    func testRunWithTaskBox() async {
        let box = TaskBox()
        var successCalled = false
        let task = Task.run(
            operation: {
                return "stored task result"
            },
            onSuccess: { _ in
                successCalled = true
            }
        )

        task.store(in: box)
        await task.value

        #expect(successCalled == true)
    }

    @Test("run with different result types")
    func testRunWithDifferentTypes() async {
        var stringResult: String?
        let stringTask = Task.run(
            operation: {
                return "hello"
            },
            onSuccess: { result in
                stringResult = result
            }
        )

        await stringTask.value

        #expect(stringResult == "hello")

        var intResult: Int?
        let intTask = Task.run(
            operation: {
                return 42
            },
            onSuccess: { result in
                intResult = result
            }
        )

        await intTask.value

        #expect(intResult == 42)

        struct TestData: Sendable, Equatable {
            let id: Int
            let name: String
        }
        var structResult: TestData?
        let structTask = Task.run(
            operation: {
                return TestData(id: 1, name: "test")
            },
            onSuccess: { result in
                structResult = result
            }
        )

        await structTask.value

        #expect(structResult == TestData(id: 1, name: "test"))
    }

    @Test("run callback execution order")
    func testCallbackExecutionOrder() async {
        var callOrder: [String] = []
        let task = Task.run(
            operation: {
                callOrder.append("operation")
                return "result"
            },
            onSuccess: { _ in
                callOrder.append("onSuccess")
            },
            onCompleted: {
                callOrder.append("onCompleted")
            }
        )

        await task.value

        #expect(callOrder == ["operation", "onSuccess", "onCompleted"])
    }

    @Test("run cancelled callback execution order")
    func testCancelledCallbackExecutionOrder() async {
        var callOrder: [String] = []

        let task = Task.run(
            operation: {
                callOrder.append("operation")
                try? await Task.sleep(nanoseconds: .second)
                return "result"
            },
            onSuccess: { _ in
                callOrder.append("onSuccess")
            },
            onCanceled: {
                callOrder.append("onCanceled")
            },
            onCompleted: {
                callOrder.append("onCompleted")
            }
        )

        task.cancel()
        await task.value

        #expect(callOrder == ["operation", "onCanceled", "onCompleted"])
    }

    @Test("run void operation executes and calls onSuccess when not cancelled")
    func testRunVoidSuccessFlow() async {
        var operationCalled = false
        var successCalled = false
        var cancelledCalled = false
        var completedCalled = false
        let task = Task.run(
            operation: {
                operationCalled = true
            },
            onSuccess: {
                successCalled = true
            },
            onCanceled: {
                cancelledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(operationCalled == true)
        #expect(successCalled == true)
        #expect(cancelledCalled == false)
        #expect(completedCalled == true)
    }

    @Test("run void operation calls onCanceled when task is cancelled before completion")
    func testRunVoidCancelledFlow() async {
        var operationCalled = false
        var successCalled = false
        var cancelledCalled = false
        var completedCalled = false
        let task = Task.run(
            operation: {
                operationCalled = true
                try? await Task.sleep(nanoseconds: .second)
            },
            onSuccess: {
                successCalled = true
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

        #expect(operationCalled == true)
        #expect(successCalled == false)
        #expect(cancelledCalled == true)
        #expect(completedCalled == true)
    }

    @Test("run void operation calls onCompleted when task is cancelled before completion")
    func testRunVoidCancelledCompletionFlow() async {
        var operationCalled = false
        var successCalled = false
        var completedCalled = false
        let task = Task.run(
            operation: {
                operationCalled = true
                try? await Task.sleep(nanoseconds: .second)
            },
            onSuccess: {
                successCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        task.cancel()
        await task.value

        #expect(operationCalled == true)
        #expect(successCalled == false)
        #expect(completedCalled == true)
    }

    @Test("run void operation calls onCompleted regardless of cancellation")
    func testRunVoidAlwaysCallsCompleted() async {
        var operationCalled = false
        var completedCalled = false
        let task = Task.run(
            operation: {
                operationCalled = true
            },
            onSuccess: {
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(operationCalled == true)
        #expect(completedCalled == true)
    }

    @Test("run void operation with default callbacks works correctly")
    func testRunVoidWithDefaultCallbacks() async {
        var operationCalled = false
        var successCalled = false
        let task = Task.run(
            operation: {
                operationCalled = true
            },
            onSuccess: {
                successCalled = true
            }
        )

        await task.value

        #expect(operationCalled == true)
        #expect(successCalled == true)
    }

    @Test("run void operation respects task name and priority")
    func testRunVoidWithNameAndPriority() async {
        let taskName = "test-void-task"
        let taskPriority = TaskPriority.high
        var operationCalled = false
        let task = Task.run(
            name: taskName,
            priority: taskPriority,
            operation: {
                operationCalled = true
            },
            onSuccess: {}
        )

        await task.value

        #expect(operationCalled == true)
        #expect(task.isCancelled == false)
    }

    @Test("run void operation can be stored in TaskBox")
    func testRunVoidWithTaskBox() async {
        let box = TaskBox()
        var operationCalled = false
        var successCalled = false
        let task = Task.run(
            operation: {
                operationCalled = true
            },
            onSuccess: {
                successCalled = true
            }
        )

        task.store(in: box)
        await task.value

        #expect(operationCalled == true)
        #expect(successCalled == true)
    }

    @Test("run void operation callback execution order")
    func testVoidCallbackExecutionOrder() async {
        var callOrder: [String] = []
        let task = Task.run(
            operation: {
                callOrder.append("operation")
            },
            onSuccess: {
                callOrder.append("onSuccess")
            },
            onCompleted: {
                callOrder.append("onCompleted")
            }
        )

        await task.value

        #expect(callOrder == ["operation", "onSuccess", "onCompleted"])
    }

    @Test("run void operation cancelled callback execution order")
    func testVoidCancelledCallbackExecutionOrder() async {
        var callOrder: [String] = []
        let task = Task.run(
            operation: {
                callOrder.append("operation")
                try? await Task.sleep(nanoseconds: .second)
            },
            onSuccess: {
                callOrder.append("onSuccess")
            },
            onCanceled: {
                callOrder.append("onCanceled")
            },
            onCompleted: {
                callOrder.append("onCompleted")
            }
        )

        task.cancel()
        await task.value

        #expect(callOrder == ["operation", "onCanceled", "onCompleted"])
    }

    @Test("operation run overloads inherit a custom actor context")
    func testOperationRunOverloadsInheritCustomActorContext() async {
        let recorder = TaskRunActorRecorder()

        let callOrder = await recorder.exerciseAllOverloads()

        #expect(
            callOrder == [
                "resultOperation",
                "resultSuccess",
                "resultCompleted",
                "voidOperation",
                "voidSuccess",
                "voidCompleted",
                "throwingResultOperation",
                "throwingResultError",
                "throwingResultCompleted",
                "throwingVoidOperation",
                "throwingVoidError",
                "throwingVoidCompleted",
            ]
        )
    }
}

private actor TaskRunActorRecorder {
    private var callOrder: [String] = []

    func exerciseAllOverloads() async -> [String] {
        struct TestError: Error {}

        let resultTask = Task.run(
            operation: {
                self.callOrder.append("resultOperation")
                return 1
            },
            onSuccess: { _ in
                self.callOrder.append("resultSuccess")
            },
            onCompleted: {
                self.callOrder.append("resultCompleted")
            }
        )
        await resultTask.value

        let voidTask = Task.run(
            operation: {
                self.callOrder.append("voidOperation")
            },
            onSuccess: {
                self.callOrder.append("voidSuccess")
            },
            onCompleted: {
                self.callOrder.append("voidCompleted")
            }
        )
        await voidTask.value

        let throwingResultTask = Task.run(
            operation: { () async throws -> Int in
                self.callOrder.append("throwingResultOperation")
                throw TestError()
            },
            onSuccess: { _ in },
            onError: { _ in
                self.callOrder.append("throwingResultError")
            },
            onCompleted: {
                self.callOrder.append("throwingResultCompleted")
            }
        )
        await throwingResultTask.value

        let throwingVoidTask = Task.run(
            operation: { () async throws -> Void in
                self.callOrder.append("throwingVoidOperation")
                throw TestError()
            },
            onSuccess: {},
            onError: { _ in
                self.callOrder.append("throwingVoidError")
            },
            onCompleted: {
                self.callOrder.append("throwingVoidCompleted")
            }
        )
        await throwingVoidTask.value

        return callOrder
    }
}
