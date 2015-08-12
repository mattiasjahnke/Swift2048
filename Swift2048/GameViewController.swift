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
    
    let game: Game2048
    var bestScore = 0
    var autoTimer: NSTimer?
    var presentedMessages = [UIButton]()
    
    required init?(coder aDecoder: NSCoder) {
        if let persisted = NSUserDefaults.standardUserDefaults().objectForKey(kPersistedModelKey) as? [Int] {
            game = Game2048(gameModel: Matrix(grid: persisted))
        } else {
            game = Game2048()
        }
        
        super.init(coder: aDecoder)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        game.delegate = self
        
        board.size = game.boardSize
        board.updateValuesWithModel(game.model, canSpawn: true)
        
        addSwipeGestureRecognizer(.Left,  gameaction: "swipeLeft")
        addSwipeGestureRecognizer(.Right, gameaction: "swipeRight")
        addSwipeGestureRecognizer(.Up,    gameaction: "swipeUp")
        addSwipeGestureRecognizer(.Down,  gameaction: "swipeDown")
        
        if let score = NSUserDefaults.standardUserDefaults().objectForKey("k2048CloneHighscore") as? Int {
            bestScore = score
        }
        
        updateScoreLabel()
    }
    
    @IBAction func toggleAutoRun(sender: AnyObject) {
        if let timer = autoTimer {
            timer.invalidate()
            autoTimer = nil
        } else {
            autoMove()
        }
    }
    
    @IBAction func resetGame(sender: AnyObject) {
        dismissMessages()
        game.reset()
    }
    
    private func updateScoreLabel() {
        if (game.score > bestScore) {
            bestScore = game.score
            NSUserDefaults.standardUserDefaults().setObject(bestScore, forKey: "k2048CloneHighscore")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
        scoreLabel.attributedText = attributedText("Score", value: "\(game.score)")
        bestLabel.attributedText = attributedText("Best", value: "\(bestScore)")
    }
    
    private func attributedText(title: String, value: String) -> NSAttributedString {
        let res = NSMutableAttributedString(string: title, attributes: [NSForegroundColorAttributeName : UIColor(red: 238.0/255.0, green: 228.0/255.0, blue: 214.0/255.0, alpha: 1)])
        res.appendAttributedString(NSAttributedString(string: "\n\(value)", attributes: [NSForegroundColorAttributeName : UIColor(white: 1, alpha: 1)]))
        return res
    }
    
    private func addSwipeGestureRecognizer(direction: UISwipeGestureRecognizerDirection, gameaction: Selector) {
        let gesture = UISwipeGestureRecognizer(target: game, action: gameaction)
        gesture.direction = direction
        self.view.addGestureRecognizer(gesture)
    }
    
    func newGameButtonTapped(sender: AnyObject) {
        resetGame(sender)
    }
    
    func continuePlayingButtonTapped(sender: AnyObject) {
        dismissMessages()
    }
    
    func autoMove() {
        if autoTimer == nil || autoTimer!.valid == false {
            autoTimer = NSTimer.scheduledTimerWithTimeInterval(0.001, target: self, selector: "autoMove", userInfo: nil, repeats: true)
        }
        switch(arc4random_uniform(4)) {
        case 0:
            game.swipeDown()
        case 1:
            game.swipeLeft()
        case 2:
            game.swipeRight()
        case 3:
            game.swipeUp()
        default:
            break
        }
    }
}

