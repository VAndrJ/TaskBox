//
//  ExampleApp.swift
//  Example
//
//  Created by VAndrJ on 16.08.2025.
//

import Combine
import SwiftUI
import TaskBox

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = TaskBoxExamplesViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    HeaderView()

                    LazyVStack(spacing: 16) {
                        ExampleSection(title: "Basic Operations", icon: "square.stack.3d.up") {
                            ExampleCard(
                                title: "Simple Data Fetch",
                                description: "Demonstrate a basic async operation with a success callback",
                                status: viewModel.dataFetchStatus,
                                action: viewModel.runDataFetch
                            )
                            .equatable()
                            ExampleCard(
                                title: "Background Calculation",
                                description: "Perform a heavy computation with background priority",
                                status: viewModel.calculationStatus,
                                action: viewModel.runCalculation
                            )
                            .equatable()
                        }

                        ExampleSection(title: "Error Handling", icon: "exclamationmark.triangle") {
                            ExampleCard(
                                title: "Network Request",
                                description: "Simulate an API call with success and error handling",
                                status: viewModel.networkStatus,
                                action: viewModel.runNetworkRequest
                            )
                            .equatable()
                            ExampleCard(
                                title: "File Operation",
                                description: "Perform a file I/O operation with error handling",
                                status: viewModel.fileStatus,
                                action: viewModel.runFileOperation
                            )
                            .equatable()
                        }

                        ExampleSection(title: "Async Sequences", icon: "link") {
                            ExampleCard(
                                title: "Number Stream",
                                description: "Process values from an async sequence",
                                status: viewModel.streamStatus,
                                action: viewModel.runStreamProcessing
                            )
                            .equatable()
                            ExampleCard(
                                title: "Timer Stream",
                                description: "Demonstrate a timer-based async sequence",
                                status: viewModel.timerStatus,
                                action: viewModel.runTimerStream
                            )
                            .equatable()
                        }

                        ExampleSection(title: "Advanced Features", icon: "gearshape.2") {
                            ExampleCard(
                                title: "Cancellation Demo",
                                description: "Demonstrate task cancellation behavior",
                                status: viewModel.cancellationStatus,
                                action: viewModel.runCancellationExample
                            )
                            .equatable()
                            ExampleCard(
                                title: "Parallel Operations",
                                description: "Run multiple tasks concurrently",
                                status: viewModel.parallelStatus,
                                action: viewModel.runParallelOperations
                            )
                            .equatable()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("TaskBox Examples")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel All") {
                        viewModel.cancelAllTasks()
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}

enum TaskStatus: Equatable {
    case idle
    case running
    case success(String? = nil)
    case error(String)
    case cancelled

    var displayName: String {
        switch self {
        case .idle: "Ready"
        case .running: "Running"
        case .success: "Success"
        case .error: "Failed"
        case .cancelled: "Cancelled"
        }
    }

    var color: Color {
        switch self {
        case .idle: .gray
        case .running: .blue
        case .success: .green
        case .error: .red
        case .cancelled: .orange
        }
    }

    var message: String? {
        switch self {
        case let .success(message): message
        case let .error(message): message
        default: nil
        }
    }

    var messageColor: Color {
        switch self {
        case .success: .green
        case .error: .red
        default: .primary
        }
    }
}

final class TaskBoxExamplesViewModel: ObservableObject {
    @Published var dataFetchStatus: TaskStatus = .idle
    @Published var calculationStatus: TaskStatus = .idle
    @Published var networkStatus: TaskStatus = .idle
    @Published var fileStatus: TaskStatus = .idle
    @Published var streamStatus: TaskStatus = .idle
    @Published var timerStatus: TaskStatus = .idle
    @Published var cancellationStatus: TaskStatus = .idle
    @Published var parallelStatus: TaskStatus = .idle

    private let box = TaskBox()

    func runDataFetch() {
        dataFetchStatus = .running
        Task.run(
            operation: {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                return "Hello, TaskBox! 👋"
            },
            onSuccess: { [weak self] result in
                self?.dataFetchStatus = .success("Received: \(result)")
            },
            onCanceled: { [weak self] in
                self?.dataFetchStatus = .cancelled
            },
            onCompleted: {
                print("Data fetch completed")
            }
        ).store(in: box)
    }

    func runCalculation() {
        calculationStatus = .running
        Task.run(
            priority: .background,
            operation: {
                return await performConcurrent {
                    var result = 0
                    for i in 1...5_000_000 {
                        result += i
                    }
                    return result
                }
            },
            onSuccess: { [weak self] sum in
                self?.calculationStatus = .success("Sum: \(sum)")
            },
            onCanceled: { [weak self] in
                self?.calculationStatus = .cancelled
            }
        ).store(in: box)
    }

    func runNetworkRequest() {
        networkStatus = .running
        Task.run(
            operation: {
                // Simulate API call that might fail.
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                if Bool.random() {
                    throw URLError(.networkConnectionLost)
                }
                return "API Response Data"
            },
            onSuccess: { [weak self] response in
                self?.networkStatus = .success("Success: \(response)")
            },
            onError: { [weak self] error in
                self?.networkStatus = .error("Failed: \(error.localizedDescription)")
            },
            onCanceled: { [weak self] in
                self?.networkStatus = .cancelled
            }
        ).store(in: box)
    }

    func runFileOperation() {
        fileStatus = .running
        Task.run(
            operation: {
                return try await performConcurrent {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    if Bool.random() {
                        throw URLError(.cannotCreateFile)
                    }
                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent("taskbox_test.txt")
                    let content = "TaskBox Example File\nCreated at: \(Date())"
                    try content.write(to: tempURL, atomically: true, encoding: .utf8)
                    let readContent = try String(contentsOf: tempURL)
                    let lineCount = readContent.components(separatedBy: .newlines).count
                    try? FileManager.default.removeItem(at: tempURL)

                    return lineCount
                }
            },
            onSuccess: { [weak self] lineCount in
                self?.fileStatus = .success("File had \(lineCount) lines")
            },
            onError: { [weak self] error in
                self?.fileStatus = .error("File error: \(error.localizedDescription)")
            },
            onCanceled: { [weak self] in
                self?.fileStatus = .cancelled
            }
        ).store(in: box)
    }

    func runStreamProcessing() {
        streamStatus = .running
        let numberStream = AsyncStream<Int> { continuation in
            Task {
                for i in 1...5 {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    continuation.yield(i)
                }
                continuation.finish()
            }
        }
        var receivedValues: [Int] = []
        Task.run(
            sequence: numberStream,
            onValue: { number in
                receivedValues.append(number)
                print("Received: \(number)")
            },
            onCompleted: { [weak self] in
                self?.streamStatus = .success("Received \(receivedValues.count) values: \(receivedValues)")
            }
        ).store(in: box)
    }

    func runTimerStream() {
        timerStatus = .running
        let timerStream = AsyncStream<Date> { continuation in
            let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                continuation.yield(Date())
            }
            // Auto-stop after 3 seconds.
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                timer.invalidate()
                continuation.finish()
            }
        }
        var tickCount = 0
        Task.run(
            sequence: timerStream,
            onValue: { date in
                tickCount += 1
                print("Timer tick \(tickCount): \(date)")
            },
            onCompleted: { [weak self] in
                self?.timerStatus = .success("Timer completed with \(tickCount) ticks")
            }
        ).store(in: box)
    }

    func runCancellationExample() {
        cancellationStatus = .running
        let longTask = Task.run(
            name: "LongOperation",
            operation: {
                for i in 1...20 {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    if Task.isCancelled { break }
                    print("Progress: \(i * 5)%")
                }
                return "Operation completed successfully"
            },
            onSuccess: { [weak self] result in
                self?.cancellationStatus = .success(result)
            },
            onCanceled: { [weak self] in
                self?.cancellationStatus = .cancelled
            }
        )
        longTask.store(in: box)

        // Cancel the long task after 2 seconds.
        Task.run(
            operation: {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            },
            onSuccess: { _ in
                print("Cancelling long task...")
                longTask.cancel()
            }
        ).store(in: box)
    }

    func runParallelOperations() {
        parallelStatus = .running
        let operationGroupBox = TaskBox()
        let totalOperations = 5
        let counter = OperationCounter(total: totalOperations)

        for i in 1...totalOperations {
            Task.run(
                name: "ParallelOp\(i)",
                operation: {
                    let delay = UInt64.random(in: 500_000_000...3_500_000_000)
                    try? await Task.sleep(nanoseconds: delay)
                    return "Task \(i)"
                },
                onSuccess: { [weak self] result in
                    let (current, isCompleted) = await counter.increment()
                    if isCompleted {
                        self?.parallelStatus = .success("✅ \(result) completed last (\(current)/\(totalOperations))")
                    }
                },
                onCanceled: { [weak self] in
                    if case .running = self?.parallelStatus {
                        self?.parallelStatus = .cancelled
                    }
                }
            ).store(in: operationGroupBox)
        }

        // Cancel all operations after 3 seconds if not completed.
        Task.run(
            operation: {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            },
            onSuccess: { [weak self] in
                if case .running = self?.parallelStatus {
                    print("⏰ Cancelling all parallel operations if needed")
                    operationGroupBox.cancelAll()
                }
            }
        ).store(in: box)
    }

    func cancelAllTasks() {
        box.cancelAll()
        print("🗑️ All tasks cancelled")
    }
}

