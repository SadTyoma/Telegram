//
//  UIImageViewExt.swift
//  Telegram_Contest
//
//  Created by Artem Shuneyko on 28.10.22.
//

import UIKit

class UIImageViewForDrawing: UIImageView {
    private var drawingQueue = DispatchQueue(label: "com.telegram.drawing")
    private var lastImage: UIImage?
    private var pts = [CGPoint](repeating: CGPoint.zero, count: 5)
    private var ctr = 0
    private var pointsBuffer = [CGPoint](repeating: CGPoint.zero, count: Constants.CAPACITY)
    private var bufIdx = 0
    private var isFirstTouchPoint = false
    private var lastSegmentOfPrev: LineSegment?
    private var fullPath = UIBezierPath()
    private var points = [CGPoint]()
    
    public var phVC: PhotoViewController?
    public var photoVC: PhotoViewController{ get{ return phVC! } }
    public var incrementalImage: UIImage?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let location = (touch?.location(in: self))!
        
        guard photoVC.drawingEnabled else {
            return
        }
        
        ctr = 0
        bufIdx = 0
        pts[0] = location
        isFirstTouchPoint = true
        lastImage = image
        fullPath = UIBezierPath()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard photoVC.drawingEnabled else {return}
        
        let touch = touches.first
        let p = touch?.location(in: self)
        points.append(p!)
        ctr += 1
        pts[ctr] = p!
        if ctr == 4 {
            pts[3] = CGPoint(x: (pts[2].x + pts[4].x) / 2.0, y: (pts[2].y + pts[4].y) / 2.0)
            
            for i in 0..<4 {
                pointsBuffer[bufIdx + i] = pts[i]
            }
            
            bufIdx += 4
            
            let bounds = self.bounds
            
            drawingQueue.async{ [self] in
                let offsetPath = UIBezierPath()
                if bufIdx == 0 {
                    return
                }
                
                var ls = [LineSegment](repeating: LineSegment(firstPoint: CGPoint.zero, secondPoint: CGPoint.zero), count: 4)
                var i = 0
                while i < bufIdx {
                    if isFirstTouchPoint {
                        ls[0] = LineSegment(firstPoint: pointsBuffer[0], secondPoint: pointsBuffer[0])
                        offsetPath.move(to: ls[0].firstPoint)
                        fullPath.move(to: ls[0].firstPoint)
                        isFirstTouchPoint = false
                    } else {
                        if let lastSegmentOfPrev = lastSegmentOfPrev {
                            ls[0] = lastSegmentOfPrev
                        }
                    }
                    
                    let frac1: Double = Constants.FF / clamp(len_sq(pointsBuffer[i], pointsBuffer[i + 1]), Constants.LOWER, Constants.UPPER)
                    let frac2: Double = Constants.FF / clamp(len_sq(pointsBuffer[i + 1], pointsBuffer[i + 2]), Constants.LOWER, Constants.UPPER)
                    let frac3: Double = Constants.FF / clamp(len_sq(pointsBuffer[i + 2], pointsBuffer[i + 3]), Constants.LOWER, Constants.UPPER)
                    ls[1] = lineSegmentPerpendicular(to: LineSegment(firstPoint: pointsBuffer[i], secondPoint: pointsBuffer[i + 1]), ofRelativeLength: frac1)
                    ls[2] = lineSegmentPerpendicular(to: LineSegment(firstPoint: pointsBuffer[i + 1], secondPoint: pointsBuffer[i + 2]), ofRelativeLength: frac2)
                    ls[3] = lineSegmentPerpendicular(to: LineSegment(firstPoint: pointsBuffer[i + 2], secondPoint: pointsBuffer[i + 3]), ofRelativeLength: frac3)
                    
                    offsetPath.move(to: ls[0].firstPoint)
                    fullPath.move(to: ls[0].firstPoint)
                    
                    offsetPath.addCurve(to: ls[3].firstPoint, controlPoint1: ls[1].firstPoint, controlPoint2: ls[2].firstPoint)
                    fullPath.addCurve(to: ls[3].firstPoint, controlPoint1: ls[1].firstPoint, controlPoint2: ls[2].firstPoint)
                    
                    offsetPath.addLine(to: ls[3].secondPoint)
                    fullPath.addLine(to: ls[3].secondPoint)
                    
                    offsetPath.addCurve(to: ls[0].secondPoint, controlPoint1: ls[2].secondPoint, controlPoint2: ls[1].secondPoint)
                    fullPath.addCurve(to: ls[0].secondPoint, controlPoint1: ls[2].secondPoint, controlPoint2: ls[1].secondPoint)
                    
                    offsetPath.close()
                    
                    lastSegmentOfPrev = ls[3]
                    i += 4
                }
                UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0.0)
                if incrementalImage == nil{
                    lastImage!.draw(in: CGRect(origin: .zero, size: bounds.size))
                }
                if let incrementalImage = incrementalImage {
                    incrementalImage.draw(at: .zero)
                    photoVC.currentColor.setStroke()
                    photoVC.currentColor.setFill()
                    offsetPath.lineWidth = photoVC.prelineSize
                    offsetPath.stroke()
                    offsetPath.fill()
                }
                
                self.incrementalImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                offsetPath.removeAllPoints()
                DispatchQueue.main.async(execute: { [self] in
                    photoVC.drawImage(incrementalImage)
                    bufIdx = 0
                    self.setNeedsDisplay()
                })
            }
            pts[0] = pts[3]
            pts[1] = pts[4]
            ctr = 1
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard photoVC.drawingEnabled else {return}
        fullPath.close()
        
