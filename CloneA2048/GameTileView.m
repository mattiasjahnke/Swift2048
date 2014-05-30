//
//  GameTile.m
//  CloneA2048
//
//  Created by Mattias Jähnke on 2014-05-26.
//  Copyright (c) 2014 Nearedge. All rights reserved.
//

#import "GameTileView.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@implementation GameTileView {
    UILabel *_valueLabel;
}

- (void)_sharedInit {
    self.alpha = 0;
    
    _valueLabel = [[UILabel alloc] initWithFrame:self.bounds];
    _valueLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _valueLabel.font = [UIFont boldSystemFontOfSize:36];
    _valueLabel.minimumScaleFactor = 0.4f;
    _valueLabel.adjustsFontSizeToFitWidth = YES;
    _valueLabel.textAlignment = NSTextAlignmentCenter;
    _valueLabel.clipsToBounds = YES;
    _valueLabel.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.2f];
    
    [self addSubview:_valueLabel];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    _valueLabel.layer.cornerRadius = cornerRadius;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    _valueLabel.frame = CGRectInset(self.bounds, 5, 5);
}

- (void)setValueHidden:(BOOL)valueHidden {
    _valueHidden = valueHidden;
    if (_valueHidden) {
        _valueLabel.text = @"";
    }
}

- (id)init {
    self = [super init];
    if (self) {
        [self _sharedInit];
    }
    return self;
}

- (void)setValue:(NSUInteger)value {
    _value = value;
    if (!_valueHidden)
        _valueLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)value];
    _valueLabel.backgroundColor = [self _tileColorForValue:@(value)];
    _valueLabel.textColor = [self _textColorForValue:@(value)];
}

- (UIColor *)_tileColorForValue:(NSNumber *)value {
    NSNumber *hex = @{@(2):@(0xEEE4DA),
                      @(4):@(0xEAE0C8),
                      @(8):@(0xF59563),
                      @(16):@(0x3399ff),
                      @(32):@(0xffa333),
                      @(64):@(0xcef030),
                      @(128):@(0xE8D8CE),
                      @(256):@(0x990303),
                      @(512):@(0x6BA5DE),
                      @(1024):@(0xDCAD60),
                      @(2048):@(0xB60022)}[value];
    return hex ? UIColorFromRGB([hex integerValue]) : UIColorFromRGB(0xF59563);
}

- (UIColor *)_textColorForValue:(NSNumber *)value {
    NSNumber *hex = @{@(2):@(0x776E64)}[value];
    return hex ? UIColorFromRGB([hex integerValue]) : UIColorFromRGB(0x776E64);
}

@end