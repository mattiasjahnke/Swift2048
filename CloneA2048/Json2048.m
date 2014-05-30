//
//  Json2048.m
//  CloneA2048
//
//  Created by Mattias Jähnke on 2014-05-26.
//  Copyright (c) 2014 Nearedge. All rights reserved.
//

#import "Json2048.h"

#define GRID_SIZE 4

typedef BOOL(^ConditionBlock)(NSInteger var);

@implementation Json2048 {
    NSMutableArray *_json;
    NSUInteger _score;
    NSUInteger _totalMoves;
    
    BOOL _gameIsDead;
}

#pragma mark - Init

- (id)initWithJson:(NSArray *)array score:(NSUInteger)score {
    self = [self init];
    if (self) {
        if (array && ([self _freeSpacesInArray:array].count || [self _movePossibleInArray:array])) {
            _json = [array mutableCopy];
            _score = score;
        }
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) { [self reset]; }
    return self;
}

- (void)setDelegate:(id<Json2048Delegate>)delegate {
    _delegate = delegate;
}

#pragma mark - Public methods

- (void)swipeDown {
    [self _processWithNextIDiff:1 nextJDiff:0 iStart:GRID_SIZE - 2 jStart:0 iConditionBlock:^BOOL(NSInteger var) { return var >= 0; } jConditionBlock:^BOOL(NSInteger var) { return var < GRID_SIZE; } iIncrement:-1 jIncrement:1];
}

- (void)swipeUp {
    [self _processWithNextIDiff:-1 nextJDiff:0 iStart:1 jStart:0 iConditionBlock:^BOOL(NSInteger var) { return var < GRID_SIZE; } jConditionBlock:^BOOL(NSInteger var) {
        return var < GRID_SIZE; } iIncrement:1 jIncrement:1];
}

- (void)swipeRight {
    [self _processWithNextIDiff:0 nextJDiff:1 iStart:0 jStart:GRID_SIZE - 2 iConditionBlock:^BOOL(NSInteger var) { return var < GRID_SIZE; } jConditionBlock:^BOOL(NSInteger var) { return var >= 0; } iIncrement:1 jIncrement:-1];
}

- (void)swipeLeft {
    [self _processWithNextIDiff:0 nextJDiff:-1 iStart:0 jStart:1 iConditionBlock:^BOOL(NSInteger var) { return var < GRID_SIZE; } jConditionBlock:^BOOL(NSInteger var) { return var < GRID_SIZE; } iIncrement:1 jIncrement:1];
}

- (void)reset {
    _score = 0;
    _totalMoves = 0;
    
    [self _resetBoardModel];
    
    if ([_delegate respondsToSelector:@selector(json2048:didChangeScore:)]) {
        [_delegate json2048:self didChangeScore:_score];
    }
}

- (NSArray *)json {
    return _json;
}

- (NSUInteger)freeSpaces {
    return [self _freeSpacesInArray:_json].count;
}

- (NSUInteger)score {
    return _score;
}

#pragma mark - Internal

- (void)_insert2or4AtRandomPosition {
    [self _insertNumberAtRandomPosition:@((arc4random() % 2 + 1) * 2)];
}

