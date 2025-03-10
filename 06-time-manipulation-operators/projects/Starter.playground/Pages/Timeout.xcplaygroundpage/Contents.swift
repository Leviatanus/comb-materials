import Combine
import SwiftUI
import PlaygroundSupport

enum TimeoutError: Error {
  case timedOut
}

let subject = PassthroughSubject<Void, TimeoutError>()
// Have you noticed you’re using a subject that emits Void values? Yes, this is totally legitimate! It signals that something happened. But, there is no particular value to carry. So, you simply use Void as the value type. This is such a common case that Subject has an extension with a send() function that takes no parameter in case the Output type is Void. This saves you from writing the awkward subject.send(()) statement!

// if we did not add customError: (() -> Self.Failure)? the publisher would emit normal completion after given timeout
let timedOutSubject = subject.timeout(.seconds(5), scheduler: DispatchQueue.main) {
    .timedOut
}

let timeline = TimelineView(title: "Button taps")
let view = VStack(spacing: 100) {
    // 1
    Button(action: { subject.send() }) {
        Text("Press me within 5 seconds")
    }
    timeline }
PlaygroundPage.current.liveView = UIHostingController(rootView: view.frame(width: 375, height: 600))
timedOutSubject.displayEvents(in: timeline)

//: [Next](@next)
/*:
 Copyright (c) 2021 Razeware LLC
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 distribute, sublicense, create a derivative work, and/or sell copies of the
 Software in any work that is designed, intended, or marketed for pedagogical or
 instructional purposes related to programming, coding, application development,
 or information technology.  Permission for such use, copying, modification,
 merger, publication, distribution, sublicensing, creation of derivative works,
 or sale is expressly withheld.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

