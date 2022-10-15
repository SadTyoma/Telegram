//
//  PhotoCollectionViewCell.swift
//  Telegram_Contest
//
//  Created by Artem Shuneyko on 13.10.22.
//

import UIKit
import Photos

class PhotoCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "photoCell"
    @IBOutlet weak var imageView: UIImageView!
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}

extension UIImageView {
    func fetchImageAsset(_ asset: PHAsset?, targetSize size: CGSize, contentMode: PHImageContentMode = .aspectFill, options: PHImageRequestOptions? = nil, completionHandler: ((Bool) -> Void)?) {
        
        guard let asset = asset else {
            completionHandler?(false)
            return
        }
        
        let resultHandler: (UIImage?, [AnyHashable: Any]?) -> Void = { image, info in
            if let img = image{
                let sideLength = min(
                    img.size.width,
                    img.size.height
                )
                
                let sourceSize = img.size
                let xOffset = (sourceSize.width - sideLength) / 2.0
                let yOffset = (sourceSize.height - sideLength) / 2.0
                
                let cropRect = CGRect(
                    x: xOffset,
                    y: yOffset,
                    width: sideLength,
                    height: sideLength
                ).integral
                
                let sourceCGImage = img.cgImage!
                let croppedCGImage = sourceCGImage.cropping(
                    to: cropRect
                )!
                
                // Use the cropped cgImage to initialize a cropped
                // UIImage with the same image scale and orientation
                let croppedImage = UIImage(
                    cgImage: croppedCGImage,
                    scale: img.imageRendererFormat.scale,
                    orientation: img.imageOrientation
                )
                
                self.image = croppedImage
                completionHandler?(true)
            }
        }
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: contentMode,
            options: options,
            resultHandler: resultHandler)
    }
}

