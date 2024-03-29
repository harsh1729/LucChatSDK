/*
 Copyright 2018 Lintel 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import "CircleButton.h"

@implementation CircleButton

- (instancetype)initWithImage:(UIImage *)image borderColor:(UIColor *)borderColor
{
    self = [[super class] buttonWithType:UIButtonTypeCustom];
    
    self.adjustsImageWhenDisabled = NO;
    self.adjustsImageWhenHighlighted = NO;
    
    self.layer.borderWidth = 1.0;
    self.layer.borderColor = borderColor.CGColor;
    
    self.defaultBackgroundColor = [UIColor whiteColor];
    self.highlightTintColor = [UIColor whiteColor];
    
    self.highlightBackgroundColor = borderColor;
    self.defaultTintColor = borderColor;
    self.tintColor = borderColor;
    
    [self setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    
    return self;
}

- (void)setDefaultBackgroundColor:(UIColor *)defaultBackgroundColor
{
    _defaultBackgroundColor = defaultBackgroundColor;
    self.backgroundColor = defaultBackgroundColor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.layer.cornerRadius = CGRectGetWidth(self.bounds) / 2.0;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self animateBackgroundColor:self.highlightBackgroundColor tintColor:self.highlightTintColor];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    [self animateBackgroundColor:self.defaultBackgroundColor tintColor:self.defaultTintColor];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    [self animateBackgroundColor:self.defaultBackgroundColor tintColor:self.defaultTintColor];
}

- (void)animateBackgroundColor:(UIColor *)color tintColor:(UIColor *)tintColor
{
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.backgroundColor = color;
                         self.tintColor = tintColor;
                     }
                     completion:nil];
}

@end
