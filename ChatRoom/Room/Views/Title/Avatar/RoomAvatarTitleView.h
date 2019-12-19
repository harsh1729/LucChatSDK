/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import <MatrixKit/MatrixKit.h>

@interface RoomAvatarTitleView : MXKRoomTitleView

@property (weak, nonatomic) IBOutlet UIView *roomAvatarMask;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *roomAvatarMaskCenterXConstraint;

@end
