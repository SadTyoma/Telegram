//
//  DataController.swift
//  Telegram_Contest
//
//  Created by Artem Shuneyko on 17.10.22.
//

import Foundation
import UIKit
import Photos

public class DataController{
    private static var instance: DataController? = nil
    private let dataQueue = DispatchQueue(label: "com.artyomshuneyko.load_data")
    public static var data = [UIImage?]()
    
    public static func getInstance()->DataController{
        if(self.instance == nil){
            self.instance = DataController()
        }
        return instance!
    }
    
    public static func addImage(image: UIImage){
        DataController.data.append(image)
    }
    
    public func startLoadData(assets: PHFetchResult<PHAsset>){        
        dataQueue.async {
            //for index in 0...assets.count - 1{
            for index in 0...100{
                let resultHandler: (UIImage?, [AnyHashable: Any]?) -> Void = { image, info in
                    DataController.data.append(image)
                }
                
                PHImageManager.default().requestImage(
                    for: assets[index],
                    targetSize: PHImageManagerMaximumSize,
                    contentMode: .aspectFill,
                    options: nil,
                    resultHandler: resultHandler)
            }
        }
    }
}
