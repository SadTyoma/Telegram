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
          self.image = image
          completionHandler?(true)
      }

      PHImageManager.default().requestImage(
      for: asset,
      targetSize: size,
      contentMode: contentMode,
      options: options,
      resultHandler: resultHandler)
  }
}

