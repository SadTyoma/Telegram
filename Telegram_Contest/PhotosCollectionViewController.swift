//
//  ViewController.swift
//  Telegram_Contest
//
//  Created by Artem Shuneyko on 13.10.22.
//

import UIKit
import Photos

class PhotosCollectionViewController: UICollectionViewController {
    var assets: PHFetchResult<PHAsset>
    let imagesInRow = 5
    let kScaleBoundLower: CGFloat = 1
    let kScaleBoundUpper: CGFloat = 4
    private var gesture: UIPinchGestureRecognizer?
    var scale: CGFloat = 0.0
    var fitCells = false
    var animatedZooming = false
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented.")
    }
    
    init?(assets: PHFetchResult<PHAsset>, title: String, coder: NSCoder) {
        self.assets = assets
        super.init(coder: coder)
        self.title = title
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PHPhotoLibrary.shared().register(self)
        
        fitCells = true
        
        animatedZooming = true
        
        // Default scale is the average between the lower and upper bound
        scale = (kScaleBoundUpper + kScaleBoundLower) / 2.0
        
        // Register a random cell
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        
        // Add the pinch to zoom gesture
        gesture = UIPinchGestureRecognizer(target: self, action: #selector(didReceivePinchGesture(_:)))
        if let gesture = self.gesture {
            collectionView.addGestureRecognizer(gesture)
        }
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    @IBSegueAction func makePhotoViewController(_ coder: NSCoder) -> PhotoViewController? {
        guard let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first else { return nil }
        return PhotoViewController(asset: assets[selectedIndexPath.item], coder: coder)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PhotoCollectionViewCell.reuseIdentifier,
            for: indexPath) as? PhotoCollectionViewCell else {
            fatalError("Unable to dequeue PhotoCollectionViewCell")
        }
        let asset = assets[indexPath.item]
        let cellSize = cellSizeCalculation()
        cell.imageView.fetchImageAssetWithCropping(asset, targetSize: cellSize, completionHandler: nil)
        
        return cell
    }
    
    // MARK: - Accessors
    
    func setScale(_ scale: CGFloat) {
        // Make sure it doesn't go out of bounds
        if scale < kScaleBoundLower {
            self.scale = kScaleBoundLower
        } else if scale > kScaleBoundUpper {
            self.scale = kScaleBoundUpper
        } else {
            self.scale = floor(scale)
        }
    }
    
    func getCountOfItems()->Double{
        if self.scale >= 1 && self.scale < 2{
            return 1.0
        }
        else if self.scale >= 2 && self.scale < 3{
            return 3.0
        }
        else{
            return 5.0
        }
    }
    
    private func cellSizeCalculation()->CGSize{
        let viewSize = self.collectionView.frame.size.width
        let scaledWidth = Double(viewSize) / getCountOfItems() - 2;
        
        if (self.fitCells) {
            let cols = floor(viewSize / scaledWidth);
            let totalSpacingSize = 2 * (cols - 1); // 10 is defined in the xib
            let fittedWidth = (viewSize - totalSpacingSize) / cols;
            return CGSize(width: fittedWidth, height: fittedWidth)
        } else {
            return CGSize(width: scaledWidth, height: scaledWidth);
        }
    }
    
    private var scaleStart: CGFloat = 0.0;

    @objc func didReceivePinchGesture(_ gesture: UIPinchGestureRecognizer){
        if (gesture.state == .began)
        {
            scaleStart = self.scale;
            return;
        }
        if (gesture.state == .changed)
        {
            // Apply the scale of the gesture to get the new scale
            setScale(scaleStart * gesture.scale)
            
            if (self.animatedZooming && self.gesture != nil)
            {
                // Animated zooming (remove and re-add the gesture recognizer to prevent updates during the animation)
                self.collectionView.removeGestureRecognizer(self.gesture!)
                let newLayout = UICollectionViewFlowLayout()
                self.collectionView.setCollectionViewLayout(newLayout, animated: true) { finished in
                    self.collectionView.addGestureRecognizer(self.gesture!)
                }
            }
            else
            {
                // Invalidate layout
                if(floor(self.scale) != floor(scaleStart)){
                    self.collectionView.collectionViewLayout.invalidateLayout()
                }
            }
        }
    }
}

extension PhotosCollectionViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // 1
        guard let change = changeInstance.changeDetails(for: assets) else {
            return
        }
        DispatchQueue.main.sync {
            // 2
            assets = change.fetchResultAfterChanges
            collectionView.reloadData()
        }
    }
}

extension PhotosCollectionViewController : UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSizeCalculation()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}