extension GameViewController {
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override var keyCommands : [UIKeyCommand]? {
        get {
            return [
                UIKeyCommand(input: UIKeyInputUpArrow, modifierFlags: UIKeyModifierFlags(rawValue: 0), action: Selector("shortUp")),
                UIKeyCommand(input: UIKeyInputDownArrow, modifierFlags: UIKeyModifierFlags(rawValue: 0), action: Selector("shortDown")),
                UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags: UIKeyModifierFlags(rawValue: 0), action: Selector("shortLeft")),
                UIKeyCommand(input: UIKeyInputRightArrow, modifierFlags: UIKeyModifierFlags(rawValue: 0), action: Selector("shortRight")),
                UIKeyCommand(input: " ", modifierFlags: UIKeyModifierFlags(rawValue: 0), action: Selector("shortReset"))]
        }
    }
    
    func shortUp() { game.swipeUp() }
    func shortDown() { game.swipeDown() }
    func shortLeft() { game.swipeLeft() }
    func shortRight() { game.swipeRight() }
    func shortReset() { game.reset() }
}

extension GameViewController: Game2048Delegate {
    func game2048DidProcessMove(game: Game2048) {
        board.updateValuesWithModel(game.model, canSpawn: false)
        board.animateTiles()
        
        NSUserDefaults.standardUserDefaults().setObject(game.model.grid, forKey: kPersistedModelKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func game2048GameOver(game: Game2048) {
        self.displayMessage("Game over!", subtitle: "Tap to try again", action: "newGameButtonTapped:")
    }
    
    func game2048Reached2048(game: Game2048) {
        self.displayMessage("You win!", subtitle: "Tap to continue playing", action: "continuePlayingButtonTapped:")
    }
    
    func game2048ScoreChanged(game: Game2048, score: Int) {
        updateScoreLabel()
    }
    
    func game2048TileMerged(game: Game2048, from: CGPoint, to: CGPoint) {
        board.moveAndRemoveTileFromPosition(from, to: to)
    }
    
    func game2048TileSpawnedAtPoint(game: Game2048, point: CGPoint) {
        board.updateValuesWithModel(game.model, canSpawn: true)
    }
    
    func game2048TileMoved(game: Game2048, from: CGPoint, to: CGPoint) {
        board.moveTileFromPosition(from, to: to)
    }
    
    private func dismissMessages() {
        for message in presentedMessages {
            UIView.animateWithDuration(0.1, animations: { _ in
                message.alpha = 0
                }, completion: { _ in
                    message.removeFromSuperview()
            })
        }
        presentedMessages.removeAll()
    }
    
    private func displayMessage(title: String, subtitle: String, action: Selector) {
        let messageButton = UIButton(type: .Custom)
        
        presentedMessages.append(messageButton)
        
        messageButton.translatesAutoresizingMaskIntoConstraints = false
        messageButton.backgroundColor = UIColor(white: 1, alpha: 0.5)
        messageButton.titleLabel!.font = UIFont.boldSystemFontOfSize(36)
        messageButton.addTarget(self, action: action, forControlEvents: .TouchUpInside)
        
        let str = NSMutableAttributedString(string: "\(title)\n", attributes: [NSFontAttributeName : UIFont.boldSystemFontOfSize(36)])
        str.appendAttributedString(NSAttributedString(string: subtitle, attributes: [NSFontAttributeName : UIFont.boldSystemFontOfSize(16), NSForegroundColorAttributeName : UIColor(white: 0, alpha: 0.3)]))
        messageButton.setAttributedTitle(str, forState: .Normal)
        messageButton.alpha = 0
        view.addSubview(messageButton)
        
        view.addConstraint(NSLayoutConstraint(item: messageButton, attribute: .Width, relatedBy: .Equal, toItem: board, attribute: .Width, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: messageButton, attribute: .Height, relatedBy: .Equal, toItem: board, attribute: .Height, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: messageButton, attribute: .CenterX, relatedBy: .Equal, toItem: board, attribute: .CenterX, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: messageButton, attribute: .CenterY, relatedBy: .Equal, toItem: board, attribute: .CenterY, multiplier: 1, constant: 0))
        
        UIView.animateWithDuration(0.2, animations: { _ in
            messageButton.alpha = 1
        })
        
        if autoTimer != nil {
            autoTimer!.invalidate()
            autoTimer = nil
        }
    }
}
