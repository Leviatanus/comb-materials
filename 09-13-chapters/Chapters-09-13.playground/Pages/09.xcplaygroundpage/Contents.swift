//: [Previous](@previous)

import Foundation
import Combine
//import PlaygroundSupport

var subscriptions = Set<AnyCancellable>()

struct Superheroes: Codable {
    var squadName: String
    var homeTown: String
    var formed: Int
    var secretBase: String
    var active: Bool
}

example(of: "URLSession extensions - network requests in Combine style and .decode") {
    guard let url = URL(string: "https://mdn.github.io/learning-area/javascript/oojs/json/superheroes.json")
    else {
        return
    }
    // It‘s crucial that you keep the resulting subscription; otherwise, it gets immediately canceled and the request never executes.
    URLSession.shared
    // You‘re using the overload of dataTaskPublisher(for:) that takes a URL as a parameter.
        .dataTaskPublisher(for: url)
    //        .tryMap { data, _ in
    //          try JSONDecoder().decode(Superheroes.self, from: data)
    //        }
        .map(\.data) // Unfortunately, since dataTaskPublisher(for:) emits a tuple, you can‘t directly use decode(type:decoder:) without first using a map(_:) that only emits the Data part of the result.
        .decode(type: Superheroes.self, decoder: JSONDecoder()) // instead of try map we can use decode!!!
        .sink(receiveCompletion: { completion in
            // Make sure you always handle errors! Network connections are prone to failure.
            if case .failure(let err) = completion {
                print("Retrieving data failed with error \(err)")
            }
        }, receiveValue: { superheroes in
            // The result is a tuple with both a Data object and a URLResponse.
            //            print("Retrieved data of size \(data.count), response = \(response)")
            print(superheroes)
        })
        .store(in: &subscriptions)
    sleep(1)
}

// This process remains a bit convoluted, as Combine does not offer operators for this kind of scenario like other reactive frameworks do. In Chapter 18, “Custom Publishers & Handling Backpressure,” you‘ll explore crafting a better solution.
example(of: "Publishing network data to multiple subscribers - multicast") {
    let url = URL(string: "https://www.raywenderlich.com")!
    
    let publisher = URLSession.shared
    // Create your DataTaskPublisher, map to its data and then multicast it. The closure you pass must return a subject of the appropriate type. Alternately, you can pass an existing subject to multicast(subject:). You‘ll learn more about multicast in Chapter 13, “Resource Management.”
        .dataTaskPublisher(for: url)
        .map(\.data)
        .multicast { PassthroughSubject<Data, URLError>() }
    
    // Subscribe a first time to the publisher. Since it‘s a ConnectablePublisher it won‘t start working right away.
    publisher
        .sink(receiveCompletion: { completion in
            if case .failure(let err) = completion {
                print("Sink1 Retrieving data failed with error \(err)")
            }
        }, receiveValue: { object in
            print("Sink1 Retrieved object \(object)")
        })
        .store(in: &subscriptions)
    
    // Subscribe a second time.
    publisher
        .sink(receiveCompletion: { completion in
            if case .failure(let err) = completion {
                print("Sink2 Retrieving data failed with error \(err)")
            }
        }, receiveValue: { object in
            print("Sink2 Retrieved object \(object)")
        })
        .store(in: &subscriptions)
    
    // Connect the publisher, when you‘re ready. It will start working and pushing values to all of its subscribers.
    publisher.connect().store(in: &subscriptions)
}


//: [Next](@next)
