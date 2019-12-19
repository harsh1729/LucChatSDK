/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import <MatrixKit/MatrixKit.h>

#import "RoomPreviewData.h"
#import "RoomInputToolbarView.h"

// We add here a protocol to handle tap gesture in title view.
@class RoomTitleView;
@protocol RoomTitleViewTapGestureDelegate <NSObject>

/**
 Tells the delegate that a tap gesture has been recognized.
 
 @param titleView the room title view.
 @param tapGestureRecognizer the recognized gesture.
 */
- (void)roomTitleView:(RoomTitleView*)titleView recognizeTapGesture:(UITapGestureRecognizer*)tapGestureRecognizer;

@end

@interface RoomTitleView : MXKRoomTitleView <UIGestureRecognizerDelegate,MXKRoomInputToolbarViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *titleMask;
@property (weak, nonatomic) IBOutlet UIView *roomDetailsMask;
@property (weak, nonatomic) IBOutlet UIView *addParticipantMask;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *displayNameCenterXConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *roomDetailsIconImageView;

/**
 The room preview data may be used when mxRoom instance is not available
 */
@property (strong, nonatomic) RoomPreviewData *roomPreviewData;

/**
 The tap gesture delegate.
 */
@property (nonatomic) id<RoomTitleViewTapGestureDelegate> tapGestureDelegate;
@property (weak, nonatomic) IBOutlet UIButton *voiceCallButton;
@property (weak, nonatomic) IBOutlet UIButton *hangupCallButton;

@property (nonatomic, weak) id<MXKRoomInputToolbarViewDelegate> delegateInput;

/**
 The method used to handle the gesture recognized by a receiver.
 */
- (void)reportTapGesture:(UITapGestureRecognizer*)tapGestureRecognizer;

@end
