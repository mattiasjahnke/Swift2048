//
//  ViewController.m
//  CloneA2048
//
//  Created by Mattias Jähnke on 2014-05-26.
//  Copyright (c) 2014 Nearedge. All rights reserved.
//

#import "ViewController.h"
#import "Json2048.h"
#import "GameBoardView.h"
#import "GameTileView.h"

@interface ViewController ()<Json2048Delegate>
@property (nonatomic, weak) IBOutlet GameBoardView *board;

@property (weak, nonatomic) IBOutlet UIButton *autoRunButton;
@property (nonatomic, weak) IBOutlet UIButton *resetButton;
@property (nonatomic, weak) IBOutlet UILabel *scoreLabel;
@property (nonatomic, weak) IBOutlet UILabel *bestLabel;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@end

static int kGameOverlayLabelTag = 12;
static int kGameOverlayButtonTag = 13;

@implementation ViewController {
    Json2048 *_game;
    NSUInteger _bestScore;
    NSTimer *_testTimer;
    
    UIView *_messageOverlayView;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - View life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _scoreLabel.layer.cornerRadius = 5;
    _bestLabel.layer.cornerRadius = 5;
    _titleLabel.layer.cornerRadius = 5;
    _autoRunButton.layer.cornerRadius = 5;
    _board.layer.cornerRadius = 5;
    _resetButton.layer.cornerRadius =5;
    
    NSNumber *lastGameScore = [[NSUserDefaults standardUserDefaults] objectForKey:@"k2048CurrentScore"];
    
	_game = [[Json2048 alloc] initWithJson:[[NSUserDefaults standardUserDefaults] objectForKey:@"k2048CloneJson"] score:lastGameScore ? [lastGameScore unsignedIntegerValue] : 0];
    _game = [[Json2048 alloc] initWithJson:@[[@[@0,@0,@0,@0] mutableCopy],
                                            [@[@1024,@0,@0,@0] mutableCopy],
                                            [@[@0,@0,@0,@0] mutableCopy],
                                             [@[@1024,@0,@0,@0] mutableCopy]] score:0];
    
    _board.size = [_game.json.firstObject count];
    
    [_board updateValuesWithValueArray:_game.json canSpawn:YES];
    
    _game.delegate = self;

    [self _addSwipeInDirection:UISwipeGestureRecognizerDirectionDown gameAction:@selector(swipeDown)];
    [self _addSwipeInDirection:UISwipeGestureRecognizerDirectionRight gameAction:@selector(swipeRight)];
    [self _addSwipeInDirection:UISwipeGestureRecognizerDirectionUp gameAction:@selector(swipeUp)];
    [self _addSwipeInDirection:UISwipeGestureRecognizerDirectionLeft gameAction:@selector(swipeLeft)];
    
    _bestScore = [[[NSUserDefaults standardUserDefaults] objectForKey:@"k2048CloneHighscore"] unsignedIntegerValue];
    [self _updateScoreLabel];
}

#pragma mark - User interaction

- (void)newGameButtonTapped:(id)sender {
    [self _removeOverlay];
    [self resetGame:sender];
    if (_testTimer) {
        [self _autoMove];
    }
}

- (void)continuePlayingButtonTapped:(id)sender {
    [self _removeOverlay];
}

- (IBAction)resetGame:(id)sender {
    [_game reset];
    [self _removeOverlay];
}

- (IBAction)toggleAuto:(id)sender {
    if (_testTimer) {
        [_testTimer invalidate];
        _testTimer = nil;
    } else {
        [self _autoMove];
    }
}

#pragma mark - Json2048 Delegation

- (void)json2048:(Json2048 *)json2048 spawnedAtPos:(CGPoint)pos {
    [_board updateValuesWithValueArray:_game.json canSpawn:YES];
    [self _saveGameState];
}

- (void)json2048GameOver:(Json2048 *)json2048 {
    [self _displayMessageWithText:@"Game over!\nTap to try again" tapSelector:@selector(newGameButtonTapped:)];
}

- (void)json2048Reached2048:(Json2048 *)json2048 {
    [self _displayMessageWithText:@"You won!\nTap to continue playing" tapSelector:@selector(continuePlayingButtonTapped:)];
}

