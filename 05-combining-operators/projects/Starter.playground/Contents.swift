import UIKit
import Combine

var subscriptions = Set<AnyCancellable>()

// Prepending - adding values before any publisher publishes anything

example(of: "prepend(Output...)") {
    // 1
    let publisher = [3, 4].publisher
    // 2
    publisher
        .prepend(1, 2)
        .prepend(-1, 0) // The last prepend affects the upstream first
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "prepend(Sequence)") {
    // 1
    let publisher = [5, 6, 7].publisher
    // 2
    publisher
        .prepend([3, 4])
        .prepend(Set(1...2)) // sets are UNORDERED - the order is not guaranteed
        .prepend(stride(from: 6, to: 11, by: 2))
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

// WARNING If we prepend the publisher, it must complete before we will switch to primary publisher

example(of: "prepend(Publisher)") {
    // 1
    let publisher1 = [3, 4].publisher
    let publisher2 = [1, 2].publisher
    // 2
    publisher1
        .prepend(publisher2)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "prepend(Publisher) #2") {
    // 1
    let publisher1 = [3, 4].publisher
    let publisher2 = PassthroughSubject<Int, Never>()
    // 2
    publisher1
        .prepend(publisher2)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
    // 3
    publisher2.send(1)
    publisher2.send(2)
    publisher2.send(completion: .finished)
}

// Appending

example(of: "append(Output...)") {
    // 1
    let publisher = [1].publisher
    // 2
    publisher
        .append(2, 3)
        .append(4)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "append(Output...) #2") {
    // 1
    let publisher = PassthroughSubject<Int, Never>()
    publisher
        .append(3, 4)
        .append(5)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
    // 2
    publisher.send(1)
    publisher.send(2)
    publisher.send(completion: .finished) // no appending occurs unless the previous publisher sends a .finished completion event.
}

example(of: "append(Sequence)") {
    // 1
    let publisher = [1, 2, 3].publisher
    publisher
        .append([4, 5]) // 2
        .append(Set([6, 7])) // 3
        .append(stride(from: 8, to: 11, by: 2)) // 4
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "append(Publisher)") {
    // 1
    let publisher1 = [1, 2].publisher
    let publisher2 = [3, 4].publisher
    // 2
    publisher1
        .append(publisher2)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

// Advanced combining

/// `switchToLatest` allows us to switch entire publsher subscriptions on the fly while cancelling the pending publisher subscription, thus switching to the latest one
example(of: "switchToLatest") {
    // 1
    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<Int, Never>()
    let publisher3 = PassthroughSubject<Int, Never>()
    // 2
    let publishers = PassthroughSubject<PassthroughSubject<Int,
                                                           Never>, Never>()
    // 3
    publishers
        .switchToLatest()
        .sink(
            receiveCompletion: { _ in print("Completed!") },
            receiveValue: { print($0) }
        )
        .store(in: &subscriptions)
    // 4
    publishers.send(publisher1) // we switched to publisher 1,so sink will receive the 1 and 2 send below (but not 3 that was send later)
    publisher1.send(1)
    publisher1.send(2)
    // 5
    publishers.send(publisher2)
    publisher1.send(3)
    publisher2.send(4)
    publisher2.send(5)
    // 6
    publishers.send(publisher3)
    publisher2.send(6)
    publisher3.send(7)
    publisher3.send(8)
    publisher3.send(9)
    // 7
    publisher3.send(completion: .finished)
    publishers.send(completion: .finished)
}

///  Use case of `switchToLatest`
///  Your user taps a button that triggers a network request. Immediately afterward, the user taps the button again, which triggers a second network request. But how do you get rid of the pending request, and only use the latest request? switchToLatest to the rescue!
example(of: "switchToLatest - Network Request") {
    //    let url = URL(string: "https://source.unsplash.com/random")!
    //    // 1
    //    func getImage() -> AnyPublisher<UIImage?, Never> {
    //        URLSession.shared
    //            .dataTaskPublisher(for: url)
    //            .map { data, _ in UIImage(data: data) }
    //            .print("image")
    //            .replaceError(with: nil)
    //            .eraseToAnyPublisher()
    //    }
    //    // 2
    //    let taps = PassthroughSubject<Void, Never>()
    //    taps
    //        .map { _ in getImage() } // 3
    //        .switchToLatest() // 4
    //        .sink(receiveValue: { _ in })
    //        .store(in: &subscriptions)
    //    // 5
    //    taps.send()
    //    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
    //        taps.send()
    //    }
    //    DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
    //        taps.send()
    //    }
}

/// `merge(with:)` This operator interleaves emissions from different publishers of the same type
example(of: "merge(with:)") {
    // 1
    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<Int, Never>()
    // 2
    publisher1
        .merge(with: publisher2) // Combine offers overloads that let you merge up to eight different publishers
        .sink(
            receiveCompletion: { _ in print("Completed") },
            receiveValue: { print($0) }
        )
        .store(in: &subscriptions)
    // 3
    publisher1.send(1)
    publisher1.send(2)
    publisher2.send(3)
    publisher1.send(4)
    publisher2.send(5)
    // 4
    publisher1.send(completion: .finished)
    publisher2.send(completion: .finished)
}

// we combine the output of two publishers - the receiveValue in sink will return tuple of latest results from each publishers each time a new value is received from any publisher.
example(of: "combineLatest") {
    // 1
    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<String, Never>()
    // 2
    publisher1
        .combineLatest(publisher2)
        .sink(
            receiveCompletion: { _ in print("Completed") },
            receiveValue: { (outputA, outputB) in
                print("P1: \(outputA), P2: \(outputB)")
            }
        )
        .store(in: &subscriptions)
    // 3
    publisher1.send(1)
    publisher1.send(2)
    publisher2.send("a")
    publisher2.send("b")
    publisher1.send(3)
    publisher2.send("c")
    // 4
    publisher1.send(completion: .finished)
    publisher2.send(completion: .finished)
}

// zip operator - works similarly to zip operator in Swift Foundation library
example(of: "zip operator in Foundation") {
    let names = ["Alice", "Bob", "Charlie"]
    let ages = [25, 30, 35]
    let heights = [1.6, 1.8, 1.7]
    
    let combined = zip(names, zip(ages, heights))
    
    for (name, (age, height)) in combined {
        print("\(name) is \(age) years old and \(height)m tall")
    }
}

/// `zip` operator waits for the publishers to publish values at current index before emitting the touple
example(of: "zip") {
    // 1
    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<String, Never>()
    // 2
    publisher1
        .zip(publisher2)
        .sink(
            receiveCompletion: { _ in print("Completed") },
            receiveValue: { print("P1: \($0), P2: \($1)") }
        )
        .store(in: &subscriptions)
    // 3
    publisher1.send(1)
    publisher1.send(2)
    publisher2.send("a")
    publisher2.send("b")
    publisher1.send(3)
    publisher2.send("c")
    publisher2.send("d") // this will not be emitted because publisher 1 did not emit value that would correspond
    
    // 4
    publisher1.send(completion: .finished)
    publisher2.send(completion: .finished)
}


// Copyright (c) 2021 Razeware LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
// distribute, sublicense, create a derivative work, and/or sell copies of the
// Software in any work that is designed, intended, or marketed for pedagogical or
// instructional purposes related to programming, coding, application development,
// or information technology.  Permission for such use, copying, modification,
// merger, publication, distribution, sublicensing, creation of derivative works,
// or sale is expressly withheld.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
