//
//  MainViewController.swift
//  Telegram_Contest
//
//  Created by Artem Shuneyko on 14.10.22.
//

import UIKit
import Photos

class MainViewController: UIViewController {
    var allPhotos = PHFetchResult<PHAsset>()
    //let dataController = DataController.getInstance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getPermissionIfNecessary { granted in
            guard granted else { return }
            self.fetchAssets()
        }
        PHPhotoLibrary.shared().register(self)
        //dataController.startLoadData(assets: allPhotos)
    }
    
    func getPermissionIfNecessary(completionHandler: @escaping (Bool) -> Void) {
        guard PHPhotoLibrary.authorizationStatus() != .authorized else {
            completionHandler(true)
            return
        }
        PHPhotoLibrary.requestAuthorization { status in
            completionHandler(status == .authorized ? true : false)
        }
    }
    
    func fetchAssets() {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [
            NSSortDescriptor(
                key: "creationDate",
                ascending: false)
        ]
        
        allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
    }
    
    @IBSegueAction func makePhotoCollectionViewController(_ coder: NSCoder) -> PhotosCollectionViewController? {
        return PhotosCollectionViewController(assets: allPhotos, title: "All Photos", coder: coder)
    }
}

extension MainViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.sync {
            if let changeDetails = changeInstance.changeDetails(for: allPhotos) {
                allPhotos = changeDetails.fetchResultAfterChanges
            }
        }
    }
}
