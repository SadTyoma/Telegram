//
//  ClassificationHelpers.swift
//  Telegram_Contest
//
//  Created by Artem Shuneyko on 30.10.22.
//

import Foundation
import CoreGraphics

struct Sector{
    var x:CGFloat
    var y:CGFloat
    var c:Int
    
    public init(point: CGPoint, c: Int){
        x = point.x
        y = point.y
        self.c = c
    }
    
    public init(x:CGFloat,y:CGFloat,c:Int){
        self.x = x
        self.y = y
        self.c = c
    }
}

struct ClassificationResult{
    var type: ShapeType
    var x: CGFloat
    var y: CGFloat
    var height: CGFloat
    var width: CGFloat
}

enum ShapeType{
    case rectangle
    case circle
    case triangle
    case unknown
}
