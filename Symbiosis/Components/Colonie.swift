//
//  colonie.swift
//  symbiosis-ios-app
//
//  Created by Quentin Tshaimanga on 05/06/2016.
//  Copyright © 2016 Etienne De Ladonchamps. All rights reserved.
//

import Foundation
import UIKit

class SYColonie: UIView {

    @IBOutlet var view: UIView!
    @IBOutlet weak var colonieName: UILabel!
    @IBOutlet weak var closeColonie: UIButton!
    @IBOutlet weak var commentaires: UIButton!
    
    let background = Background()
    
    // MARK: Init
    var nibName: String = "Colonie"

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK: Setup
    func setup() {
        
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        addSubview(view)
        
        view?.superview!.hidden = true
        closeColonie.addTarget(self, action:#selector(self.hideColonie), forControlEvents: .TouchUpInside)
  
    }
    
    func addbackground(name: String){        
        view?.superview!.hidden = false
        view?.superview!.layer.zPosition = 1
        
        commentaires.titleLabel?.textColor = background.hexStringToUIColor("#BBB3B3")
        commentaires.layer.borderColor = UIColor.lightGrayColor().CGColor
        
        colonieName.text = name
        colonieName.textColor = background.hexStringToUIColor("#FF6A4D")
        
    }

    
    func hideColonie(){
        //view?.superview!.removeFromSuperview()
        view?.superview!.hidden = true
    }
    
    func loadViewFromNib() -> UIView {
        
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: nibName, bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }

    
    
}