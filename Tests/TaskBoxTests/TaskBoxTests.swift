//
//  TaskBoxTests.swift
//  TaskBox
//
//  Created by VAndrJ on 16.08.2025.
//

import Testing

@testable import TaskBox

@Suite
struct TaskBoxTests {
    @Test("TaskBox can store and cancel tasks")
    func testTaskBoxBasicFunctionality() async {
        let box = TaskBox()
        let task1 = Task {
            try? await Task.sleep(nanoseconds: .second)
        }
        let task2 = Task {
            try? await Task.sleep(nanoseconds: .second)
        }
        box.insert(task1)
        box.insert(task2)
        // Give task a moment to start
        try? await Task.sleep(nanoseconds: .millisecond * 10)

        box.cancelAll()

        _ = await task1.result
        _ = await task2.result

        #expect(task1.isCancelled)
        #expect(task2.isCancelled)
    }

    @Test("TaskBox automatically cancels tasks on deallocation")
    func testTaskBoxAutoDeallocation() async {
        let task: Task<Void, Never>
        do {
            let box = TaskBox()
            task = Task {
                try? await Task.sleep(nanoseconds: .second)
            }

            box.insert(task)

            try? await Task.sleep(nanoseconds: .millisecond * 10)
        }
        _ = await task.result

        #expect(task.isCancelled)
    }

    @Test("Task store extension works correctly")
    func testTaskStoreExtension() async {
        let box = TaskBox()
        let task = Task {
            try? await Task.sleep(nanoseconds: .second)
        }
        task.store(in: box)
        try? await Task.sleep(nanoseconds: .millisecond * 10)

        box.cancelAll()

        _ = await task.result

        #expect(task.isCancelled)
    }

    @Test("Empty TaskBox cancelAll works without issues")
    func testEmptyTaskBoxCancelAll() {
        let box = TaskBox()

        box.cancelAll()
        box.cancelAll()
    }

    @Test("TaskBox can handle multiple cancelAll calls")
    func testMultipleCancelAllCalls() async {
        let box = TaskBox()
        let task = Task {
            try? await Task.sleep(nanoseconds: .second)
        }
        box.insert(task)
        try? await Task.sleep(nanoseconds: .millisecond * 10)

        box.cancelAll()
        box.cancelAll()

        #expect(task.isCancelled)
    }

    @Test("TaskBox can store multiple different task types")
    func testTaskBoxWithDifferentTaskTypes() async {
        let box = TaskBox()
        let stringTask = Task<String, Never> {
            try? await Task.sleep(nanoseconds: .second)
            return "completed"
        }
        let voidTask = Task<Void, Never> {
            try? await Task.sleep(nanoseconds: .second)
        }
        let throwingTask = Task<Int, any Error> {
            try? await Task.sleep(nanoseconds: .second)
            return 42
        }
        box.insert(stringTask)
        box.insert(voidTask)
        box.insert(throwingTask)
        try? await Task.sleep(nanoseconds: .millisecond * 10)

        box.cancelAll()

        _ = await stringTask.result
        _ = await voidTask.result
        _ = await throwingTask.result

        #expect(stringTask.isCancelled)
        #expect(voidTask.isCancelled)
        #expect(throwingTask.isCancelled)
    }

    @Test("TaskBox works with completed tasks")
    func testTaskBoxWithCompletedTasks() async {
        let box = TaskBox()
        let quickTask = Task {
            return "quick"
        }
        let result = await quickTask.result

        #expect(result.get() == "quick")

        box.insert(quickTask)
        box.cancelAll()
    }
}
