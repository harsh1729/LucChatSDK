/*
 
 Copyright 2018 Lintel 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import "RoomAvatarTitleView.h"

#import "ThemeService.h"

#import "MXRoomSummary+Luc.h"

@implementation RoomAvatarTitleView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([self class])
                          bundle:[NSBundle bundleForClass:[self class]]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.superview)
    {
        if (@available(iOS 11.0, *))
        {
            // Force the title view layout by adding 2 new constraints on the UINavigationBarContentView instance.
            NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                             attribute:NSLayoutAttributeTop
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self.superview
                                                                             attribute:NSLayoutAttributeTop
                                                                            multiplier:1.0f
                                                                              constant:0.0f];
            NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                                 attribute:NSLayoutAttributeCenterX
                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                    toItem:self.superview
                                                                                 attribute:NSLayoutAttributeCenterX
                                                                                multiplier:1.0f
                                                                                  constant:0.0f];
            
            [NSLayoutConstraint activateConstraints:@[topConstraint, centerXConstraint]];
            
            // Do not crop the avatar
            self.superview.clipsToBounds = NO;
        }
        else
        {
            // Center horizontally the avatar into the navigation bar
            CGRect frame = self.superview.frame;
            UINavigationBar *navigationBar;
            UIView *superView = self;
            while (superView.superview)
            {
                if ([superView.superview isKindOfClass:[UINavigationBar class]])
                {
                    navigationBar = (UINavigationBar*)superView.superview;
                    break;
                }
                
                superView = superView.superview;
            }
            
            if (navigationBar)
            {
                CGSize navBarSize = navigationBar.frame.size;
                CGFloat superviewCenterX = frame.origin.x + (frame.size.width / 2);
                
                self.roomAvatarMaskCenterXConstraint.constant = (navBarSize.width / 2) - superviewCenterX;
            }
        }
    }
}

@end
