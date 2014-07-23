//
//  GameTile.m
//  CloneA2048
//
//  Created by Mattias Jähnke on 2014-05-26.
//  Copyright (c) 2014 Nearedge. All rights reserved.
//

#import "GameTileView.h"

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
    
    NSString *stringValue = value <= 2048 ? [NSString stringWithFormat:@"%d", value] : @"super";
    _valueLabel.backgroundColor = [self _colorForValue:stringValue forKey:@"background"];
    _valueLabel.textColor = [self _colorForValue:stringValue forKey:@"text"];
}

- (UIColor *)_colorForValue:(NSString *)value forKey:(NSString *)key {
    unsigned result = 0;
    if (_colorScheme[value][key]) {
        NSScanner *scanner = [NSScanner scannerWithString:_colorScheme[value][key]];
        [scanner scanHexInt:&result];
    } else {
        NSScanner *scanner = [NSScanner scannerWithString:_colorScheme[@"default"][key]];
        [scanner scanHexInt:&result];
    }
    return UIColorFromRGB(result);
}

@end