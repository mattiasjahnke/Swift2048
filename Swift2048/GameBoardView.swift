//
//  GameBoardView.swift
//  CloneA2048
//
//  Created by Mattias Jähnke on 2015-06-30.
//  Copyright © 2015 Nearedge. All rights reserved.
//

import UIKit

class GameBoardView: UIView {
    
    let contentInset: CGFloat = 10
    var size = 4 {
        didSet {
            updatePlaceholderLayers()
        }
    }
    var tiles = [GameTileView]()
    var placeholderLayers = [CALayer]()
    var colorScheme: [String : [String : String]] = {
        let data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("default-color", ofType: "json")!)!
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as! [String : [String : String]]
            return json
        } catch {
            return [String : [String : String]]()
        }
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updatePlaceholderLayers()
        animateTiles()
    }
    
    func spawnTileAtPosition(position: CGPoint) -> GameTileView {
        let tile = GameTileView(frame: frameForPosition(position))
        tiles.append(tile)
        addSubview(tile)
        tile.colorScheme = colorScheme
        tile.position = position
        tile.cornerRadius = 5
        tile.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.1, 0.1), CGAffineTransformMakeRotation(3.14))
        
        UIView.animateWithDuration(0.3) { _ in
            tile.alpha = 1
            tile.transform = CGAffineTransformIdentity
        }
        
        return tile
    }
    
    func moveTileFromPosition(from: CGPoint, to: CGPoint) {
        tileAtPosition(from)?.position = to
    }
    
    func moveAndRemoveTileFromPosition(from: CGPoint, to: CGPoint) {
        if let tile = tileAtPosition(from), toTile = tileAtPosition(to) {
            tile.destroy = true
            moveTileFromPosition(from, to: to)
            UIView.animateWithDuration(0.1, animations: { _ in
                toTile.transform = CGAffineTransformMakeScale(1.2, 1.2)
                }, completion: { _ in
                    UIView.animateWithDuration(0.1, animations: { _ in
                        toTile.transform = CGAffineTransformIdentity
                    })
            })
        }
    }
    
    func animateTiles() {
        var destroyed = [GameTileView]()
        for tile in tiles {
            UIView.animateWithDuration(0.1, animations: { _ in
                let dest = self.frameForPosition(tile.position)
                tile.bounds = CGRect(x: 0, y: 0, width: dest.width, height: dest.height)
                tile.layer.position = CGPoint(x: dest.origin.x + dest.width / 2, y: dest.origin.y + dest.height / 2)
                tile.alpha = tile.destroy ? 0 : 1
                }, completion: { _ in
                    if tile.destroy {
                        tile.removeFromSuperview()
                        destroyed.append(tile)
                    }
            })
        }
        tiles = tiles.filter({ tile -> Bool in
            return !destroyed.contains(tile)
        })
    }
    
    func updateValuesWithModel(model: Matrix, canSpawn: Bool) {
        for y in 0..<model.size {
            for x in 0..<model.size {
                var tile = tileAtPosition(CGPoint(x: x, y: y))
                if canSpawn && model[y, x] > 0 && tile == nil {
                    tile = spawnTileAtPosition(CGPoint(x: x, y: y))
                }
                if canSpawn && model[y, x] == 0 && tile != nil {
                    tiles.removeAtIndex(tiles.indexOf(tile!)!)
                    tile!.removeFromSuperview()
                }
                assert(!(tile == nil && model[y, x] > 0))
                if let tile = tile {
                    tile.value = model[y, x]
                }
            }
        }
    }
    
    private func updatePlaceholderLayers() {
        while placeholderLayers.count != size * size {
            if placeholderLayers.count < size * size {
                placeholderLayers.append(CALayer())
                layer.addSublayer(placeholderLayers.last!)
            } else {
                placeholderLayers.last!.removeFromSuperlayer()
                placeholderLayers.removeLast()
            }
        }
        
        for y in 0..<size {
            for x in 0..<size {
                let layer = placeholderLayers[size * x + y]
                layer.backgroundColor = UIColor(red: 204.0/255.0, green: 192.0/255.0, blue: 181.0/255.0, alpha: 1).CGColor
                layer.cornerRadius = 5
                layer.anchorPoint = CGPoint(x: 0, y: 0)
                let rect = CGRectInset(frameForPosition(CGPoint(x: x, y: y)), 5, 5)
                layer.position = rect.origin
                layer.bounds = rect
            }
        }
    }
    
    private func tileAtPosition(position: CGPoint) -> GameTileView? {
        for tile in tiles {
            if CGPointEqualToPoint(position, tile.position) && !tile.destroy {
                return tile
            }
        }
        return nil
    }
    
    private func frameForPosition(position: CGPoint) -> CGRect {
        let minSize = min(frame.size.width, frame.size.height) - contentInset * 2
        let s = round(minSize / CGFloat(size))
        return CGRect(x: position.x * s + contentInset, y: position.y * s + contentInset, width: s, height: s)
    }
    
}
