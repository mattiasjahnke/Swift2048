//
//  GameBoard.h
//  CloneA2048
//
//  Created by Mattias Jähnke on 2014-05-26.
//  Copyright (c) 2014 Nearedge. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GameTileView;

@interface GameBoardView : UIView

@property (nonatomic, assign) NSUInteger size;

// *** Tile control
- (GameTileView *)spawnTileAtPosition:(CGPoint)position;
- (void)moveTileAtPosition:(CGPoint)fromPosition toPosition:(CGPoint)toPosition;
- (void)moveAndRemoveTileAtPosition:(CGPoint)fromPosition toPosition:(CGPoint)toPosition;
- (void)animateTiles;

// Canspawn is a boolean indicating if we allow the gameboard to spawn a new tile at
// a position if that position is empty (useful to set the board state)
- (void)updateValuesWithValueArray:(NSArray *)valueArray canSpawn:(BOOL)canSpawn;

@end