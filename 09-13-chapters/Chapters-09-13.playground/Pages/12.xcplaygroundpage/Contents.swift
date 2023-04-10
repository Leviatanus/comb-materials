//: [Previous](@previous)

import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

// Key-Value observing

// assign(to:on:) - we can update the value of an object's property every time a publsher emits a new value

// Now we can observe changes to single variable!
// Combine provides a publisher for any property of an object that is KVO (Key-Value Observing)-compliant

// There are many other framework classes exposing KVO-compliant properties. Just use publisher(for:) with a key path to a KVO-compliant property, and voilà!
example(of: "OperationQueue") {
    let queue = OperationQueue()
    queue.publisher(for: \.operationCount)
        .sink {
            print("Outstanding operations in queue: \($0)")
        }
        .store(in: &subscriptions)
}


// Create a class that conforms to the NSObject protocol. This is required for KVO.
class TestObject: NSObject {
    // Mark any property you want to make observable as @objc dynamic.
    @objc dynamic var integerProperty: Int = 0
    @objc dynamic var stringProperty: String = ""
    @objc dynamic var arrayProperty: [Float] = []
}

/// `publisher(for:options:)` allows us to subscribe to an property of an object
///  `for` is a KeyPath to the property
///  `options` allows us to  define if we want to receive initial value through `.initial` , `.prior` emits both the previous and the new value when a change occurs.
/// When observing system object be aware! They must be marked KVO-aware in docs
example(of: "subscribing to your own KVO-compliant properties with publisher(for:options:)") {
    let obj = TestObject()
    
    // Create and subscribe to a publisher observing the integerProperty property of obj.
    obj.publisher(for: \.integerProperty)
        .sink {
            print("integerProperty changes to \($0)")
        }
        .store(in: &subscriptions)
    
    obj.publisher(for: \.stringProperty)
        .sink {
            print("stringProperty changes to \($0)")
        }
        .store(in: &subscriptions)
    
    obj.publisher(for: \.arrayProperty)
        .sink {
            print("arrayProperty changes to \($0)")
        }
        .store(in: &subscriptions)
    
    // Updating the property - it will trigger the subscription
    obj.integerProperty = 100
    obj.integerProperty = 200
    obj.stringProperty = "Hello"
    obj.arrayProperty = [1.0]
    obj.stringProperty = "World"
    obj.arrayProperty = [1.0, 2.0]
}

example(of: "publisher(for:options:) without initial value (leave options as an empty array]") {
    let obj = TestObject()
    
    obj.publisher(for: \.integerProperty, options: [])
        .sink {
            print("integerProperty changes \($0)")
        }
        .store(in: &subscriptions)
    
    obj.integerProperty = 100
    obj.integerProperty = 200
}

example(of: "publisher(for:options:) with .prior option") {
    let obj = TestObject()
    
    obj.publisher(for: \.integerProperty, options: [.prior])
        .sink {
            print("integerProperty changes \($0)")
        }
        .store(in: &subscriptions)
    
    obj.integerProperty = 100
    obj.integerProperty = 200
}

/// The `ObservableObject` protocol conformance makes the compiler automatically generate the `objectWillChange` property. It‘s an `ObservableObjectPublisher` which emits `Void` items and `Never` fails.
/// We do not know which value has changed
example(of: "ObservableObject") {
    class MonitorObject: ObservableObject {
        @Published var someProperty = false
        @Published var someOtherProperty = ""
    }
    
    let object = MonitorObject()
    let subscription = object.objectWillChange.sink {
        print("object will change")
    }
    
    object.someProperty = true
    object.someOtherProperty = "Hello world"
}
//: [Next](@next)
