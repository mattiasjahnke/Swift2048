//
//  GameTile.h
//  CloneA2048
//
//  Created by Mattias Jähnke on 2014-05-26.
//  Copyright (c) 2014 Nearedge. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GameTileView : UIView

@property (nonatomic, assign) BOOL destory;
@property (nonatomic, assign) CGPoint position;
@property (nonatomic, assign) NSUInteger value;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) BOOL valueHidden;
@property (nonatomic, strong) NSDictionary *colorScheme;

@end