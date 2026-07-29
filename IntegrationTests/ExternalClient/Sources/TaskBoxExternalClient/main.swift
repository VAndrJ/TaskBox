import TaskBox

@main
struct ExternalClient {
    @MainActor
    static func main() async {
        let box = TaskBox()
        var receivedValues: [Int] = []
        let valueStream = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }
        let valueTask = Task.run(
            sequence: valueStream,
            onValue: { value in
                receivedValues.append(value)
            }
        )
        valueTask.store(in: box)

        await valueTask.value
        precondition(receivedValues == [1, 2])

        var receivedSignalCount = 0
        let signalStream = AsyncStream<Void> { continuation in
            continuation.yield()
            continuation.finish()
        }
        let signalTask = Task.run(
            sequence: signalStream,
            onValue: {
                receivedSignalCount += 1
            }
        )
        signalTask.store(in: box)

        await signalTask.value
        precondition(receivedSignalCount == 1)

        box.cancelAll()

        let detachedClient = Task.detached {
            let detachedBox = TaskBox()
            let detachedTask = Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            detachedTask.store(in: detachedBox)
            detachedBox.cancelAll()

            await detachedTask.value
            precondition(detachedTask.isCancelled)
        }
        await detachedClient.value
    }
}
