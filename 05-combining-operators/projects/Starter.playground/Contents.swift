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
