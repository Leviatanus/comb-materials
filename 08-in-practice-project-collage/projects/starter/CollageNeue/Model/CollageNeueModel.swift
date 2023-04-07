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

import UIKit
import Photos
import Combine

class CollageNeueModel: ObservableObject {
  static let collageSize = CGSize(width: UIScreen.main.bounds.width, height: 200)
  
  private var subscriptions = Set<AnyCancellable>()
  private let images = CurrentValueSubject<[UIImage], Never>([]) // when binding data to UI it is better to use CurrentValuSubject rather than PassthroughSubject
  // CurrentValueSubject guaranteed that at least one value will be send and UI will not have an undefined state
  
  let updateUISubject = PassthroughSubject<Int, Never>()
  
  private(set) var selectedPhotosSubject = PassthroughSubject<UIImage, Never>()
  
  @Published var imagePreview: UIImage?
  
  // MARK: - Collage
  
  private(set) var lastSavedPhotoID = ""
  private(set) var lastErrorMessage = ""
  
  func bindMainView() {
    // You begin a subscription to the current collection of photos.
    images
      .handleEvents(receiveOutput: { [weak self] photos in
        self?.updateUISubject.send(photos.count)
      })
    // You use map to convert them to a single collage by calling into UIImage.collage(images:size:), a helper method defined in UIImage+Collage.swift.
      .map { photos in
        UIImage.collage(images: photos, size: Self.collageSize)
      }
    // You use the assign(to:) subscriber to bind the resulting collage image to imagePreview, which is the center screen image view. Using the assign(to:) subscriber automatically manages the subscription lifecycle.
      .assign(to: &$imagePreview)
  }
  
  func add() {
    selectedPhotosSubject = PassthroughSubject<UIImage, Never>()
    //    let newPhotos = selectedPhotosSubject
    selectedPhotosSubject
      .map { [unowned self] newImage in
        // Get the current list of selected images and append any new images to it.
        return self.images.value + [newImage]
      }
    // Use assign to send the updated images array through the images subject.
      .assign(to: \.value, on: images)
    // You store the new subscription in subscriptions. However, the subscription will end whenever the user dismisses the presented view controller.
      .store(in: &subscriptions)
  }
  
  func clear() {
    images.send([])
  }
  
  func save() {
    guard let image = imagePreview else { return }
    // Subscribe the PhotoWriter.save(_:) future by using sink(receiveCompletion:receiveValue:).
    PhotoWriter.save(image)
      .sink(
        receiveCompletion: { [unowned self] completion in // unowned self should be used if we are sure that the object will not be released from memory e.g. view that is never popped out of the stack
          // In case of completion with a failure, you save the error message to lastErrorMessage.
          if case .failure(let error) = completion {
            lastErrorMessage = error.localizedDescription
          }
          clear()
        },
        receiveValue: { [unowned self] id in
          // In case you get back a value — the new asset identifier — you store it in lastSavedPhotoID.
          lastSavedPhotoID = id
        }
      )
      .store(in: &subscriptions)
  }
  
  // MARK: -  Displaying photos picker
  private lazy var imageManager = PHCachingImageManager()
  private(set) var thumbnails = [String: UIImage]()
  private let thumbnailSize = CGSize(width: 200, height: 200)
  
  func bindPhotoPicker() {
  }
  
  func loadPhotos() -> PHFetchResult<PHAsset> {
    let allPhotosOptions = PHFetchOptions()
    allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
    return PHAsset.fetchAssets(with: allPhotosOptions)
  }
  
  func enqueueThumbnail(asset: PHAsset) {
    guard thumbnails[asset.localIdentifier] == nil else { return }
    
    imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
      guard let image = image else { return }
      self.thumbnails[asset.localIdentifier] = image
    })
  }
  
  func selectImage(asset: PHAsset) {
    imageManager.requestImage(
      for: asset,
      targetSize: UIScreen.main.bounds.size,
      contentMode: .aspectFill,
      options: nil
    ) { [weak self] image, info in
      guard let self = self,
            let image = image,
            let info = info else { return }
      
      if let isThumbnail = info[PHImageResultIsDegradedKey as String] as? Bool, isThumbnail {
        // Skip the thumbnail version of the asset
        return
      }
      
      self.selectedPhotosSubject.send(image)
    }
  }
}