        var newImage: UIImage?
        let classificationResult = classify()
        switch classificationResult.type{
        case .rectangle:
            newImage = drawRectangle(classificationResult)
        case .circle:
            newImage = drawCircle(classificationResult)
        default:
            newImage = drawUnknown()
            incrementalImage = newImage
            points = [CGPoint]()
            fullPath.removeAllPoints()
        }
        
        UIView.transition(with: self,
                          duration: 0.5,
                          options: .transitionCrossDissolve,
                          animations: { self.image = newImage },
                          completion: nil)
        
        incrementalImage = newImage
        points = [CGPoint]()
        fullPath.removeAllPoints()
        self.setNeedsDisplay()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchesEnded(touches, with: event)
    }
    
    public func lineSegmentPerpendicular(to pp: LineSegment, ofRelativeLength fraction: Double) -> LineSegment {
        let x0 = pp.firstPoint.x
        let y0 = pp.firstPoint.y
        let x1 = pp.secondPoint.x
        let y1 = pp.secondPoint.y
        
        var dx: CGFloat
        var dy: CGFloat
        dx = x1 - x0
        dy = y1 - y0
        
        var xa: CGFloat
        var ya: CGFloat
        var xb: CGFloat
        var yb: CGFloat
        xa = x1 + CGFloat(fraction / 2) * dy
        ya = y1 - CGFloat(fraction / 2) * dx
        xb = x1 - CGFloat(fraction / 2) * dy
        yb = y1 + CGFloat(fraction / 2) * dx
        
        return LineSegment(firstPoint: CGPoint(x: xa, y: ya), secondPoint: CGPoint(x: xb, y: yb))
        
    }
    
    private func len_sq(_ p1: CGPoint,_ p2: CGPoint)->Double{
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        
        return dx * dx + dy * dy
    }
    
    private func clamp(_ value: Double,_ lower: Double,_ higher: Double)->Double{
        if value < lower{
            return lower
        }
        if value > higher{
            return higher
        }
        return value
    }
    
    private func drawCircle(_ clResult: ClassificationResult) -> UIImage? {
        let center = CGPoint(x: clResult.x + clResult.width / 2, y: clResult.y + clResult.height / 2)
        let path = UIBezierPath()
        path.addArc(withCenter: center, radius: clResult.height / 2, startAngle: 0.0, endAngle: Double.pi * 2.0, clockwise: true)
        
        let bounds = self.bounds
        guard let image = lastImage else {return nil}
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0.0)
        image.draw(in: CGRect(origin: .zero, size: bounds.size))
        var incImage = UIGraphicsGetImageFromCurrentImageContext()
        
        incImage!.draw(at: .zero)
        photoVC.currentColor.setStroke()
        path.lineWidth = photoVC.prelineSize
        path.stroke()
        incImage = UIGraphicsGetImageFromCurrentImageContext()
        
        image.draw(in: CGRect(origin: .zero, size: bounds.size))
        incImage!.draw(in: CGRect(origin: .zero, size: bounds.size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        photoVC.addToImageArray(newImage)
        
        return newImage
    }
    
    private func drawRectangle(_ clResult: ClassificationResult) -> UIImage? {
        guard let image = lastImage else {return nil}
        let bounds = self.bounds
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0.0)
        image.draw(in: CGRect(origin: .zero, size: bounds.size))
        var incImage = UIGraphicsGetImageFromCurrentImageContext()
        incImage!.draw(at: .zero)
        
        let rectangle = CGRect(x: clResult.x, y: clResult.y, width: clResult.width, height: clResult.height)
        let context = UIGraphicsGetCurrentContext()
        context!.setLineWidth(photoVC.prelineSize);
        
        photoVC.currentColor.setStroke()
        UIRectFrame(rectangle)
        
        incImage = UIGraphicsGetImageFromCurrentImageContext()
        
        image.draw(in: CGRect(origin: .zero, size: bounds.size))
        incImage!.draw(in: CGRect(origin: .zero, size: bounds.size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        photoVC.addToImageArray(newImage)
        
        return newImage
    }
    
    private func drawUnknown()->UIImage?{
        let bounds = self.bounds
        guard let image = lastImage else {return nil}
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0.0)
        image.draw(in: CGRect(origin: .zero, size: bounds.size))
        var incImage = UIGraphicsGetImageFromCurrentImageContext()
        
        incImage!.draw(at: .zero)
        photoVC.currentColor.setStroke()
        photoVC.currentColor.setFill()
        fullPath.lineWidth = photoVC.lineSize
        fullPath.stroke()
        fullPath.fill()
        incImage = UIGraphicsGetImageFromCurrentImageContext()
        
        image.draw(in: CGRect(origin: .zero, size: bounds.size))
        incImage!.draw(in: CGRect(origin: .zero, size: bounds.size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        photoVC.addToImageArray(newImage)
        
        return newImage
    }
    
    private func classify()->ClassificationResult{
        var left = self.bounds.width
        var top = self.bounds.height
        var right = 0.0
        var bottom = 0.0
        
        for point in points {
            if left > point.x{
                left = point.x
            }
            if right < point.x{
                right = point.x
            }
            if top > point.y{
                top = point.y
            }
            if bottom < point.y{
                bottom = point.y
            }
        }
        
        var sects = [Sector](repeating: Sector(x: 0, y: 0, c: 0), count: 9)
        let x3 = (right + (1/(right-left)) - left) / 3
        let y3 = (bottom + (1/(bottom-top)) - top) / 3
        for point in points {
            let sx = floor((point.x - left)/x3)
            let sy = floor((point.y - top)/y3)
            let idx = Int(sy * 3 + sx)
            sects[idx].x += point.x
            sects[idx].y += point.y
            sects[idx].c += 1
            if sx == 1 && sy == 1 {
                return ClassificationResult(type: .unknown, x: 0, y: 0, height: 0, width: 0)
            }
        }
        var sigPts = [Sector]()
        let clk = [0, 1, 2, 5, 8, 7, 6, 3]
        for cl in clk{
            let pt = sects[cl];
            if(pt.c > 0) {
                sigPts.append(Sector(x: pt.x / CGFloat(pt.c), y: pt.y / CGFloat(pt.c), c: 0))
            } else {
                return ClassificationResult(type: .unknown, x: 0, y: 0, height: 0, width: 0)
            }
        }
        var angles = [Double]()
        var i = 0
        while i < sigPts.count{
            let a = sigPts[i]
            let b = sigPts[(i + 1) % sigPts.count]
            let c = sigPts[(i + 2) % sigPts.count]
            let ab = sqrt(pow(b.x-a.x, 2)+pow(b.y-a.y, 2))
            let bc = sqrt(pow(b.x-c.x, 2)+pow(b.y-c.y, 2))
            let ac = sqrt(pow(c.x-a.x, 2)+pow(c.y-a.y, 2))
            let deg = floor(acos((pow(bc, 2) + pow(ab, 2) - pow(ac, 2))/(2*bc*ab)) * 180 / Double.pi)
            
            angles.append(deg)
            i += 1
        }
        
        let corners = getCorners(angles: angles, pts: sigPts)
        if corners.count <= 1 {
            return ClassificationResult(type: .circle, x: left, y: top, height: bottom - top, width: right - left)
        }else if corners.count == 4 {
            return ClassificationResult(type: .rectangle, x: left, y: top, height: bottom - top, width: right - left)
        } else {
            return ClassificationResult(type: .unknown, x: 0, y: 0, height: 0, width: 0)
        }
    }
    
    private func getCorners(angles: [Double], pts: [Sector])->[Sector]{
        var list = [Sector]()
        if pts.isEmpty{
            list = points.map { p in
                Sector(point: p, c: 0)
            }
        }else{
            list = pts
        }
        
        var corners = [Sector]()
        var i = 0
        while i < angles.count{
            if angles[i] < 125{
                corners.append(list[(i + 1) % list.count])
            }
            i += 1
        }
        return corners
    }
}

struct LineSegment{
    var firstPoint: CGPoint
    var secondPoint: CGPoint
}
