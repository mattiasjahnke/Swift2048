//
//  GameBoard.m
//  CloneA2048
//
//  Created by Mattias Jähnke on 2014-05-26.
//  Copyright (c) 2014 Nearedge. All rights reserved.
//

#import "GameBoardView.h"
#import "GameTileView.h"

#define CONTENT_INSET 10
#define TILE_CORNER_RADIUS 5

@implementation GameBoardView {
    NSMutableArray *_tiles, *_placeholderLayers;
    NSDictionary *_colorScheme;
}

#pragma mark - Init

- (void)_sharedInit {
    _tiles = [NSMutableArray array];
    _placeholderLayers = [NSMutableArray array];

    _colorScheme = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"default-color" ofType:@"json"]] options:0 error:nil];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _sharedInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _sharedInit];
    }
    return self;
}

#pragma mark - Public

- (void)setSize:(NSUInteger)size {
    _size = size;
    [self _updatePlaceholderLayers];
}

- (GameTileView *)spawnTileAtPosition:(CGPoint)position {
    GameTileView *tile = [GameTileView new];
    [_tiles addObject:tile];
    [self addSubview:_tiles.lastObject];
    
    tile.colorScheme = _colorScheme;
    tile.position = position;
    tile.cornerRadius = TILE_CORNER_RADIUS;
    tile.frame = [self _frameForPosition:position];
    tile.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.1, 0.1f), CGAffineTransformMakeRotation(3.14));
    
    [UIView animateWithDuration:0.3f animations:^{
        ((GameTileView*)_tiles.lastObject).alpha = 1;
        ((GameTileView*)_tiles.lastObject).transform = CGAffineTransformIdentity;
    }];
    
    return tile;
}

- (void)moveTileAtPosition:(CGPoint)fromPosition toPosition:(CGPoint)toPosition {
    [self _tileAtPosition:fromPosition].position = toPosition;
}

- (void)moveAndRemoveTileAtPosition:(CGPoint)fromPosition toPosition:(CGPoint)toPosition {
    GameTileView *tile = [self _tileAtPosition:fromPosition];
    GameTileView *toTile = [self _tileAtPosition:toPosition];
    tile.destory = YES;
    [self moveTileAtPosition:fromPosition toPosition:toPosition];
    
    // "Pop" the merged tile
    assert(toTile);
    [UIView animateWithDuration:.1f animations:^{
        toTile.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:.1f animations:^{
            toTile.transform = CGAffineTransformIdentity;
        }];
    }];
   
}

- (void)animateTiles {
    NSMutableArray *destroyed = [NSMutableArray array];
    for (GameTileView *tile in _tiles) {
        [UIView animateWithDuration:0.1f animations:^{
            CGRect dest = [self _frameForPosition:tile.position];
            tile.bounds = CGRectMake(0,0,dest.size.width, dest.size.height);
            tile.layer.position = CGPointMake(dest.origin.x + tile.bounds.size.width / 2, dest.origin.y + tile.bounds.size.height / 2);
            if (tile.destory) {
                tile.alpha = 0;
            }
        } completion:^(BOOL finished) {
            if (tile.destory) {
                [tile removeFromSuperview];
                [_tiles removeObject:tile];
                [destroyed addObject:tile];
            }
        }];
    }
    [_tiles removeObjectsInArray:destroyed];
}

- (void)updateValuesWithValueArray:(NSArray *)valueArray canSpawn:(BOOL)canSpawn {
    for (int i = 0; i < valueArray.count; i++) {
        for (int j = 0; j < [valueArray[i] count]; j++) {
            GameTileView *tile = [self _tileAtPosition:CGPointMake(i, j)];
            if (canSpawn && [valueArray[i][j] unsignedIntegerValue] > 0 && !tile) {
                tile = [self spawnTileAtPosition:CGPointMake(i, j)];
            }
            if (canSpawn && [valueArray[i][j] unsignedIntegerValue] == 0 && tile) {
                [_tiles removeObject:tile];
                [tile removeFromSuperview];
            }
            assert(!(tile == nil && [valueArray[i][j] unsignedIntegerValue] > 0));
            [tile setValue:[valueArray[i][j] unsignedIntegerValue]];
        }
    }
}

#pragma mark - Internal

- (void)layoutSubviews {
    [super layoutSubviews];
    [self _updatePlaceholderLayers];
    [self animateTiles];
}

- (CGRect)_frameForPosition:(CGPoint)position {
    CGFloat min = MIN(self.frame.size.width, self.frame.size.height) - CONTENT_INSET * 2;
    CGFloat s = roundf(min / _size);
    return CGRectMake(position.y * s + CONTENT_INSET, position.x * s + CONTENT_INSET, s, s);
}

- (GameTileView *)_tileAtPosition:(CGPoint)position {
    for (GameTileView *tile in _tiles) {
        if (CGPointEqualToPoint(position, tile.position) && !tile.destory) {
            return tile;
        }
    }
    return nil;
}

- (void)_updatePlaceholderLayers {
    while (_placeholderLayers.count != _size * _size) {
        if (_placeholderLayers.count < _size * _size) {
            [_placeholderLayers addObject:[CALayer new]];
            [self.layer addSublayer:_placeholderLayers.lastObject];
        } else {
            [_placeholderLayers.lastObject removeFromSuperlayer];
            [_placeholderLayers removeLastObject];
        }
    }
    for (int i = 0; i < _size; i++) {
        for (int j = 0; j < _size; j++) {
            CALayer *layer = (CALayer*)_placeholderLayers[_size * j + i];
            layer.backgroundColor = [UIColor colorWithRed:204/255.0f green:192/255.0f blue:181/255.0f alpha:1].CGColor;
            layer.cornerRadius = TILE_CORNER_RADIUS;
            layer.anchorPoint = CGPointMake(0, 0);
            CGRect f = CGRectInset([self _frameForPosition:CGPointMake(i, j)], 5, 5);
            layer.position = f.origin;
            layer.bounds = f;
        }
    }
}

@end