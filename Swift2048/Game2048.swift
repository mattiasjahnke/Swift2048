//
//  Game2048.swift
//  CloneA2048
//
//  Created by Mattias Jähnke on 2015-06-29.
//  Copyright © 2015 Nearedge. All rights reserved.
//

import UIKit

@objc protocol Game2048Delegate {
    // Game flow and rules
    optional func game2048ScoreChanged(game: Game2048, score: Int) // score is the delta
    optional func game2048GameOver(game: Game2048)
    optional func game2048Reached2048(game: Game2048)
    
    // Changes to the board
    optional func game2048TileSpawnedAtPoint(game: Game2048, point: CGPoint)
    optional func game2048TileMoved(game: Game2048, from: CGPoint, to: CGPoint)
    optional func game2048TileMerged(game: Game2048, from: CGPoint, to: CGPoint)
    optional func game2048DidProcessMove(game: Game2048)
}

class Game2048: NSObject {
    var delegate: Game2048Delegate?
    
    var model = Matrix(size: 4)
    var boardSize: Int {
        get {
            return model.size
        }
    }
    
    private var seen2048 = false
    private var totalMoves = 0
    private var _score = 0 {
        didSet {
            delegate?.game2048ScoreChanged?(self, score: _score - oldValue)
        }
    }
    var score: Int {
        get { return _score }
    }
    
    override init() {
        super.init()
        reset()
    }
    
    convenience init(gameModel: Matrix) {
        self.init()
        model = gameModel
        _score = model.gridSum
    }
    
    func reset() {
        totalMoves = 0
        resetBoardModel()
    }
    
    func swipeLeft() {
        process(.decrease, yCompareDirection: .none)
    }
    
    func swipeRight() {
        process(.increase, yCompareDirection: .none)
    }
    
    func swipeDown() {
        process(.none, yCompareDirection: .increase)
    }
    
    func swipeUp() {
        process(.none, yCompareDirection: .decrease)
    }
    
    private func process(xCompareDirection: Direction, yCompareDirection: Direction) {
        func startFromDirection(direction: Direction) -> Int {
            switch direction {
            case .none: return 0
            case .decrease: return 1
            case .increase: return model.size - 2
            }
        }
        
        var merges = [(y: Int, x: Int)]()
        var totalChanges = 0
        var changes = 0
        var accumulatedScore = 0
        
        repeat {
            changes = 0
            for var y = startFromDirection(yCompareDirection); y < model.size && y >= 0; y += yCompareDirection == .increase ? -1 : 1 {
                for var x = startFromDirection(xCompareDirection); x < model.size && x >= 0; x += xCompareDirection == .increase ? -1 : 1 {
                    if model[y, x] == 0 {
                        continue
                    }
                    let comparePosition = (y: y + yCompareDirection.rawValue, x: x + xCompareDirection.rawValue)
                    let compareValue = model[comparePosition.y, comparePosition.x]
                    if compareValue == 0 {
                        // Move
                        model[comparePosition.y, comparePosition.x] = model[y, x]
                        model[y, x] = 0
                        
                        delegate?.game2048TileMoved?(self, from: CGPoint(x: x, y: y), to: CGPoint(x: comparePosition.x, y: comparePosition.y))
                        
                        changes++
                    } else if compareValue == model[y, x] {
                        var merged = false
                        for (mY, mX) in merges {
                            if (mX == comparePosition.x && mY == comparePosition.y) || (x == mX && y == mY) {
                                merged = true
                                break
                            }
                        }
                        if merged {
                            continue
                        }
                        // Merge
                        model[comparePosition.y, comparePosition.x] = compareValue * 2
                        model[y, x] = 0
                        
                        merges.append(comparePosition)
                        
                        delegate?.game2048TileMerged?(self, from: CGPoint(x: x, y: y), to: CGPoint(x: comparePosition.x, y: comparePosition.y))
                        
                        if !seen2048 && model[comparePosition.y, comparePosition.x] == 2048 {
                            seen2048 = true
                            delegate?.game2048Reached2048?(self)
                        }
                        
                        accumulatedScore += compareValue * 2;
                        changes++
                    }
                }
            }
            totalChanges += changes
        } while(changes > 0)
        
        _score += accumulatedScore;
        
        if totalChanges > 0 {
            totalMoves++
            spawnRandom2or4()
        }
        
        delegate?.game2048DidProcessMove?(self)
        
        if model.placesWithValue(0).count <= 0 && !model.moveIsPossible {
            delegate?.game2048GameOver?(self)
        }
    }
    
    private func resetBoardModel() {
        _score = 0
        model = Matrix(size: 4)
        for _ in 0..<2 { spawnRandom2or4() }
    }
    
    private func spawnRandom2or4() {
        let space = model.placesWithValue(0).randomElement()
        assert(space != nil)
        guard let empty = space else { return }
        model[empty.y, empty.x] = (Int(arc4random_uniform(2)) + 1) * 2
        delegate?.game2048TileSpawnedAtPoint?(self, point: CGPoint(x: empty.x, y: empty.y))
    }
}

enum Direction: Int {
    case increase = 1
    case decrease = -1
    case none = 0
}

// 2048 matrix methods
extension Matrix {
    var moveIsPossible: Bool {
        get {
            var foundMove = false
            for y in 0..<size {
                for x in 0..<size {
                    let value = self[y, x]
                    if y > 0 && self[y - 1, x] == value {
                        foundMove = true
                    } else if x > 0 && self[y, x - 1] == value {
                        foundMove = true
                    } else if y < size - 1 && self[y + 1, x] == value {
                        foundMove = true
                    } else if x < size - 1 && self[y, x + 1] == value {
                        foundMove = true
                    }
                    
                    if foundMove {
                        break
                    }
                }
                if foundMove {
                    break
                }
            }
            return foundMove
        }
    }
}

extension Array {
    func randomElement() -> Element? {
        return self.count > 0 ? self[Int(arc4random_uniform(UInt32(self.count)))] : nil
    }
}

struct Matrix {
    let size: Int
    var grid: [Int]
    var gridSum: Int {
        get { return grid.reduce(0, combine: { $0 + max(0, $1) }) }
    }
    
    init(size: Int) {
        self.size = size
        grid = Array(count: size * size, repeatedValue: 0)
    }
    
    init(grid: [Int]) {
        self.size = Int(sqrt(Float(grid.count)))
        self.grid = grid
    }
    
    func placesWithValue(value: Int) -> [(y: Int, x: Int)] {
        var free = [(y: Int, x: Int)]()
        for y in 0..<self.size {
            for x in 0..<self.size {
                if self[y, x] == 0 {
                    free.append((y: y, x: x))
                }
            }
        }
        return free
    }
    
    func indexIsValidForRow(row: Int, column: Int) -> Bool {
        return row >= 0 && row < size && column >= 0 && column < size
    }
    
    func asciiRepresentation() -> String {
        var matrix = ""
        for y in 0..<size {
            var row = ""
            for x in 0..<size {
                if self[y, x] > 0 { row += "[ \(self[y, x])]" }
                if self[y, x] == 0 { row += "[  ]" }
            }
            matrix += row + "\n"
        }
        return matrix
    }
    
    subscript(row: Int, column: Int) -> Int {
        get {
            assert(indexIsValidForRow(row, column: column), "Index out of range")
            return grid[(row * size) + column]
        }
        set {
            assert(indexIsValidForRow(row, column: column), "Index out of range")
            grid[(row * size) + column] = newValue
        }
    }
}