- (void)_displayMessageWithText:(NSString *)text tapSelector:(SEL)selector {
    if (!_messageOverlayView) {
        _messageOverlayView = [[UIView alloc] initWithFrame:_board.frame];
        _messageOverlayView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5f];
        UILabel *gameOverLabel = [[UILabel alloc] initWithFrame:_messageOverlayView.bounds];
        gameOverLabel.tag = kGameOverlayLabelTag;
        gameOverLabel.textAlignment = NSTextAlignmentCenter;
        gameOverLabel.font = [UIFont boldSystemFontOfSize:30];
        gameOverLabel.numberOfLines = 2;
        [_messageOverlayView addSubview:gameOverLabel];
    }
    
    if ([_messageOverlayView viewWithTag:kGameOverlayButtonTag]) {
        [[_messageOverlayView viewWithTag:kGameOverlayButtonTag] removeFromSuperview];
    }
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    button.tag = kGameOverlayButtonTag;
    button.frame = _messageOverlayView.bounds;
    [_messageOverlayView addSubview:button];
    
    if (!_messageOverlayView.superview) {
        [self.view addSubview:_messageOverlayView];
        _messageOverlayView.alpha = 0;
        
        [UIView animateWithDuration:0.2f animations:^{
            _messageOverlayView.alpha = 1;
        }];
    }
    
    ((UILabel *)[_messageOverlayView viewWithTag:kGameOverlayLabelTag]).text = text;
    
    if (_testTimer) {
        [_testTimer invalidate];
        /*dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
         [self newGameButtonTapped:newGameButton];
         });*/
    }
}

- (void)_removeOverlay {
    [UIView animateWithDuration:0.1f animations:^{
        _messageOverlayView.alpha = 0;
    } completion:^(BOOL finished) {
        [_messageOverlayView removeFromSuperview];
    }];
}

- (void)json2048:(Json2048 *)json2048 didChangeScore:(NSUInteger)score {
    [self _updateScoreLabel];
}

#pragma mark Handle Json2048 moves to allow UI animation

- (void)json2048:(Json2048 *)json2048 didMovePos:(CGPoint)fromPos toPos:(CGPoint)toPos {
    [_board moveTileAtPosition:fromPos toPosition:toPos];
}

- (void)json2048:(Json2048 *)json2048 didMergeFromPos:(CGPoint)fromPos AtPos:(CGPoint)atPos {
    [_board moveAndRemoveTileAtPosition:fromPos toPosition:atPos];
}

- (void)json2048DidMove:(Json2048 *)json2048 {
    [_board updateValuesWithValueArray:_game.json canSpawn:NO];
    [_board animateTiles];
}

#pragma mark - Internal

- (void)_addSwipeInDirection:(UISwipeGestureRecognizerDirection)direction gameAction:(SEL)action {
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:_game action:action];
    swipe.direction = direction;
    [self.view addGestureRecognizer:swipe];
}

- (void)_updateScoreLabel {
    if (_game.score > _bestScore) {
        _bestScore = _game.score;
        [[NSUserDefaults standardUserDefaults] setObject:@(_bestScore) forKey:@"k2048CloneHighscore"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [self _styleAttributedTextInLabel:_scoreLabel title:@"Score" value:[NSString stringWithFormat:@"%lu",(unsigned long)_game.score]];
    [self _styleAttributedTextInLabel:_bestLabel title:@"Best" value:[NSString stringWithFormat:@"%lu", (unsigned long)_bestScore]];
}

- (void)_styleAttributedTextInLabel:(UILabel *)label title:(NSString *)title value:(NSString *)value {
    NSMutableAttributedString *res = [[NSMutableAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:238/255.0f green:228/255.0f blue:214/255.0f alpha:1]}];
    [res appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@", value] attributes:@{NSForegroundColorAttributeName : [UIColor colorWithWhite:1 alpha:1]}]];
    label.attributedText = res;
}

- (void)_saveGameState {
    [[NSUserDefaults standardUserDefaults] setObject:_game.json forKey:@"k2048CloneJson"];
    [[NSUserDefaults standardUserDefaults] setObject:@(_game.score) forKey:@"k2048CurrentScore"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -

- (void)_autoMove {
    if (!_testTimer || !_testTimer.isValid) {
        _testTimer = [NSTimer scheduledTimerWithTimeInterval:0.001f target:self selector:@selector(_autoMove) userInfo:nil repeats:YES];
    }
    int a = arc4random() % 4;
    switch (a) {
        case 0:
            [_game swipeDown];
            break;
        case 1:
            [_game swipeLeft];
            break;
        case 2:
            [_game swipeRight];
            break;
        case 3:
            [_game swipeUp];
            break;
        default:
            break;
    }
}

@end
