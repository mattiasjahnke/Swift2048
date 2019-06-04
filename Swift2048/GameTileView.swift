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
    var position = (x: -1, y: -1)
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
    private var isSetup = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    fileprivate func setup() {
        guard !isSetup else { return }
        isSetup = true
        alpha = 0
        
        valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = UIFont.boldSystemFont(ofSize: 70)
        valueLabel.minimumScaleFactor = 0.4
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.textAlignment = .center
        valueLabel.clipsToBounds = true
        valueLabel.baselineAdjustment = .alignCenters
        valueLabel.backgroundColor = UIColor(white: 0.5, alpha: 0.2)
        
        self.addSubview(valueLabel)
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-p-[valueLabel]-p-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: ["p": 5], views: ["valueLabel" : valueLabel]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-p-[valueLabel]-p-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: ["p": 5], views: ["valueLabel" : valueLabel]))
    }
    
    fileprivate func colorForType(_ value: String, key: String) -> UIColor {
        if let colorScheme = colorScheme {
            if let vDic = colorScheme[value], let s = vDic[key] {
                return UIColor.colorWithHex(s)
            } else {
                if let vDic = colorScheme["default"], let s = vDic[key] {
                    return UIColor.colorWithHex(s)
                }
            }
        }
        return UIColor.black
    }
}

extension UIColor {
    class func colorWithHex(_ hex: String) -> UIColor {
        var cString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("0X")) {
            cString = String(cString[cString.index(cString.startIndex, offsetBy: 2)..<cString.endIndex])
        }
        
        if (cString.count != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
