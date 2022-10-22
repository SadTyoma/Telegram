//
//  PhotoViewController.swift
//  Telegram_Contest
//
//  Created by Artem Shuneyko on 14.10.22.
//

import UIKit
import Photos

let CAPACITY = 100
let FF = 0.2
let LOWER = 0.01
let UPPER = 1.0

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
        self.photoView.isMultipleTouchEnabled = false
        tap = UITapGestureRecognizer(target: self, action: #selector(eraseDrawing(_:)))
        tap?.numberOfTapsRequired = 2
        if let tap = tap{
            self.photoView.addGestureRecognizer(tap)
        }
        
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
        photoView.fetchImageAsset(asset, targetSize: photoView.bounds.size, completionHandler: nil)
    }
    
    struct LineSegment{
        var firstPoint: CGPoint
        var secondPoint: CGPoint
    }
    
    private var incrementalImage: UIImage?
    private var lastImage: UIImage?
    private var pts = [CGPoint](repeating: CGPoint.zero, count: 5)
    private var ctr = 0
    private var pointsBuffer = [CGPoint](repeating: CGPoint.zero, count: CAPACITY)
    private var bufIdx = 0
    private var drawingQueue = DispatchQueue(label: "com.artyomshuneyko.drawing")
    private var isFirstTouchPoint = false
    private var lastSegmentOfPrev: LineSegment?
    private var tap: UITapGestureRecognizer?
    private var fullPath = UIBezierPath() //TODO remove
    private var points = [CGPoint]()
    
    @objc func eraseDrawing(_ sender: UITapGestureRecognizer? = nil){
        incrementalImage = nil
        self.photoView.setNeedsDisplay()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        ctr = 0
        bufIdx = 0
        let touch = touches.first
        pts[0] = (touch?.location(in: self.photoView))!
        isFirstTouchPoint = true
        lastImage = photoView.image
        fullPath = UIBezierPath()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let p = touch?.location(in: self.photoView)
        points.append(p!)
        ctr += 1
        pts[ctr] = p!
        if ctr == 4 {
            pts[3] = CGPoint(x: (pts[2].x + pts[4].x) / 2.0, y: (pts[2].y + pts[4].y) / 2.0)

            for i in 0..<4 {
                pointsBuffer[bufIdx + i] = pts[i]
            }

            bufIdx += 4

            let bounds = self.photoView.bounds

            drawingQueue.async(execute: { [self] in
                let offsetPath = UIBezierPath() // ................. (2)
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

                    let frac1: Double = FF / clamp(len_sq(pointsBuffer[i], pointsBuffer[i + 1]), LOWER, UPPER) // ................. (4)
                    let frac2: Double = FF / clamp(len_sq(pointsBuffer[i + 1], pointsBuffer[i + 2]), LOWER, UPPER)
                    let frac3: Double = FF / clamp(len_sq(pointsBuffer[i + 2], pointsBuffer[i + 3]), LOWER, UPPER)
                    ls[1] = lineSegmentPerpendicular(to: LineSegment(firstPoint: pointsBuffer[i], secondPoint: pointsBuffer[i + 1]), ofRelativeLength: frac1) // ................. (5)
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
                    UIColor.black.setStroke()
                    UIColor.black.setFill()
                    offsetPath.stroke() // ................. (8)
                    offsetPath.fill()
                }
                
                self.incrementalImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                offsetPath.removeAllPoints()
                DispatchQueue.main.async(execute: { [self] in
                    drawImage()
                    bufIdx = 0
                    self.photoView.setNeedsDisplay()
                })
            })
            pts[0] = pts[3]
            pts[1] = pts[4]
            ctr = 1
        }
    }
    
    func drawRect(rect: CGRect){
        incrementalImage?.draw(in: rect)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fullPath.close()
        let bounds = self.photoView.bounds
        
        var newImage: UIImage?
        let classificationResult = classify()
        switch classificationResult.type{
        case .rectangle:
            newImage = drawRectangle(classificationResult)
        case .circle:
            newImage = drawCircle(classificationResult)
        default:
            if let image = lastImage{
                UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0.0)
                image.draw(in: CGRect(origin: .zero, size: bounds.size))
                var incImage = UIGraphicsGetImageFromCurrentImageContext()

                incImage!.draw(at: .zero)
                UIColor.black.setStroke()
                UIColor.black.setFill()
                fullPath.stroke()
                fullPath.fill()
                incImage = UIGraphicsGetImageFromCurrentImageContext()

                image.draw(in: CGRect(origin: .zero, size: bounds.size))
                incImage!.draw(in: CGRect(origin: .zero, size: bounds.size))
                newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
            }
        }
        
        self.photoView.image = newImage
        incrementalImage = newImage
        points = [CGPoint]()
        fullPath.removeAllPoints()
        self.photoView.setNeedsDisplay()
    }
    
    func drawRectangle(_ clResult: ClassificationResult) -> UIImage? {
        guard let image = lastImage else {return nil}
        let bounds = self.photoView.bounds

        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0.0)
        image.draw(in: CGRect(origin: .zero, size: bounds.size))
        var incImage = UIGraphicsGetImageFromCurrentImageContext()
        incImage!.draw(at: .zero)

        let rectangle = CGRect(x: clResult.x, y: clResult.y, width: clResult.width, height: clResult.height)

        UIColor.black.setFill()
        UIRectFrame(rectangle)

        incImage = UIGraphicsGetImageFromCurrentImageContext()

        image.draw(in: CGRect(origin: .zero, size: bounds.size))
        incImage!.draw(in: CGRect(origin: .zero, size: bounds.size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func drawCircle(_ clResult: ClassificationResult) -> UIImage? {
        let center = CGPoint(x: clResult.x + clResult.width / 2, y: clResult.y + clResult.height / 2)
        let path = UIBezierPath()
        path.addArc(withCenter: center, radius: clResult.height / 2, startAngle: 0.0, endAngle: Double.pi * 2.0, clockwise: true)
        
        let bounds = self.photoView.bounds
        guard let image = lastImage else {return nil}
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0.0)
        image.draw(in: CGRect(origin: .zero, size: bounds.size))
        var incImage = UIGraphicsGetImageFromCurrentImageContext()

        incImage!.draw(at: .zero)
        UIColor.black.setStroke()
        UIColor.clear.setFill()
        path.stroke()
        path.fill()
        incImage = UIGraphicsGetImageFromCurrentImageContext()

        image.draw(in: CGRect(origin: .zero, size: bounds.size))
        incImage!.draw(in: CGRect(origin: .zero, size: bounds.size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    private func drawImage(){
        if let incrementalImage = incrementalImage, let image = self.photoView.image{
            let size = self.photoView.bounds.size
            UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
            image.draw(in: CGRect(origin: .zero, size: size))
            incrementalImage.draw(in: CGRect(origin: .zero, size: size))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self.photoView.image = newImage
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchesEnded(touches, with: event)
    }
    
    private func classify()->ClassificationResult{
        var left = self.photoView.bounds.width
        var top = self.photoView.bounds.height
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
        
        let center = CGPoint(x: (left+right)/2, y: (top+bottom)/2)
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
        }else if corners.count == 3{
            return ClassificationResult(type: .triangle, x: left, y: top, height: bottom - top, width: right - left)
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
    
    private func lineSegmentPerpendicular(to pp: LineSegment, ofRelativeLength fraction: Double) -> LineSegment {
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
