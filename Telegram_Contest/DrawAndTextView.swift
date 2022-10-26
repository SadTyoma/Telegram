//
//  DrawAndTextView.swift
//  Telegram_Contest
//
//  Created by Artem Shuneyko on 24.10.22.
//

import UIKit

class DrawAndTextView: UIView {
    @IBOutlet weak var colorButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var brushButton: UIButton!
    @IBOutlet weak var DrawOrText: UISegmentedControl!
    @IBOutlet weak var fontType: UISegmentedControl!
    @IBOutlet weak var textView: UIView!
    @IBOutlet weak var sizeView: UIView!
    @IBOutlet weak var sizeButton: UIButton!
    @IBOutlet weak var sizeBar: UISlider!
    
    var sizeViewState = false
    @IBAction func sizeButtonClicked(_ sender: Any){
        sizeView.isHidden = sizeViewState
        sizeViewState = !sizeViewState
    }
    @IBAction func brushButtonClicked(_ sender: Any){}
    @IBAction func colorButtonClicked(_ sender: Any){}
    @IBAction func undoButtonClicked(_ sender: Any){}
    @IBAction func acceptButtonClicked(_ sender: Any){
        acceptButton.isEnabled = false
    }
    @IBAction func DrawOrTextChanged(_ sender: UISegmentedControl){
        switch sender.selectedSegmentIndex{
        case 0:
            textView.isHidden = true
        case 1:
            textView.isHidden = false
        default:
            textView.isHidden = true
        }
    }
    @IBAction func fontTypeChanged(_ sender: Any){}
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit(){
        let view = Bundle.main.loadNibNamed("DrawAndTextView", owner: self, options: nil)![0] as! UIView
        view.frame = self.bounds
        addSubview(view)
        
        sizeView.isHidden = true
        
        let image = UIImage(named: "brush.png")
        let newimage = resizeImage(image: image!, targetSize: brushButton.frame.size)
        brushButton.setImage(newimage, for: .normal)
        
        colorButton.backgroundColor = .black
        sizeButton.backgroundColor = .black
                
        acceptButton.isEnabled = false
        textView.isHidden = true
        
        colorButton.layer.cornerRadius = 5
        colorButton.layer.borderWidth = 2
        colorButton.layer.borderColor = UIColor.white.cgColor
        
        sizeButton.layer.cornerRadius = 5
        sizeButton.layer.borderWidth = 2
        sizeButton.layer.borderColor = UIColor.white.cgColor
        
        sizeBar.maximumValue = 80
        sizeBar.minimumValue = 20
        sizeBar.value = 36
    }
    
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(origin: .zero, size: newSize)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
