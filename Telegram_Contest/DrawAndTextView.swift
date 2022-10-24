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
    @IBOutlet weak var sizeField: UITextField!
    @IBOutlet weak var fontType: UISegmentedControl!
    @IBOutlet weak var textView: UIView!
    
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
    @IBAction func sizeChanged(_ sender: Any){}
    @IBAction func fontTypeChanged(_ sender: Any){}
    
    var color: UIColor?
    var font: String?
    var fontSize: String?
    
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
        
        let segmentedControl = UISegmentedControl(items: ["Arial-BoldMT", "Futura-Medium ", "Marker Felt"])
        sizeField.text = "36"
        DrawOrText = segmentedControl
        
        //let image = UIImage(named: "brush.png")
        //brushButton.setImage(image, for: .normal)
        
        colorButton.backgroundColor = .white
        
        acceptButton.isEnabled = false
        textView.isHidden = true
    }
}
