//
//  PhotoViewController.swift
//  Telegram_Contest
//
//  Created by Artem Shuneyko on 14.10.22.
//

import UIKit
import Photos

class PhotoViewController: UIViewController {

    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var photoView: UIImageView!
    
    var asset: PHAsset
    var editingOutput: PHContentEditingOutput?

    required init?(coder: NSCoder) {
      fatalError("init(coder:) not implemented")
    }

    init?(asset: PHAsset, coder: NSCoder) {
      self.asset = asset
      super.init(coder: coder)
    }

    @IBAction func ClearAllClicked(_ sender: Any) { getPhoto()}
    @IBAction func SaveClicked(_ sender: Any) { saveImage()}
    @IBAction func undoClicked(_ sender: Any) { undo()}
    override func viewDidLoad() {
        super.viewDidLoad()
        getPhoto()
        updateUndoButton()
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
      PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

//    func applyFilter() {
//      // 1
//      asset.requestContentEditingInput(with: nil) { input, _ in
//        // 2
//        guard let bundleID = Bundle.main.bundleIdentifier else {
//          fatalError("Error: unable to get bundle identifier")
//        }
//        guard let input = input else {
//          fatalError("Error: cannot get editing input")
//        }
//        guard let filterData = Filter.noir.data else {
//          fatalError("Error: cannot get filter data")
//        }
//        // 3
//        let adjustmentData = PHAdjustmentData(
//          formatIdentifier: bundleID,
//          formatVersion: "1.0",
//          data: filterData)
//        // 4
//        self.editingOutput = PHContentEditingOutput(contentEditingInput: input)
//        guard let editingOutput = self.editingOutput else { return }
//        editingOutput.adjustmentData = adjustmentData
//        // 5
//        let fitleredImage = self.imageView.image?.applyFilter(.noir)
//        self.imageView.image = fitleredImage
//        // 6
//        let jpegData = fitleredImage?.jpegData(compressionQuality: 1.0)
//        do {
//          try jpegData?.write(to: editingOutput.renderedContentURL)
//        } catch {
//          print(error.localizedDescription)
//        }
//        // 7
//        DispatchQueue.main.async {
//          self.saveButton.isEnabled = true
//        }
//      }
//    }

    func updateUndoButton() {
      let adjustmentResources = PHAssetResource.assetResources(for: asset)
        .filter { $0.type == .adjustmentData }
      undoButton.isEnabled = !adjustmentResources.isEmpty
    }
    
    func saveImage() {
      // 1
      let changeRequest: () -> Void = {
        let changeRequest = PHAssetChangeRequest(for: self.asset)
        changeRequest.contentEditingOutput = self.editingOutput
      }
      // 2
      let completionHandler: (Bool, Error?) -> Void = { success, error in
        guard success else {
          print("Error: cannot edit asset: \(String(describing: error))")
          return
        }
        // 3
        self.editingOutput = nil
        DispatchQueue.main.async {
          self.saveButton.isEnabled = false
        }
      }
      // 4
      PHPhotoLibrary.shared().performChanges(
        changeRequest,
        completionHandler: completionHandler)
    }

    func undo() {
      // 1
      let changeRequest: () -> Void = {
        let request = PHAssetChangeRequest(for: self.asset)
        request.revertAssetContentToOriginal()
      }
      // 2
      let completionHandler: (Bool, Error?) -> Void = { success, error in
        guard success else {
          print("Error: can't revert the asset: \(String(describing: error))")
          return
        }
        DispatchQueue.main.async {
          self.undoButton.isEnabled = false
        }
      }
      // 3
      PHPhotoLibrary.shared().performChanges(
        changeRequest,
        completionHandler: completionHandler)
    }

    func getPhoto() {
      photoView.fetchImageAsset(asset, targetSize: view.bounds.size, completionHandler: nil)
    }

}

extension PhotoViewController: PHPhotoLibraryChangeObserver {
  func photoLibraryDidChange(_ changeInstance: PHChange) {
    // 2
    guard
      let change = changeInstance.changeDetails(for: asset),
      let updatedAsset = change.objectAfterChanges
      else { return }
    // 3
    DispatchQueue.main.sync {
      // 4
      asset = updatedAsset
      photoView.fetchImageAsset(
        asset,
        targetSize: view.bounds.size
      ) { [weak self] _ in
        guard let self = self else { return }
        // 5
        self.updateUndoButton()
      }
    }
  }
}
