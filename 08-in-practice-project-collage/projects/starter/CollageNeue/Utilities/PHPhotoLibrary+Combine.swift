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

import Foundation
import Photos
import Combine

extension PHPhotoLibrary {
  
  static var isAuthorized: Future<Bool, Never> {
    let future = Future<Bool, Never> { promise in
      fetchAuthorizationStatus { value in
        print("fetchAuthorizationStatus: \(value)")
        promise(.success(value))
      }
    }
    print("returning future")
    return future
  }
  
  static func fetchAuthorizationStatus(callback: @escaping (Bool) -> Void) {
    // Fetch the current status.
    let currentlyAuthorized = authorizationStatus() == .authorized
    
    // If authorized callback immediately.
    guard !currentlyAuthorized else {
      return callback(currentlyAuthorized)
    }
    
    // Otherwise request access and callback with the new status.
    requestAuthorization { newStatus in
      callback(newStatus == .authorized)
    }
  }
}

