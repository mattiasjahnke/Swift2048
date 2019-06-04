//
//  GameViewController.swift
//  CloneA2048
//
//  Created by Mattias Jähnke on 2015-06-30.
//  Copyright © 2015 Nearedge. All rights reserved.
//

import UIKit

class GameViewController: UIViewController {
    let kBestScoreKey = "kBestScoreKey"
    let kPersistedModelKey = "kPersistedModelKey"
    let kPersistedModelScoreKey = "kPersistedModelScoreKey"
    
    @IBOutlet weak var board: GameBoardView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var bestLabel: UILabel!
    
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var autoRunButton: UIButton!
    
    fileprivate let game: Game2048
    fileprivate var bestScore = 0
    fileprivate var autoTimer: Timer?
    fileprivate var presentedMessages = [UIButton]()
    fileprivate var swipeStart: CGPoint?
    fileprivate var lastMove = 0  // TODO: Implement a more elegant solution
    
    required init?(coder aDecoder: NSCoder) {
        if let persisted = UserDefaults.standard.object(forKey: kPersistedModelKey) as? [Int] {
            game = Game2048(gameModel: persisted)
        } else {
            game = Game2048()
        }
        
        super.init(coder: aDecoder)
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        game.delegate = self
        
        board.size = game.boardSize
        board.updateValuesWithModel(game.model, canSpawn: true)

        if let score = UserDefaults.standard.object(forKey: "k2048CloneHighscore") as? Int {
            bestScore = score
        }
        
        updateScoreLabel()
    }
    
    @IBAction func toggleAutoRun(_ sender: AnyObject) {
        if let timer = autoTimer {
            timer.invalidate()
            autoTimer = nil
        } else {
            autoMove()
        }
    }
    
    @IBAction func resetGame(_ sender: AnyObject) {
        dismissMessages()
        game.reset()
    }
    
    fileprivate func updateScoreLabel() {
        if (game.score > bestScore) {
            bestScore = game.score
            UserDefaults.standard.set(bestScore, forKey: "k2048CloneHighscore")
            UserDefaults.standard.synchronize()
        }
        
        scoreLabel.attributedText = attributedText("Score", value: "\(game.score)")
        bestLabel.attributedText = attributedText("Best", value: "\(bestScore)")
    }
    
    fileprivate func attributedText(_ title: String, value: String) -> NSAttributedString {
        let res = NSMutableAttributedString(string: title, attributes: [
            .foregroundColor : UIColor(red: 238.0/255.0, green: 228.0/255.0, blue: 214.0/255.0, alpha: 1)
            ])
        res.append(NSAttributedString(string: "\n\(value)", attributes: [
            .foregroundColor : UIColor(white: 1, alpha: 1)
            ]))
        return res
    }
    
    @objc func newGameButtonTapped(_ sender: AnyObject) {
        resetGame(sender)
    }
    
    @objc func continuePlayingButtonTapped(_ sender: AnyObject) {
        dismissMessages()
    }
    
    @objc func autoMove() {
        if autoTimer == nil || autoTimer!.isValid == false {
            autoTimer = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(GameViewController.autoMove), userInfo: nil, repeats: true)
        }
        switch(arc4random_uniform(4)) {
        case 0: shortUp()
        case 1: shortDown()
        case 2: shortRight()
        case 3: shortLeft()
        default: break
        }
    }
    
    @objc func shortUp() { game.swipe(.y(.decrease)) }
    @objc func shortDown() { game.swipe(.y(.increase)) }
    @objc func shortLeft() { game.swipe(.x(.decrease)) }
    @objc func shortRight() { game.swipe(.x(.increase)) }
}

// MARK: Touch handling
extension GameViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            swipeStart = touch.location(in: view)
            lastMove = 0
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let swipeStart = swipeStart, let touch = touches.first else { return }
        
        let treshold: CGFloat = 250.0
        let loc = touch.location(in: view)
        let diff = CGPoint(x: loc.x - swipeStart.x, y: loc.y - swipeStart.y)
        
        func evaluateDirection(_ a: CGFloat, _ b: CGFloat, _ sensitivity: CGFloat) -> Bool {
            let delta = sensitivity * max(abs(b)/(abs(a)+abs(b)), 0.05)
            return sensitivity >= 0 ? a > delta : a < delta
        }
        
        if diff.x > 0 && evaluateDirection(diff.x, diff.y, treshold) && lastMove != 1 {
            shortRight()
            lastMove = 1
        } else if diff.x < 0 && evaluateDirection(diff.x, diff.y, -treshold) && lastMove != 2 {
            shortLeft()
            lastMove = 2
        } else if diff.y > 0 && evaluateDirection(diff.y, diff.x, treshold) && lastMove != 3 {
            shortDown()
            lastMove = 3
        } else if diff.y < 0 && evaluateDirection(diff.y, diff.x, -treshold) && lastMove != 4 {
            shortUp()
            lastMove = 4
        }
        
        self.swipeStart = loc
    }
}

