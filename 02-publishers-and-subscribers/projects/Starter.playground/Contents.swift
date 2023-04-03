import Foundation
import Combine
import _Concurrency

var subscriptions = Set<AnyCancellable>()

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
