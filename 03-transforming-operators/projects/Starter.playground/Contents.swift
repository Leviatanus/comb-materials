import Foundation
import Combine

/// Each `Combine` operator returns a publisher

/// collect transforms the upstream inuput into and array
/// WARNING: It will wait for completion before emiting the values (and store until then everything in mmory)
example(of: "collect") {
    var subscriptions = Set<AnyCancellable>()
    
    ["A", "B", "C", "D", "E"].publisher
        .collect()
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "collect - return several array of given max length") {
    var subscriptions = Set<AnyCancellable>()
    
    ["A", "B", "C", "D", "E"].publisher
        .collect(2)
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}

/// It works just like Swift’s standard map, except that it operates on values emitted from a publisher. This operator re-publishes values as soon as they are published by the upstream.
example(of: "map") {
    var subscriptions = Set<AnyCancellable>()
    
    // 1
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    // 2
    [123, 4, 56].publisher
    // 3
        .map {
            formatter.string(for: NSNumber(integerLiteral: $0)) ?? ""
        }
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

/// We can map one, two or three `KeyPath` values
example(of: "mapping key paths") {
    var subscriptions = Set<AnyCancellable>()
    
    // 1
    let publisher = PassthroughSubject<Coordinate, Never>()
    // 2
    publisher
    // 3
        .map(\.x, \.y)
        .sink(receiveValue: { x, y in
            // 4
            print(
                "The coordinate at (\(x), \(y)) is in quadrant",
                quadrantOf(x: x, y: y)
            )
        })
        .store(in: &subscriptions)
    // 5
    publisher.send(Coordinate(x: 10, y: -8))
    publisher.send(Coordinate(x: 0, y: 5))
}

/// `tryMap` can be used for emitting error downstream if an error could be the side-effect of functions executed inside tryMap
example(of: "tryMap") {
    var subscriptions = Set<AnyCancellable>()
    // 1
    Just("Directory name that does not exist")
    // 2
        .tryMap {
            try FileManager.default.contentsOfDirectory(atPath: $0)
            
        }
    // 3
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}

/// Flattening publishers - The publisher returned by flatMap does not — and often will not — be of the same type as the upstream publishers it receives.
///
/// Use case:
/// A common use case for flatMap in Combine is when you want to pass elements emitted by one publisher to a method that itself returns a publisher, and ultimately subscribe to the elements emitted by that second publisher.

example(of: "flatMap") {
    var subscriptions = Set<AnyCancellable>()
    
    // each int represents an ASCII code
    func decode(_ codes: [Int]) -> AnyPublisher<String, Never> {
        // 2
        Just(
            codes
                .compactMap { code in
                    guard (32...255).contains(code) else { return nil }
                    return String(UnicodeScalar(code) ?? " ")
                }
                .joined() // 3
        )
        // 4
        .eraseToAnyPublisher()
    }
    
    // 5
    [72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33]
        .publisher
        .collect()
        .flatMap(decode) // Use flatMap to pass the array element to your decoder function.
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "replaceNil") {
    var subscriptions = Set<AnyCancellable>()
    
    ["A", nil, "C"].publisher
        .eraseToAnyPublisher() // replaceNil(with:) has overloads which can confuse Swift into picking the wrong one for your use case. This results in the type remaining as Optional<String> instead of being fully unwrapped. The code uses eraseToAnyPublisher() to work around that bug.
        .replaceNil(with: "-") // 2
        .sink(receiveValue: { print($0) }) // 3
        .store(in: &subscriptions)
}

/// Replace value of publsher with given value if it finishes without ever emitting any value
example(of: "replaceEmpty(with:)") {
    var subscriptions = Set<AnyCancellable>()
    // 1
    let empty = Empty<Int, Never>(completeImmediately: true) // we can configure it to never emit anything by passing false instead of true (true is passed as a default)
    // 2
    empty
        .replaceEmpty(with: 1)
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}

/// In the case of `scan` if new value is emitted we get access to previous e.g. latest variable
example(of: "scan") {
    var subscriptions = Set<AnyCancellable>()
    // 1
    var dailyGainLoss: Int { .random(in: -10...10) }
    // 2
    let august2019 = (0..<22)
        .map { _ in dailyGainLoss }
        .publisher
    // 3
    august2019
    // we start with value 50 .scan(50) then increment it with the change (the new value will be stored in latest)
        .scan(50) { latest, current in // there is also corresponding tryScan
            max(0, latest + current)
        } // Use scan with a starting value of 50, and then add each daily change to the running stock price
        .sink(receiveValue: { _ in })
        .store(in: &subscriptions)
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
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.
