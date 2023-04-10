//: [Previous](@previous)

import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

// Timers

// RunLoop class is not thread-safe. You should only call RunLoop methods for the run loop of the current thread!

// note: Timer class is more feasible to use
example(of: "Run loop schedule - it does not create a publisher - Its only usefulness in relation to Combine is that the Cancellable it returns lets you stop the timer after a while") {
    let runLoop = RunLoop.main
    let subscription = runLoop.schedule(
        after: runLoop.now,
        interval: .seconds(1),
        tolerance: .milliseconds(100)
    ){
        print("Timer fired")
    }
    //    .store(in: &subscriptions)
    
    // we will cancel the created subscription after 3 seonds
    runLoop.schedule(after: .init(Date(timeIntervalSinceNow: 3.0)))
    {
        subscription.cancel()
    }
}

example(of: "Timer - Combine variant") {
    // On - which RunLoop your timer attaches to. Here, the main thread‘s RunLoop.
    // In - which run loop mode(s) the timer runs. Here, the default run loop mode.
    Timer
        .publish(every: 1.0, on: .main, in: .common)
        .autoconnect()
        .scan(0) { counter, _ in counter + 1 }
        .sink { counter in
            print("Counter is \(counter)")
        }
        .store(in: &subscriptions)
}

example(of: "DispatchQueue timer") {
    let queue = DispatchQueue.main
    // Create a Subject you will send timer values to.
    let source = PassthroughSubject<Int, Never>()
    // Prepare a counter. You‘ll increment it every time the timer fires.
    var counter = 0
    // Schedule a repeating action on the selected queue every second. The action starts immediately.
    queue.schedule(after: queue.now, interval: .seconds(1) ){
        source.send(counter)
        counter += 1
    }
    .store(in: &subscriptions)
    
    // Subscribe to the subject to get the timer values
    source.sink {
        print("Timer emitted \($0)")
    }
        .store(in: &subscriptions)
}
//: [Next](@next)
