import Foundation
import Combine
import _Concurrency

/// `Publisher` protocol defines requirements for a type to be able to transmit a sequence of values over time to one or more subscribers

/// We will create publishers and subscribe to them
example(of: "Publisher") {
    // 1 create new notification name
    let myNotification = Notification.Name("MyNotification")
    // 2 get a Publisher for previously created Notification name
    let publisher = NotificationCenter.default
        .publisher(for: myNotification, object: nil)
    // 3
    let center = NotificationCenter.default
    // 4
    let observer = center.addObserver(
        forName: myNotification,
        object: nil,
        queue: nil) { notification in
            print("Notification received!")
        }
    // 5
    center.post(name: myNotification, object: nil)
    // 6
    center.removeObserver(observer)
}

example(of: "Subscriber") {
    let myNotification = Notification.Name("MyNotification")
    let center = NotificationCenter.default
    let publisher = center.publisher(for: myNotification, object: nil)
    
    // 1 by using sink method on a publisher we can create a subscriber
    let subscription: AnyCancellable = publisher
        .sink { _ in
            print("Notification received from a publisher!")
        }
    // 2
    center.post(name: myNotification, object: nil)
    // 3
    subscription.cancel()
}

example(of: "Just") {
    // 1
    let just = Just("Hello world!")
    // 2
    _ = just
        .sink(
            receiveCompletion: {
                print("Received completion", $0)
            },
            receiveValue: {
                print("Received value", $0)
            })
    
    _ = just
        .sink(
            receiveCompletion: {
                print("Received completion (another)", $0)
            },
            receiveValue: {
                print("Received value (another)", $0)
            })
}

/// This method allows us to set parameter of e.g. class object
example(of: "assign(to:on:)") {
    // 1
    class SomeObject {
        var value: String = "" {
            didSet {
                print(value)
            }
        } }
    // 2
    let object = SomeObject()
    // 3
    let publisher = ["Hello", "world!"].publisher
    // 4 THIS CAN CREATE STRONG REFERENCE CYCLES
    _ = publisher
        .assign(to: \.value, on: object)
}

example(of: "assign(to:)") {
    // 1
    class SomeObject {
        @Published var value = 0
    }
    let object = SomeObject()
    // 2
    object.$value
        .sink {
            print($0)
        }
    // 3 THIS METHOD CAN FREE US OF SITUATIONS WHERE STRING RERFERENCE CYCLE WOULD BE CREATED WITH assign(to:on:)
    (0..<10).publisher
        .assign(to: &object.$value)
}

/// Subscription between the publisher and the subscriber is the protocol `Subscription`

/// Backpressure management - conecept of subscriber stating how many values it is willing to receive
/// Each time a subscrber receives values it can increase its demand, yet it CANNOT decrese it

example(of: "Creating a custom subscriber") {
    // 1
    let publisher = (1...6).publisher
    // 2
    final class IntSubscriber: Subscriber {
        // 3
        typealias Input = Int
        typealias Failure = Never
        // 4
        func receive(subscription: Subscription) {
            subscription.request(.max(3))
        }
        // 5
        func receive(_ input: Int) -> Subscribers.Demand {
            print("Received value", input)
            return .max(1) // every time we receive a value, we want to receive up to one more
        }
        // 6
        func receive(completion: Subscribers.Completion<Never>) {
            print("Received completion", completion)
        }
    }
    
    // creating a subscriber and subscribing
    let subscriber = IntSubscriber()
    publisher.subscribe(subscriber)
}

example(of: "Future type") {
    func futureIncrement(
        integer: Int,
        afterDelay delay: TimeInterval) -> Future<Int, Never> {
            Future<Int, Never> { promise in
                print("Original")
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    promise(.success(integer + 1))
                }
            }
        }
    
    var subscriptions = Set<AnyCancellable>()
    
    // 1
    let future = futureIncrement(integer: 1, afterDelay: 1)
    // 2
    future
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
    
    future
        .sink(receiveCompletion: { print("Second", $0) },
              receiveValue: { print("Second", $0) })
        .store(in: &subscriptions)
}

example(of: "PassthroughSubject") {
    // 1
    enum MyError: Error {
        case test }
    // 2
    final class StringSubscriber: Subscriber {
        typealias Input = String
        typealias Failure = MyError
        func receive(subscription: Subscription) {
            subscription.request(.max(2))
        }
        func receive(_ input: String) -> Subscribers.Demand {
            print("Received value", input)
            // 3
            return input == "World" ? .max(1) : .none
        }
        func receive(completion: Subscribers.Completion<MyError>) {
            print("Received completion", completion)
        }
    }
    // 4
    let subscriber = StringSubscriber()
    
    // 5
    let subject = PassthroughSubject<String, MyError>()
    // 6
    subject.subscribe(subscriber) // FIRST SUBSCRIBER
    // 7
    let subscription = subject
        .sink(
            receiveCompletion: { completion in
                print("Received completion (sink)", completion)
            },
            receiveValue: { value in
                print("Received value (sink)", value)
            }
        ) // SECOND SUBSCRIBER
    subject.send("Hello")
    subject.send("World")
    // 8
    
    subscription.cancel()
    // 9
    subject.send("Still there?")
    
    
    subject.send(completion: .failure(MyError.test))
    subject.send(completion: .finished) // once one completion event is sent the next ones won't have ANY effect
    subject.send("How about another one?")
}

example(of: "CurrentValueSubject") {
    // 1
    var subscriptions = Set<AnyCancellable>()
    // 2
    let subject = CurrentValueSubject<Int, Never>(0)
    // 3
    subject
        .print()
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions) // 4
    
    // we can ask the CurrentValueSubject for value at any time
    print(subject.value)
    
    subject.value = 3 // we can send new value by setting value property
    print(subject.value)
    
    subject
        .print()
      .sink(receiveValue: { print("Second subscription:", $0) })
      .store(in: &subscriptions)
    
    subject.send(completion: .finished) // otherwise each subscriber recieves cancel when we go out of this code's scope
}

/// Copyright (c) 2021 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.