// MARK: External keyboard handling
extension GameViewController {
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override var keyCommands : [UIKeyCommand]? {
        get {
            return [
                UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(GameViewController.shortUp)),
                UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(GameViewController.shortDown)),
                UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(GameViewController.shortLeft)),
                UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(GameViewController.shortRight)),
                UIKeyCommand(input: " ", modifierFlags: [], action: #selector(GameViewController.shortReset))]
        }
    }
    
    @objc func shortReset() { game.reset() }
}

extension GameViewController: Game2048Delegate {
    func game2048DidProcessMove(_ game: Game2048) {
        board.updateValuesWithModel(game.model, canSpawn: false)
        board.animateTiles()
        
        UserDefaults.standard.set(game.model, forKey: kPersistedModelKey)
        UserDefaults.standard.synchronize()
    }
    
    func game2048GameOver(_ game: Game2048) {
        self.displayMessage("Game over!",
                            subtitle: "Tap to try again",
                            action: #selector(GameViewController.newGameButtonTapped(_:)))
    }
    
    func game2048Reached2048(_ game: Game2048) {
        self.displayMessage("You win!",
                            subtitle: "Tap to continue playing",
                            action: #selector(GameViewController.continuePlayingButtonTapped(_:)))
    }
    
    func game2048ScoreChanged(_ game: Game2048, score: Int) {
        updateScoreLabel()
        if score > 0 {
            displayScoreChangeNotification("+ \(score)")
        }
    }
    
    func game2048TileMerged(_ game: Game2048, from: CGPoint, to: CGPoint) {
        board.moveAndRemoveTile(from: from.boardPosition, to: to.boardPosition)
    }
    
    func game2048TileSpawnedAtPoint(_ game: Game2048, point: CGPoint) {
        board.updateValuesWithModel(game.model, canSpawn: true)
    }
    
    func game2048TileMoved(_ game: Game2048, from: CGPoint, to: CGPoint) {
        board.moveTile(from: from.boardPosition, to: to.boardPosition)
    }
    
    func dismissMessages() {
        for message in presentedMessages {
            UIView.animate(withDuration: 0.1, animations: { 
                message.alpha = 0
                }, completion: { _ in
                    message.removeFromSuperview()
            })
        }
        presentedMessages.removeAll()
    }
    
    private func displayScoreChangeNotification(_ text: String) {
        let label = UILabel(frame: scoreLabel.frame)
        label.text = text
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.font = scoreLabel.font
        scoreLabel.superview!.addSubview(label)
        UIView.animate(withDuration: 0.8, animations: {
            label.alpha = 0
            var rect = label.frame
            rect.origin.y += 50
            label.frame = rect
            }, completion: { _ in
                label.removeFromSuperview()
        }) 
    }
    
    private func displayMessage(_ title: String, subtitle: String, action: Selector) {
        let messageButton = UIButton(type: .custom)
        
        presentedMessages.append(messageButton)
        
        messageButton.translatesAutoresizingMaskIntoConstraints = false
        messageButton.backgroundColor = UIColor(white: 1, alpha: 0.5)
        messageButton.titleLabel!.font = UIFont.boldSystemFont(ofSize: 36)
        messageButton.addTarget(self, action: action, for: .touchUpInside)
        
        let str = NSMutableAttributedString(string: "\(title)\n", attributes: [.font: UIFont.boldSystemFont(ofSize: 36)])
        str.append(NSAttributedString(string: subtitle, attributes: [
            .font : UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor : UIColor(white: 0, alpha: 0.3)
            ]))

        messageButton.setAttributedTitle(str, for: UIControl.State())
        messageButton.alpha = 0
        view.addSubview(messageButton)
        
        messageButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1).isActive = true
        messageButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1).isActive = true
        messageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        messageButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        UIView.animate(withDuration: 0.2) { messageButton.alpha = 1 }
        
        if autoTimer != nil {
            autoTimer!.invalidate()
            autoTimer = nil
        }
    }
}

extension CGPoint {
    var boardPosition: BoardPosition {
        return (x: Int(self.x), y: Int(self.y))
    }
}
