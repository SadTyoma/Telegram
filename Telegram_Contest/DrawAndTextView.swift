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
    @IBOutlet weak var imageTip: UIImageView!
    
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
        
        let image = UIImage(named: "pencil-tip")?.withRenderingMode(.alwaysTemplate)
        imageTip.image = image
        imageTip.tintColor = .black
                
        acceptButton.isEnabled = false
        textView.isHidden = true
        
        sizeBar.maximumValue = 80
        sizeBar.minimumValue = 20
        sizeBar.value = 36
    }
}
