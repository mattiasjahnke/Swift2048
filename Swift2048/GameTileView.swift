//
//  GameTileView.swift
//  CloneA2048
//
//  Created by Mattias Jähnke on 2015-06-30.
//  Copyright © 2015 Nearedge. All rights reserved.
//

import UIKit

typealias ColorScheme = [String : [String : String]]

class GameTileView: UIView {

    var destroy = false
    var position = CGPoint(x: -1, y: -1)
    var cornerRadius: CGFloat = 0 {
        didSet {
            valueLabel.layer.cornerRadius = cornerRadius
        }
    }
    var value = -1 {
        didSet {
            if !valueHidden {
                valueLabel.text = "\(value)"
            }
            let str = value <= 2048 ? "\(value)" : "super"
            valueLabel.backgroundColor = colorForType(str, key: "background")
            valueLabel.textColor = colorForType(str, key: "text")
        }
    }
    var valueHidden = false {
        didSet {
            if valueHidden {
                valueLabel.text = ""
            }
        }
    }
    var colorScheme: ColorScheme?
    
    var valueLabel = UILabel()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        alpha = 0
        
        valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = UIFont.boldSystemFontOfSize(70)
        valueLabel.minimumScaleFactor = 0.4
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.textAlignment = .Center
        valueLabel.clipsToBounds = true
        valueLabel.backgroundColor = UIColor(white: 0.5, alpha: 0.2)
        
        self.addSubview(valueLabel)
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-5-[valueLabel]-5-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["valueLabel" : valueLabel]))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-5-[valueLabel]-5-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["valueLabel" : valueLabel]))
    }
    
    private func colorForType(value: String, key: String) -> UIColor {
        if let colorScheme = colorScheme {
            if let vDic = colorScheme[value], s = vDic[key] {
                return UIColor.colorWithHex(s)
            } else {
                if let vDic = colorScheme["default"], s = vDic[key] {
                    return UIColor.colorWithHex(s)
                }
            }
        }
        return UIColor.blackColor()
    }
}

extension UIColor {
    class func colorWithHex(hex: String) -> UIColor {
        var cString = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet() as NSCharacterSet).uppercaseString
        
        if (cString.hasPrefix("0X")) {
            cString = cString.substringFromIndex(advance(cString.startIndex, 2))
        }
        
        if (cString.characters.count != 6) {
            return UIColor.grayColor()
        }
        
        var rgbValue:UInt32 = 0
        NSScanner(string: cString).scanHexInt(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
