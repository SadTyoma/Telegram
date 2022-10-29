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

class PhotoViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var clearAllButton: UIBarButtonItem!
    @IBOutlet weak var photoView: UIImageViewExt!
    @IBOutlet weak var drawingTool: DrawAndTextView!
    @IBOutlet weak var text: UIImageView!
    
    var asset: PHAsset
    var editingOutput: PHContentEditingOutput?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    init?(asset: PHAsset, coder: NSCoder) {
        self.asset = asset
        super.init(coder: coder)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func didPinch(sender: UIPinchGestureRecognizer) {
        let scale = sender.scale
        let imageView = sender.view as! UIImageView
        imageView.transform = CGAffineTransformScale(imageView.transform, scale, scale)
    
        imageScale *= scale

        sender.scale = 1
    }
    
    @objc func didRotate(sender: UIRotationGestureRecognizer) {
        let rotation = sender.rotation
        let imageView = sender.view as! UIImageView
        imageView.transform = CGAffineTransformRotate(imageView.transform, rotation)
        imageRotation += rotation
        sender.rotation = 0
    }
    
    @objc func didPanned(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: text)
        
        text.frame.origin.x += translation.x
        text.frame.origin.y += translation.y
        
        textLocation?.x += translation.x
        textLocation?.y += translation.y
        
        sender.setTranslation(.zero, in: text)
    }
    
    @objc func didTapped(sender: UITapGestureRecognizer){
        let location = sender.location(in: self.view)
        if location.x > photoView.frame.width || location.y > photoView.frame.height{
            return
        }
        
        guard !drawingEnabled else{
            drawingTool.sizeView.isHidden = true
            
            return
        }
        
        textTouchLocation = location
        textLocation = sender.location(in: self.photoView)
        textField!.isHidden = false
        textBackgroundView?.isHidden = false
        verticalSizeSlider?.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if imageArray.isEmpty{
            imageArray.append(photoView.image)
        }
        
        textBackgroundView = UIView(frame: photoView.frame)
        textBackgroundView?.backgroundColor = .darkGray.withAlphaComponent(0.5)
        self.view.addSubview(textBackgroundView!)
        textBackgroundView?.isHidden = true
        
        textField =  UITextField()
        let midX = view.bounds.midX
        let midY = view.bounds.midY
        let size = CGSize(width: view.bounds.size.width / 2, height: view.bounds.height / 20)
        textField!.frame = CGRect(x: midX - size.width / 2, y: midY - size.height / 2, width: size.width, height: size.height)
        textField!.placeholder = "Enter text"
        textField!.borderStyle = UITextField.BorderStyle.roundedRect
        textField!.autocorrectionType = UITextAutocorrectionType.no
        textField!.keyboardType = UIKeyboardType.default
        textField!.returnKeyType = UIReturnKeyType.done
        textField!.clearButtonMode = UITextField.ViewMode.whileEditing
        textField!.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        textField!.delegate = self
        self.view.addSubview(textField!)
        textField!.isHidden = true
        
        createVerticalSlider()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.photoView.phVC = self
        self.photoView.isUserInteractionEnabled = true
        getPhoto()
        
        pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(sender:)))
        rotationRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(sender:)))
        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPanned(sender:)))
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapped(sender:)))
        
        view.isUserInteractionEnabled = true
        view.isMultipleTouchEnabled = true
        view.addGestureRecognizer(tapRecognizer!)
        text.isUserInteractionEnabled = true
        text.isMultipleTouchEnabled = true
        text.addGestureRecognizer(pinchRecognizer!)
        text.addGestureRecognizer(rotationRecognizer!)
        text.addGestureRecognizer(panRecognizer!)
        text.frame = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
        text.isHidden = true
        
        //DrawingTool
        drawingTool.undoButton.addTarget(self, action: #selector(self.undo), for: .touchUpInside)
        drawingTool.colorButton.addTarget(self, action: #selector(self.colorButtonClicked), for: .touchUpInside)
        drawingTool.sizeBar.addTarget(self, action: #selector(self.sizeChanged), for: .valueChanged)
        drawingTool.fontType.addTarget(self, action: #selector(self.fontTypeChanged), for: .valueChanged)
        drawingTool.brushButton.addTarget(self, action: #selector(self.brushButtonClicked), for: .touchUpInside)
        drawingTool.DrawOrText.addTarget(self, action: #selector(self.drawOrTextChanged), for: .valueChanged)
        drawingTool.acceptButton.addTarget(self, action: #selector(self.acceptButtonClicked), for: .touchUpInside)
        drawingTool.saveButton.addTarget(self, action: #selector(self.saveButtonClicked), for: .touchUpInside)
        
        updateUndoButton()
        drawingTool.acceptButton.isEnabled = false
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    func createVerticalSlider(){
        verticalSizeSlider = UISlider(frame: .zero)
        guard let slider = verticalSizeSlider else {return}
        slider.transform = CGAffineTransformMakeRotation(CGFloat(-Double.pi / 2))
        slider.maximumValue = 80
        slider.minimumValue = 20
        slider.value = 36
        slider.addTarget(self, action: #selector(self.sliderChanged), for: .valueChanged)
        slider.isContinuous = false
        slider.isHidden = true
        
        let xPos = 0.0
        let yPos = photoView.frame.height * 0.1
        let width = photoView.frame.width * 0.1
        let height = photoView.frame.height * 0.8
        let sliderFrame = CGRect(x: xPos, y: yPos, width: width, height: height)
        slider.frame = sliderFrame
        
        textBackgroundView?.addSubview(slider)
    }
    
    @objc func sliderChanged(sender: UISlider) {
        textSize = Double(sender.value)
    }
    
    func updateUndoButton() {
        let flag = imageArray.count > 1
        drawingTool.undoButton.isEnabled = flag
        drawingTool.undoButton.tintColor = flag ? .darkGray : .lightGray
    }
    
    @IBAction func clearAllClicked(_ sender: Any) {
        photoView.image = imageArray.first!
        photoView.incrementalImage = imageArray.first!
    }
    
    @objc func saveButtonClicked(){
        let image = imageArray.last!
        if let image = image{
            UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
        }
    }
    
    @objc func acceptButtonClicked() {
        let location = CGPoint(x: textLocation!.x - text!.frame.width / 2, y: textLocation!.y - text!.frame.height / 2)
        drawImage2(textImage, true, location)
        drawingTool.acceptButton.isEnabled = false
        text.isHidden = true
        text.frame = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
        text.transform = CGAffineTransformIdentity
        
        verticalSizeSlider?.isHidden = true
        
        self.photoView.isUserInteractionEnabled = true
        
        textTouchLocation = nil
        textImage = nil
    }
    
    @objc func drawOrTextChanged() {
        switch drawingTool.DrawOrText.selectedSegmentIndex
        {
        case 0:
            drawingEnabled = true
            if !textField!.isHidden{
                textField!.isHidden = true
                textBackgroundView?.isHidden = true
            }
        case 1:
            drawingEnabled = false
        default:
            break
        }
    }
    
    @objc func brushButtonClicked() {
        drawingTool.sizeView.isHidden = false
    }
    
    @objc func fontTypeChanged() {
        fontIndex = drawingTool.fontType.selectedSegmentIndex
    }
    
    @objc func sizeChanged() {
        textSize = Double(drawingTool.sizeBar.value)
    }
    
    @objc func colorButtonClicked() {
        let colorVC = UIColorPickerViewController()
        colorVC.delegate = self
        present(colorVC, animated: true)
    }
    
    @objc func undo() {
        if imageArray.count > 1{
            imageArray.removeLast()
            updateUndoButton()
            photoView.image = imageArray.last!
            photoView.incrementalImage = imageArray.last!
        }
    }
    
    func getPhoto() {
        photoView.fetchImageAsset(asset, targetSize: photoView.bounds.size, completionHandler: nil)
    }
    
    func createTextImage(text: String)->UIImage?{
        let attributes = [
            NSAttributedString.Key.foregroundColor : currentColor,
            NSAttributedString.Key.font : UIFont(name: fontTypes[fontIndex], size: textSize)!,
        ]
        
        let waterfallText = NSAttributedString(string: text, attributes: attributes)
        let textGenerationFilter = CIFilter(name: "CIAttributedTextImageGenerator")!
        textGenerationFilter.setValue(waterfallText, forKey: "inputText")
        textGenerationFilter.setValue(NSNumber(value: Double(1)), forKey: "inputScaleFactor")
        guard  let outputImage = textGenerationFilter.outputImage else { return nil }
        
        return UIImage(ciImage: outputImage)
    }
    
    public var drawingEnabled = true
    public var textTouchLocation: CGPoint?
    public var textLocation: CGPoint?
    public var textField : UITextField?
    public var textFromTextField = ""
    
    public var currentColor: UIColor = .black
    public let fontTypes = ["Arial-BoldMT", "HoeflerText-Italic", "Marker Felt"]
    public var pinchRecognizer: UIPinchGestureRecognizer?
    public var rotationRecognizer: UIRotationGestureRecognizer?
    public var panRecognizer: UIPanGestureRecognizer?
    public var tapRecognizer: UITapGestureRecognizer?
    public var verticalSizeSlider: UISlider?
    public var textImage: UIImage?
    public var textBackgroundView: UIView?
    public var imageRotation = 0.0
    public var imageScale = 1.0
    public var fontIndex = 0
    public var textSize = 36.0
    public var prelineSize: Double{
        get{
            return textSize / 8
        }
    }
    public var lineSize: Double{
        get{
            return textSize / 12
        }
    }
    public var imageArray = [UIImage?]()
    
    @objc func eraseDrawing(_ sender: UITapGestureRecognizer? = nil){
        self.photoView.setNeedsDisplay()
    }
    
    public func addToImageArray(_ image:UIImage?){
        imageArray.append(image)
        updateUndoButton()
    }
    
    public func drawImage(_ incrementalImage:UIImage?, _ saveImage: Bool, _ location: CGPoint?){
        if let incrementalImage = incrementalImage, let image = self.photoView.image{
            let size = self.photoView.bounds.size
            UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
            image.draw(in: CGRect(origin: .zero, size: size))
            
            if let location = location {
                let size = incrementalImage.size
                incrementalImage.draw(in: CGRect(origin: location, size: size))
            }else{
                incrementalImage.draw(in: CGRect(origin: .zero, size: size))
            }
            
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self.photoView.image = newImage
            if saveImage{
                addToImageArray(newImage)
            }
        }
    }
    
    public func drawImage2(_ incrementalImage:UIImage?, _ saveImage: Bool, _ location: CGPoint?){
        if let incrementalImage = incrementalImage, let image = self.photoView.image{
            let scaled = incrementalImage.scale(by: imageScale)
            let rotated = scaled!.rotate(radians: Float(imageRotation))
            
            let size = self.photoView.bounds.size
            UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
            image.draw(in: CGRect(origin: .zero, size: size))
            
            if let location = location {
                let size = rotated!.size
                rotated!.draw(in: CGRect(origin: location, size: size))
            }else{
                rotated!.draw(in: CGRect(origin: .zero, size: size))
            }
            
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self.photoView.image = newImage
            if saveImage{
                addToImageArray(newImage)
            }
        }
    }
}

extension PhotoViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.sync {
            let lastImage = imageArray.last!
            imageArray.removeAll()
            imageArray.append(lastImage)
            
            updateUndoButton()
        }
    }
}

extension PhotoViewController: UITextFieldDelegate{
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textFromTextField = ""
        textField.text = textFromTextField
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textFromTextField = textField.text!
        textField.isHidden = true
        textBackgroundView?.isHidden = true
        self.view.endEditing(true)
                
        textImage = createTextImage(text: textFromTextField)
        let textView = UIImageView(image: textImage)
        if let textTouchLocation = textTouchLocation {
            text.frame = textView.frame
            text.image = textImage
            text.center = textTouchLocation
            text.isHidden = false
        }
        
        self.photoView.isUserInteractionEnabled = false
        
        drawingTool.acceptButton.isEnabled = true
        textFromTextField = ""
        textField.text = textFromTextField
        
        return true
    }
}

extension PhotoViewController: UIColorPickerViewControllerDelegate{
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        let color = viewController.selectedColor
        currentColor = color
        drawingTool.imageTip.tintColor = color
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

struct LineSegment{
    var firstPoint: CGPoint
    var secondPoint: CGPoint
}

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
    
    func resize(targetSize: CGSize) -> UIImage {
        let size = self.size
            
            let widthRatio  = targetSize.width  / size.width
            let heightRatio = targetSize.height / size.height
            
            var newSize: CGSize
            if widthRatio > heightRatio {
                newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
            } else {
                newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
            }
            
            let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
            self.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return newImage!
        }
    
    func scale(by scale: CGFloat) -> UIImage? {
            let size = self.size
            let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        return self.resize(targetSize: scaledSize)
        }
}
