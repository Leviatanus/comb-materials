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
}