#Preview {
    ContentView()
}

@concurrent
nonisolated func performConcurrent<T>(_ operation: @Sendable () async throws -> T) async rethrows -> T {
    return try await operation()
}

private actor OperationCounter {
    private var count = 0
    private let total: Int

    init(total: Int) {
        self.total = total
    }

    func increment() -> (current: Int, isCompleted: Bool) {
        count += 1
        return (count, count == total)
    }

    func reset() {
        count = 0
    }
}

struct ExampleSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                Spacer()
            }

            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ExampleCard: View, Equatable {
    static func == (lhs: ExampleCard, rhs: ExampleCard) -> Bool {
        lhs.title == rhs.title && lhs.description == rhs.description && lhs.status == rhs.status
    }

    let title: String
    let description: String
    let status: TaskStatus
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                statusIcon
            }

            HStack {
                Text(status.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(status.color)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: action) {
                    Text(buttonText)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .disabled(status == .running)
            }

            if let message = status.message {
                Text(message)
                    .font(.caption2)
                    .foregroundColor(status.messageColor)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }

    private var statusIcon: some View {
        Group {
            switch status {
            case .idle:
                Image(systemName: "circle")
                    .foregroundColor(.gray)
            case .running:
                ProgressView()
                    .scaleEffect(0.8)
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .error:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            case .cancelled:
                Image(systemName: "stop.circle.fill")
                    .foregroundColor(.orange)
            }
        }
    }

    private var buttonText: String {
        switch status {
        case .idle, .success, .error, .cancelled: "Run"
        case .running: "Running..."
        }
    }
}

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            Text("TaskBox Examples")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Interactive demonstration of the Task.run methods")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}
