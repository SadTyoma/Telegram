//
//  PhotoViewController.swift
//  Telegram_Contest
//
//  Created by Artem Shuneyko on 14.10.22.
//

import UIKit
import Photos

class PhotoViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var clearAllButton: UIBarButtonItem!
    @IBOutlet weak var photoView: UIImageViewForDrawing!
    @IBOutlet weak var drawingTool: DrawAndTextView!
    @IBOutlet weak var text: UIImageView!
    
    private var asset: PHAsset
    private var textTouchLocation: CGPoint?
    private var textLocation: CGPoint?
    private var textField : UITextField?
    private var textFromTextField = ""
    private let fontTypes = ["Arial-BoldMT", "HoeflerText-Italic", "Marker Felt"]
    private var pinchRecognizer: UIPinchGestureRecognizer?
    private var rotationRecognizer: UIRotationGestureRecognizer?
    private var panRecognizer: UIPanGestureRecognizer?
    private var tapRecognizer: UITapGestureRecognizer?
    private var verticalSizeSlider: UISlider?
    private var textImage: UIImage?
    private var textBackgroundView: UIView?
    private var imageRotation = 0.0
    private var imageScale = 1.0
    private var fontIndex = 0
    
    public var currentColor: UIColor = .black
    public var drawingEnabled = true
    public var textSize = 36.0
    public var prelineSize: Double{ get{ return textSize / 8 } }
    public var lineSize: Double{ get{ return textSize / 12 } }
    public var imageArray = [UIImage?]()
    
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
        let imageView = sender.view as! UIImageView
        let translation = sender.translation(in: imageView)
    
        let oldTransform = imageView.transform
        let newTransform = oldTransform.translatedBy(x: translation.x,
                                                     y: translation.y)
        imageView.transform = newTransform
        
        if text.frame.origin.x < 0.0 || text.frame.origin.x + text.frame.width > photoView.frame.width || text.frame.origin.y + text.frame.height > photoView.frame.height + photoView.frame.origin.y || text.frame.origin.y < photoView.frame.origin.y {
            imageView.transform = oldTransform
            return
        }
        
        textLocation?.x += translation.x
        textLocation?.y += translation.y
        
        sender.setTranslation(.zero, in: imageView)
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
    
    private func createVerticalSlider(){
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
        drawingTool.sizeBar.value = Float(textSize)
    }
    
    private func updateUndoButton() {
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
        drawImage(textImage, true, text.frame.origin)
        drawingTool.acceptButton.isEnabled = false
        text.isHidden = true
        text.frame = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
        text.transform = CGAffineTransformIdentity
        
        verticalSizeSlider?.isHidden = true
        
        self.photoView.isUserInteractionEnabled = true
        
        imageScale = 1.0
        imageRotation = 0.0
        
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
            drawingTool.sizeView.isHidden = true
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
        verticalSizeSlider?.value = Float(textSize)
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
    
    private func getPhoto() {
        photoView.fetchImageAsset(asset, targetSize: photoView.bounds.size, completionHandler: nil)
    }
    
    private func createTextImage(text: String)->UIImage?{
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
    
    @objc func eraseDrawing(_ sender: UITapGestureRecognizer? = nil){
        self.photoView.setNeedsDisplay()
    }
    
    public func addToImageArray(_ image:UIImage?){
        imageArray.append(image)
        updateUndoButton()
    }
    
    public func drawImage(_ incrementalImage:UIImage?){
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
    
    public func drawImage(_ incrementalImage:UIImage?, _ saveImage: Bool, _ location: CGPoint?){
        if let incrementalImage = incrementalImage, let image = self.photoView.image{
            let scaled = incrementalImage.scale(by: imageScale)
            let rotated = scaled!.rotate(radians: Float(imageRotation))
            
            let size = self.photoView.bounds.size
            UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
            image.draw(in: CGRect(origin: .zero, size: size))
            
            if var location = location {
                let size = rotated!.size
                location.y -= photoView.frame.origin.y
                rotated!.draw(in: CGRect(origin: location, size: size))
            } else {
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
