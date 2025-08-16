//
//  TaskRunThrowingTests.swift
//  TaskBox
//
//  Created by VAndrJ on 16.08.2025.
//

import Testing

@testable import TaskBox

@Suite
struct TaskRunThrowingTests {
    @Test("run executes throwing operation and calls onSuccess when not canceled")
    func testRunThrowingSuccessFlow() async {
        var successCalled = false
        var errorCalled = false
        var canceledCalled = false
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
            onError: { _ in
                errorCalled = true
            },
            onCanceled: {
                canceledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(successCalled == true)
        #expect(errorCalled == false)
        #expect(canceledCalled == false)
        #expect(completedCalled == true)
        #expect(resultValue == expectedResult)
    }

    @Test("run calls onError when operation throws")
    func testRunThrowingErrorFlow() async {
        var successCalled = false
        var errorCalled = false
        var canceledCalled = false
        var completedCalled = false
        var capturedError: Error?
        struct TestError: Error, Equatable {
            let message: String
        }
        let expectedError = TestError(message: "test error")
        let task = Task.run(
            operation: {
                throw expectedError
            },
            onSuccess: { _ in
                successCalled = true
            },
            onError: { error in
                errorCalled = true
                capturedError = error
            },
            onCanceled: {
                canceledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(successCalled == false)
        #expect(errorCalled == true)
        #expect(canceledCalled == false)
        #expect(completedCalled == true)
        #expect(capturedError as? TestError == expectedError)
    }

    @Test("run calls onCanceled when task is canceled before completion")
    func testRunThrowingCanceledFlow() async {
        var successCalled = false
        var errorCalled = false
        var canceledCalled = false
        var completedCalled = false
        let task = Task.run(
            operation: {
                return await TestClass().longTask()
            },
            onSuccess: { _ in
                successCalled = true
            },
            onError: { _ in
                errorCalled = true
            },
            onCanceled: {
                canceledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        try? await Task.sleep(nanoseconds: .millisecond * 10)
        task.cancel()
        await task.value

        #expect(successCalled == false)
        #expect(errorCalled == false)
        #expect(canceledCalled == true)
        #expect(completedCalled == true)
    }

    @Test("run calls onCanceled when task is canceled after error")
    func testRunThrowingCanceledAfterErrorFlow() async {
        var successCalled = false
        var errorCalled = false
        var canceledCalled = false
        var completedCalled = false
        struct TestError: Error {}
        let task = Task.run(
            operation: {
                try await Task.sleep(nanoseconds: .second)
                throw TestError()
            },
            onSuccess: { _ in
                successCalled = true
            },
            onError: { _ in
                errorCalled = true
            },
            onCanceled: {
                canceledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        task.cancel()
        await task.value

        #expect(successCalled == false)
        #expect(errorCalled == false)
        #expect(canceledCalled == true)
        #expect(completedCalled == true)
    }

    @Test("run calls onCompleted regardless of outcome")
    func testRunThrowingAlwaysCallsCompleted() async {
        var completedCalled = false
        let task = Task.run(
            operation: {
                return 42
            },
            onSuccess: { _ in },
            onError: { _ in },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(completedCalled == true)
    }

    @Test("run with default callbacks works correctly")
    func testRunThrowingWithDefaultCallbacks() async {
        var successCalled = false
        var resultValue: Int?
        let task = Task.run(
            operation: {
                return 123
            },
            onSuccess: { result in
                successCalled = true
                resultValue = result
            },
            onError: { _ in }
        )

        await task.value

        #expect(successCalled == true)
        #expect(resultValue == 123)
    }

    @Test("run respects task name and priority")
    func testRunThrowingWithNameAndPriority() async {
        let taskName = "test-throwing-task"
        let taskPriority = TaskPriority.high
        let task = Task.run(
            name: taskName,
            priority: taskPriority,
            operation: {
                return "result"
            },
            onSuccess: { _ in },
            onError: { _ in }
        )

        await task.value

        #expect(task.isCancelled == false)
    }

    @Test("run can be stored in TaskBox")
    func testRunThrowingWithTaskBox() async {
        let box = TaskBox()
        var successCalled = false
        let task = Task.run(
            operation: {
                return "stored task result"
            },
            onSuccess: { _ in
                successCalled = true
            },
            onError: { _ in }
        )

        task.store(in: box)
        await task.value

        #expect(successCalled == true)
    }

    @Test("run with different result types")
    func testRunThrowingWithDifferentTypes() async {
        var stringResult: String?
        let stringTask = Task.run(
            operation: {
                return "hello"
            },
            onSuccess: { result in
                stringResult = result
            },
            onError: { _ in }
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
            },
            onError: { _ in }
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
            },
            onError: { _ in }
        )

        await structTask.value

        #expect(structResult == TestData(id: 1, name: "test"))
    }

    @Test("run callback execution order for success")
    func testRunThrowingSuccessCallbackExecutionOrder() async {
        var callOrder: [String] = []
        let task = Task.run(
            operation: {
                callOrder.append("operation")
                return "result"
            },
            onSuccess: { _ in
                callOrder.append("onSuccess")
            },
            onError: { _ in
                callOrder.append("onError")
            },
            onCompleted: {
                callOrder.append("onCompleted")
            }
        )

        await task.value

        #expect(callOrder == ["operation", "onSuccess", "onCompleted"])
    }

    @Test("run callback execution order for error")
    func testRunThrowingErrorCallbackExecutionOrder() async {
        var callOrder: [String] = []
        struct TestError: Error {}
        let task = Task.run(
            operation: {
                callOrder.append("operation")
                throw TestError()
            },
            onSuccess: { _ in
                callOrder.append("onSuccess")
            },
            onError: { _ in
                callOrder.append("onError")
            },
            onCompleted: {
                callOrder.append("onCompleted")
            }
        )

        await task.value

        #expect(callOrder == ["operation", "onError", "onCompleted"])
    }

    @Test("run callback execution order for cancellation")
    func testRunThrowingCanceledCallbackExecutionOrder() async {
        var callOrder: [String] = []
        let task = Task.run(
            operation: {
                callOrder.append("operation")
                try await Task.sleep(nanoseconds: .second)
                return "result"
            },
            onSuccess: { _ in
                callOrder.append("onSuccess")
            },
            onError: { _ in
                callOrder.append("onError")
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

    @Test("run callback execution order for cancellation without onCanceled")
    func testRunThrowingCanceledWithoutCallbackExecutionOrder() async {
        var callOrder: [String] = []
        let task = Task.run(
            operation: {
                callOrder.append("operation")
                try await Task.sleep(nanoseconds: .second)
                return "result"
            },
            onSuccess: { _ in
                callOrder.append("onSuccess")
            },
            onError: { _ in
                callOrder.append("onError")
            },
            onCompleted: {
                callOrder.append("onCompleted")
            }
        )

        task.cancel()
        await task.value

        #expect(callOrder == ["operation", "onCompleted"])
    }

    @Test("run handles different error types")
    func testRunThrowingWithDifferentErrorTypes() async {
        enum CustomError: Error, Equatable {
            case networkError
            case validationError(String)
        }
        var capturedError: CustomError?
        let task = Task.run(
            operation: {
                throw CustomError.validationError("invalid input")
            },
            onSuccess: { (_: String) in },
            onError: { error in
                capturedError = error as? CustomError
            }
        )

        await task.value

        #expect(capturedError == CustomError.validationError("invalid input"))
    }

    @Test("run void throwing operation executes and calls onSuccess when not canceled")
    func testRunVoidThrowingSuccessFlow() async {
        var operationCalled = false
        var successCalled = false
        var errorCalled = false
        var canceledCalled = false
        var completedCalled = false
        let task = Task.run(
            operation: {
                operationCalled = true
            },
            onSuccess: {
                successCalled = true
            },
            onError: { _ in
                errorCalled = true
            },
            onCanceled: {
                canceledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(operationCalled == true)
        #expect(successCalled == true)
        #expect(errorCalled == false)
        #expect(canceledCalled == false)
        #expect(completedCalled == true)
    }

    @Test("run void throwing operation calls onError when operation throws")
    func testRunVoidThrowingErrorFlow() async {
        var operationCalled = false
        var successCalled = false
        var errorCalled = false
        var canceledCalled = false
        var completedCalled = false
        var capturedError: Error?
        struct TestError: Error, Equatable {
            let message: String
        }
        let expectedError = TestError(message: "test void error")
        let task = Task.run(
            operation: {
                operationCalled = true
                throw expectedError
            },
            onSuccess: {
                successCalled = true
            },
            onError: { error in
                errorCalled = true
                capturedError = error
            },
            onCanceled: {
                canceledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(operationCalled == true)
        #expect(successCalled == false)
        #expect(errorCalled == true)
        #expect(canceledCalled == false)
        #expect(completedCalled == true)
        #expect(capturedError as? TestError == expectedError)
    }

    @Test("run void throwing operation calls onCanceled when task is canceled before completion")
    func testRunVoidThrowingCanceledFlow() async {
        var operationCalled = false
        var successCalled = false
        var errorCalled = false
        var canceledCalled = false
        var completedCalled = false
        let task = Task.run(
            operation: {
                operationCalled = true
                try? await Task.sleep(nanoseconds: .second)
            },
            onSuccess: {
                successCalled = true
            },
            onError: { _ in
                errorCalled = true
            },
            onCanceled: {
                canceledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        task.cancel()
        await task.value

        #expect(operationCalled == true)
        #expect(successCalled == false)
        #expect(errorCalled == false)
        #expect(canceledCalled == true)
        #expect(completedCalled == true)
    }

    @Test("run void throwing operation calls onCanceled when task is canceled after error")
    func testRunVoidThrowingCanceledAfterErrorFlow() async {
        var operationCalled = false
        var successCalled = false
        var errorCalled = false
        var canceledCalled = false
        var completedCalled = false
        struct TestError: Error {}
        let task = Task.run(
            operation: {
                operationCalled = true
                try await Task.sleep(nanoseconds: .second)
                throw TestError()
            },
            onSuccess: {
                successCalled = true
            },
            onError: { _ in
                errorCalled = true
            },
            onCanceled: {
                canceledCalled = true
            },
            onCompleted: {
                completedCalled = true
            }
        )

        task.cancel()
        await task.value

        #expect(operationCalled == true)
        #expect(successCalled == false)
        #expect(errorCalled == false)
        #expect(canceledCalled == true)
        #expect(completedCalled == true)
    }

    @Test("run void throwing operation calls onCompleted regardless of outcome")
    func testRunVoidThrowingAlwaysCallsCompleted() async {
        var operationCalled = false
        var completedCalled = false
        let task = Task.run(
            operation: {
                operationCalled = true
            },
            onSuccess: {},
            onError: { _ in },
            onCompleted: {
                completedCalled = true
            }
        )

        await task.value

        #expect(operationCalled == true)
        #expect(completedCalled == true)
    }

    @Test("run void throwing operation with default callbacks works correctly")
    func testRunVoidThrowingWithDefaultCallbacks() async {
        var operationCalled = false
        var successCalled = false
        let task = Task.run(
            operation: {
                operationCalled = true
            },
            onSuccess: {
                successCalled = true
            },
            onError: { _ in }
        )

        await task.value

        #expect(operationCalled == true)
        #expect(successCalled == true)
    }

    @Test("run void throwing operation respects task name and priority")
    func testRunVoidThrowingWithNameAndPriority() async {
        let taskName = "test-void-throwing-task"
        let taskPriority = TaskPriority.high
        var operationCalled = false
        let task = Task.run(
            name: taskName,
            priority: taskPriority,
            operation: {
                operationCalled = true
            },
            onSuccess: {},
            onError: { _ in }
        )

        await task.value

        #expect(operationCalled == true)
        #expect(task.isCancelled == false)
    }

    @Test("run void throwing operation can be stored in TaskBox")
    func testRunVoidThrowingWithTaskBox() async {
        let box = TaskBox()
        var operationCalled = false
        var successCalled = false
        let task = Task.run(
            operation: {
                operationCalled = true
            },
            onSuccess: {
                successCalled = true
            },
            onError: { _ in }
        )

        task.store(in: box)
        await task.value

        #expect(operationCalled == true)
        #expect(successCalled == true)
    }

    @Test("run void throwing operation callback execution order for success")
    func testVoidThrowingSuccessCallbackExecutionOrder() async {
        var callOrder: [String] = []
        let task = Task.run(
            operation: {
                callOrder.append("operation")
            },
            onSuccess: {
                callOrder.append("onSuccess")
            },
            onError: { _ in
                callOrder.append("onError")
            },
            onCompleted: {
                callOrder.append("onCompleted")
            }
        )

        await task.value

        #expect(callOrder == ["operation", "onSuccess", "onCompleted"])
    }

    @Test("run void throwing operation callback execution order for error")
    func testVoidThrowingErrorCallbackExecutionOrder() async {
        var callOrder: [String] = []
        struct TestError: Error {}
        let task = Task.run(
            operation: {
                callOrder.append("operation")
                throw TestError()
            },
            onSuccess: {
                callOrder.append("onSuccess")
            },
            onError: { _ in
                callOrder.append("onError")
            },
            onCompleted: {
                callOrder.append("onCompleted")
            }
        )

        await task.value

        #expect(callOrder == ["operation", "onError", "onCompleted"])
    }

    @Test("run void throwing operation callback execution order for cancellation")
    func testVoidThrowingCanceledCallbackExecutionOrder() async {
        var callOrder: [String] = []
        let task = Task.run(
            operation: {
                callOrder.append("operation")
                try await Task.sleep(nanoseconds: .second)
            },
            onSuccess: {
                callOrder.append("onSuccess")
            },
            onError: { _ in
                callOrder.append("onError")
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

    @Test("run void throwing operation callback execution order for cancellation without onCanceled")
    func testVoidThrowingCanceledWithoutCallbackExecutionOrder() async {
        var callOrder: [String] = []
        let task = Task.run(
            operation: {
                callOrder.append("operation")
                try await Task.sleep(nanoseconds: .second)
            },
            onSuccess: {
                callOrder.append("onSuccess")
            },
            onError: { _ in
                callOrder.append("onError")
            },
            onCompleted: {
                callOrder.append("onCompleted")
            }
        )

        task.cancel()
        await task.value

        #expect(callOrder == ["operation", "onCompleted"])
    }

    @Test("run void throwing operation handles different error types")
    func testRunVoidThrowingWithDifferentErrorTypes() async {
        enum CustomError: Error, Equatable {
            case networkError
            case validationError(String)
        }
        var operationCalled = false
        var capturedError: CustomError?
        let task = Task.run(
            operation: {
                operationCalled = true
                throw CustomError.validationError("invalid void input")
            },
            onSuccess: {},
            onError: { error in
                capturedError = error as? CustomError
            }
        )

        await task.value

        #expect(operationCalled == true)
        #expect(capturedError == CustomError.validationError("invalid void input"))
    }
}

private nonisolated final class TestClass {
    @concurrent
    func longTask() async -> String {
        var sum = 0
        for i in 0...10_000_000 {
            if Bool.random() {
                sum += i
            }
        }
        return "\(sum)"
    }
}
