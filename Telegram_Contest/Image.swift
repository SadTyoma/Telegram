//
//  Image.swift
//  Telegram_Contest
//
//  Created by Artem Shuneyko on 13.10.22.
//

import SwiftUI
import UIKit

struct Image: Identifiable {

    let id = UUID()
    let url: URL

}

extension Image: Equatable {
    static func ==(lhs: Image, rhs: Image) -> Bool {
        return lhs.id == rhs.id && lhs.id == rhs.id
    }
}


extension UIImage {
    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let scaleFactor = min(widthRatio, heightRatio)
        
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )

        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        
        return scaledImage
    }
}