- (void)_processWithNextIDiff:(int)nextIDiff nextJDiff:(int)nextJDiff iStart:(int)iStart jStart:(int)jStart iConditionBlock:(ConditionBlock)iCondBlock jConditionBlock:(ConditionBlock)jCondBlock iIncrement:(int)iIncrement jIncrement:(int)jIncrement {
    
    NSMutableArray *merges = [NSMutableArray array];
    
    NSUInteger totalChanges = 0;
    NSUInteger changes = 0;
    do {
        changes = 0;
        for (int i = iStart; iCondBlock(i); i += iIncrement) {
            for (int j = jStart; jCondBlock(j); j += jIncrement) {
                
                NSUInteger tileValue = [_json[i][j] unsignedIntegerValue];
                if (tileValue == 0)
                    continue;
                
                NSUInteger nextTileValue = [_json[i + nextIDiff][j + nextJDiff] unsignedIntegerValue];
                
                if (nextTileValue == 0) {
                    // Move
                    _json[i + nextIDiff][j + nextJDiff] = _json[i][j];
                    _json[i][j] = @(0);
                    if ([_delegate respondsToSelector:@selector(json2048:didMovePos:toPos:)]) {
                        [_delegate json2048:self didMovePos:CGPointMake(i, j) toPos:CGPointMake(i + nextIDiff, j + nextJDiff)];
                    }
                    changes++;
                } else if (nextTileValue == tileValue) {
                    // Make sure the nextTitleValue isn't a previously merged tile
                    BOOL merged = NO;
                    for (NSArray *merge in merges) {
                        if (([merge[0] unsignedIntegerValue] == i + nextIDiff && [merge[1] unsignedIntegerValue] == j + nextJDiff ) || ([merge[0] unsignedIntegerValue] == i && [merge[1] unsignedIntegerValue] == j)) {
                            merged = YES;
                            break;
                        }
                    }
                    if (merged)
                        continue;
                    
                    // Merge
                    _json[i][j] = @0;
                    _json[i + nextIDiff][j + nextJDiff] = @(nextTileValue * 2);
                    
                    [merges addObject:@[@(i + nextIDiff), @(j + nextJDiff)]];
                    
                    if ([_delegate respondsToSelector:@selector(json2048:didMergeFromPos:AtPos:)]) {
                        [_delegate json2048:self didMergeFromPos:CGPointMake(i, j) AtPos:CGPointMake(i + nextIDiff, j + nextJDiff)];
                    }
                    
                    _score += nextTileValue * 2;
                    if ([_delegate respondsToSelector:@selector(json2048:didChangeScore:)]) {
                        [_delegate json2048:self didChangeScore:_score];
                    }
                    changes++;
                } // Else -> Stuck
            }
        }
        totalChanges += changes;
    } while (changes > 0);
    
    // Did move?
    if (totalChanges > 0) {
        _totalMoves++;
        [self _insert2or4AtRandomPosition];
    }

    if ([_delegate respondsToSelector:@selector(json2048DidMove:)]) {
        [_delegate json2048DidMove:self];
    }
    
    // Check for game over
    if (self.freeSpaces <= 0) {
        if (![self _movePossibleInArray:_json]) {
            if ([_delegate respondsToSelector:@selector(json2048GameOver:)]) {
                [_delegate json2048GameOver:self];
            }
        }
    }
}

- (BOOL)_movePossibleInArray:(NSArray *)array {
    BOOL foundMove = NO;
    for (int i = 0; i < GRID_SIZE; i++) {
        for (int j = 0; j < GRID_SIZE; j++) {
            NSUInteger v = [array[i][j] unsignedIntegerValue];
            if (i > 0 && [array[i - 1][j] unsignedIntegerValue] == v) {
                foundMove = YES;
            } else if (j > 0 && [array[i][j - 1] unsignedIntegerValue] == v) {
                foundMove = YES;
            } else if (i < GRID_SIZE - 1 && [array[i + 1][j] unsignedIntegerValue] == v) {
                foundMove = YES;
            } else if (j < GRID_SIZE - 1 && [array[i][j + 1] unsignedIntegerValue] == v) {
                foundMove = YES;
            }
            
            if (foundMove)
                break;
        }
        if (foundMove)
            break;
    }
    return foundMove;
}

- (void)_resetBoardModel {
    _json = [[NSMutableArray alloc] init];
    for (int i = 0; i < GRID_SIZE; i++) {
        NSMutableArray *rowArray = [NSMutableArray array];
        for (int j = 0; j < GRID_SIZE; j++) {
            [rowArray addObject:@(0)];
        }
        [_json addObject:rowArray];
    }
    
    [self _insert2or4AtRandomPosition];
    [self _insert2or4AtRandomPosition];
}

- (NSArray *)_freeSpacesInArray:(NSArray *)array {
    NSMutableArray *workingArray = [NSMutableArray array];
    for (int i = 0; i < GRID_SIZE; i++) {
        for (int j = 0; j < GRID_SIZE; j++) {
            if ([array[i][j] unsignedIntegerValue] == 0) {
                [workingArray addObject:@[@(i), @(j)]];
            }
        }
    }
    return workingArray;
}

- (void)_insertNumberAtRandomPosition:(NSNumber *)number {
    NSArray *freeSpaces = [self _freeSpacesInArray:_json];
    assert(freeSpaces.count > 0);
    NSArray *pos = freeSpaces[(int)arc4random() % freeSpaces.count];
    _json[[pos[0] integerValue]][[pos[1] integerValue]] = number;
    if ([_delegate respondsToSelector:@selector(json2048:spawnedAtPos:)]) {
        [_delegate json2048:self spawnedAtPos:CGPointMake([pos[0] integerValue], [pos[1] integerValue])];
    }
}

#pragma mark -

- (NSString *)description {
    NSMutableString *s = [NSMutableString string];
    [s appendFormat:@"GRID: \n"];
    for (int i = 0; i < GRID_SIZE; i++) {
        for (int j = 0; j < GRID_SIZE; j++) {
            [s appendFormat:@"%d ", [_json[i][j] integerValue]];
        }
        [s appendFormat:@"\n"];
    }
    return s;
}

@end
