//: [Previous](@previous)

import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

// Combine offers a few operators to help with debugging

example(of: "print - passthrough publisher") {
    let subscription = (1...3).publisher
        .print("publisher")
        .sink { _ in }
}

class TimeLogger: TextOutputStream {
    private var previous = Date()
    private let formatter = NumberFormatter()
    init() {
        formatter.maximumFractionDigits = 5
    }
    func write(_ string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = Date()
        print("+\(formatter.string(for:now.timeIntervalSince(previous))!)s: \(string)")
        previous = now
    }
}

example(of: "print - with StreamOutput for logging") {
    let subscription = (1...3).publisher
        .print("publisher", to: TimeLogger())
        .sink { _ in }
}

// we can execute code e.g. on receive subscription, on receive cancel etc.
example(of: "side effects - handleEvents(receiveSubscription:receiveOutput:receiveCompletion:rece iveCancel:receiveRequest:)") {
    let request = URLSession.shared.dataTaskPublisher(for: URL(string: "https://www.raywenderlich.com/")!)
    request
        .handleEvents(receiveSubscription: { _ in
            print("Network request will start")
        }, receiveOutput: { _ in
            print("Network request data received")
        }, receiveCancel: {
            print("Network request cancelled")
        })
        .sink(receiveCompletion: { completion in
            print("Sink received completion: \(completion)")
        }) { (data, _) in
            print("Sink received data: \(data)")
        }
    // this will print
    //    Network request will start
    //    Network request cancelled
    // which means that we forgot to keep the Cancellable around!
}

// MARK: last resort operators

// we can execute code e.g. on receive subscription, on receive cancel etc.
example(of: "breakpointOnError() - will stop executing on error") {
    let subscription = (1...3).publisher
        .breakpointOnError()
        .print("publisher")
        .sink { _ in }
}

example(of: "breakpoint(receiveSubscription:receiveOutput:receiveCompletion:)") {
    let subscription = (1...3).publisher
        .breakpoint(receiveOutput: { value in
          return value == -1 // break if condition is met
        })
        .print("publisher")
        .sink { _ in }
}



//: [Next](@next)
