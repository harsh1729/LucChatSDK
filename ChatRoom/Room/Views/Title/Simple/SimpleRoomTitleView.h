/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import <MatrixKit/MatrixKit.h>

/**
 This title view display the room display name only.
 There is no user interaction in it except the back button.
 */
@interface SimpleRoomTitleView : MXKRoomTitleView <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *displayNameCenterXConstraint;

@end
