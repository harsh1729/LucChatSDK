/*
 
 Copyright 2018 Lintel 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import "RoomTitleView.h"

#import "ThemeService.h"
#import "LucChatSDK-Swift.h"

@interface RoomTitleView()
{
    // The intermediate action sheet
    UIAlertController *actionSheet;
}

@end

@implementation RoomTitleView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([RoomTitleView class])
                          bundle:[NSBundle bundleForClass:[RoomTitleView class]]];
}

- (void)dealloc
{
    _roomPreviewData = nil;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    //HARSH : Do not add gesture at this point in time
    
//    if (_titleMask)
//    {
//        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reportTapGesture:)];
//        [tap setNumberOfTouchesRequired:1];
//        [tap setNumberOfTapsRequired:1];
//        [tap setDelegate:self];
//        [self.titleMask addGestureRecognizer:tap];
//        self.titleMask.userInteractionEnabled = YES;
//    }
//
//    if (_roomDetailsMask)
//    {
//        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reportTapGesture:)];
//        [tap setNumberOfTouchesRequired:1];
//        [tap setNumberOfTapsRequired:1];
//        [tap setDelegate:self];
//        [self.roomDetailsMask addGestureRecognizer:tap];
//        self.roomDetailsMask.userInteractionEnabled = YES;
//    }
//
//    if (_addParticipantMask)
//    {
//        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reportTapGesture:)];
//        [tap setNumberOfTouchesRequired:1];
//        [tap setNumberOfTapsRequired:1];
//        [tap setDelegate:self];
//        [self.addParticipantMask addGestureRecognizer:tap];
//        self.addParticipantMask.userInteractionEnabled = YES;
//    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.roomDetailsIconImageView.image = [MXKTools paintImage:self.roomDetailsIconImageView.image
                                                     withColor:ThemeService.shared.theme.tintColor];
    
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
            
        }
        else
        {
            // Center horizontally the display name into the navigation bar
            CGRect frame = self.superview.frame;
            
            // Look for the navigation bar.
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
                
                // Check whether the view is not moving away (see navigation between view controllers).
                if (superviewCenterX < navBarSize.width)
                {
                    // Center the display name
                    self.displayNameCenterXConstraint.constant = (navBarSize.width / 2) - superviewCenterX;
                }
            }  
        }
    }
}

-(void)customizeViewRendering
{
    [super customizeViewRendering];

    self.backgroundColor = UIColor.clearColor;
    self.displayNameTextField.textColor = (self.mxRoom.summary.displayname.length ? ThemeService.shared.theme.baseTextPrimaryColor : ThemeService.shared.theme.textSecondaryColor);
}

- (void)setRoomPreviewData:(RoomPreviewData *)roomPreviewData
{
    _roomPreviewData = roomPreviewData;
    
    [self refreshDisplay];
}

- (void)refreshDisplay
{
    [super refreshDisplay];
    
    // Consider in priority the preview data (if any)
    if (self.roomPreviewData)
    {
        self.displayNameTextField.text = self.roomPreviewData.roomName;
    }
    else if (self.mxRoom)
    {
        self.displayNameTextField.text = self.mxRoom.summary.displayname;
        if (!self.displayNameTextField.text.length)
        {
            self.displayNameTextField.text = [NSBundle mxk_localizedStringForKey:@"room_displayname_empty_room"];
            self.displayNameTextField.textColor = ThemeService.shared.theme.textSecondaryColor;
        }
        else
        {
            self.displayNameTextField.textColor = ThemeService.shared.theme.baseTextPrimaryColor;
        }
    }
}

- (void)destroy
{
    self.tapGestureDelegate = nil;
    
    [super destroy];
}

- (void)reportTapGesture:(UITapGestureRecognizer*)tapGestureRecognizer
{
    if (self.tapGestureDelegate)
    {
        [self.tapGestureDelegate roomTitleView:self recognizeTapGesture:tapGestureRecognizer];
    }
}

//Toch action for call button
- (IBAction)onTouchUpInside:(UIButton*)button
{
    self.delegateInput = self.delegate;
    
    if (button == self.voiceCallButton)
    {
        if ([self.delegateInput respondsToSelector:@selector(roomInputToolbarView:placeCallWithVideo:)])
        {
            
            // Ask the user the kind of the call: voice or video?
            actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
            
            __weak typeof(self) weakSelf = self;
            [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"voice", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                              if (weakSelf)
                                                              {
                                                                  typeof(self) self = weakSelf;
                                                                  self->actionSheet = nil;
                                                                  
                                                                  [self.delegateInput roomInputToolbarView:nil placeCallWithVideo:NO];
                                                              }
                                                              
                                                          }]];
            
            [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"video", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                              if (weakSelf)
                                                              {
                                                                  typeof(self) self = weakSelf;
                                                                  self->actionSheet = nil;
                                                                  
                                                                  [self.delegateInput roomInputToolbarView:nil placeCallWithVideo:YES];
                                                              }
                                                              
                                                          }]];
            
            [actionSheet addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                              if (weakSelf)
                                                              {
                                                                  typeof(self) self = weakSelf;
                                                                  self->actionSheet = nil;
                                                              }
                                                              
                                                          }]];
            
            [actionSheet popoverPresentationController].sourceView = self.voiceCallButton;
            [actionSheet popoverPresentationController].sourceRect = self.voiceCallButton.bounds;
            [self.window.rootViewController presentViewController:actionSheet animated:YES completion:nil];
        }
    }
    else if (button == self.hangupCallButton)
    {
        
        if ([self.delegateInput respondsToSelector:@selector(roomInputToolbarViewHangupCall:)])
        {
            [self.delegateInput roomInputToolbarViewHangupCall:nil];
        }
    }
    
    //[super onTouchUpInside:button];
}

- (void)setActiveCall:(BOOL)activeCall
{
//    if (_activeCall != activeCall)
//    {
//        _activeCall = activeCall;
//
//        self.voiceCallButton.hidden = (_activeCall || !self.rightInputToolbarButton.hidden);
//        self.hangupCallButton.hidden = (!_activeCall || !self.rightInputToolbarButton.hidden);
//    }
    
    NSLog(@"setActiveCall");
}


@end
