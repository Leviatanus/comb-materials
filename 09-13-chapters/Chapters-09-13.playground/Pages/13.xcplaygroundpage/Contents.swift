//: [Previous](@previous)

import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

// Resource management

/// Thanks to `share` operator we can obtain publisher by reference NOT value
/// There is no buffering or replay involved
example(of: "Networking with share operator") {
    let shared = URLSession.shared
        .dataTaskPublisher(for: URL(string: "https://www.raywenderlich.com")!)
        .map(\.data)
        .print("shared")
        .share()

    print("subscribing first")

    shared
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { print("subscription1 received: '\($0)'") }
        )
        .store(in: &subscriptions)

    print("subscribing second")

    shared
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { print("subscription2 received: '\($0)'") }
        )
        .store(in: &subscriptions)
}

example(of: "Networking WITHOUT share operator - request is triggered multiple times") {
    let shared = URLSession.shared
        .dataTaskPublisher(for: URL(string: "https://www.raywenderlich.com")!)
        .map(\.data)
        .print("NOT shared")

    print("WITHOUT share operator - subscribing first")

    shared
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { print("WITHOUT share operator - subscription1 received: '\($0)'") }
        )
        .store(in: &subscriptions)

    print("WITHOUT share operator - subscribing second")

    shared
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { print("WITHOUT share operator - subscription2 received: '\($0)'") }
        )
        .store(in: &subscriptions)
}

example(of: "Networking with share operator - subscribing after the publisher has finished - we receive no values") {
    let shared = URLSession.shared
        .dataTaskPublisher(for: URL(string: "https://www.raywenderlich.com")!)
        .map(\.data)
        .print("shared")
        .share()

    print("subscribing first")

    shared
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { print("subscription1 received: '\($0)'") }
        )
        .store(in: &subscriptions)


    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        print("subscribing second - after the request has finished")

        shared
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { print("subscription2 received: '\($0)'") }
            )
            .store(in: &subscriptions)
    }
}


/// NOTE:  A multicast publisher, like all ConnectablePublishers, also provides an autoconnect() method, which makes it work like share(): The first time you subscribe to it, it connects to the upstream publisher and starts the work immediately. This is useful in scenarios where the upstream publisher emits a single value and you can use a CurrentValueSubject to share it with subscribers.
example(of: "multicast - it builds on share() but it waits for connect() call before it starts publishing, so the publshers can be set up as needed before connecting") {
    // Prepares a subject, which relays the values and completion event the upstream publisher emits.
    let subject = PassthroughSubject<Data, URLError>()
    // Prepares the multicasted publisher, using the above subject.
    let multicasted = URLSession.shared
        .dataTaskPublisher(for: URL(string: "https://www.raywenderlich.com")!)
        .map(\.data)
        .print("multicast")
        .multicast(subject: subject)

    // Subscribes to the shared — i.e., multicasted — publisher, like earlier in this chapter.
    multicasted
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { print("subscription1 received: '\($0)'") }
        )
        .store(in: &subscriptions)
    multicasted
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { print("subscription2 received: '\($0)'") }
        )
        .store(in: &subscriptions)
    // Instructs the publisher to connect to the upstream publisher.
    multicasted.connect().store(in: &subscriptions)
}


/// `Future` is a class!
/// it performs work and returns a single result, not a stream of results, so the use cases are narrower than full-blown publishers.
/// Upon creation, it immediately invokes your closure to start computing the result and fulfill the promise as soon as possible.
/// It stores the result of the fulfilled Promise and delivers it to current and future subscribers.
example(of: "Future") {
    // Provides a function simulating work (possibly asynchronous) performed by the Future.
    func performSomeWork() throws -> Int {
        print("Performing some work and returning a result")
        return 5
    }
    // Creates a new Future. Note that the work starts immediately without waiting for subscribers.
    let future = Future<Int, Error> { fulfill in
        do {
            let result = try performSomeWork()
            // In case the work succeeds, it fulfills the Promise with the result.
            fulfill(.success(result))
        } catch { // If the work fails, it passes the error to the Promise.
            fulfill(.failure(error))
        }
    }
    print("Subscribing to future...")
    // Subscribes once to show that we receive the result.
    let subscription1 = future
        .sink(
            receiveCompletion: { _ in print("subscription1 completed") },
            receiveValue: { print("subscription1 received: '\($0)'") }
        )
    // Subscribes a second time to show that we receive the result too without performing the work twice.
    let subscription2 = future
        .sink(
            receiveCompletion: { _ in print("subscription2 completed") },
            receiveValue: { print("subscription2 received: '\($0)'") }
        )
}

//: [Next](@next)
