/*
 
 Copyright 2018 Lintel 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import "RoomTableViewCell.h"

#import "ThemeService.h"
#import "LucChatSDK-Swift.h"

#import "MXRoomSummary+Luc.h"

#pragma mark - Defines & Constants

static const CGFloat kDirectRoomBorderColorAlpha = 0.75;
static const CGFloat kDirectRoomBorderWidth = 3.0;

@implementation RoomTableViewCell

#pragma mark - Class methods

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.titleLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    
    // Prepare direct room border
    CGColorRef directRoomBorderColor = CGColorCreateCopyWithAlpha(ThemeService.shared.theme.tintColor.CGColor, kDirectRoomBorderColorAlpha);
    
    [self.directRoomBorderView.layer setCornerRadius:self.directRoomBorderView.frame.size.width / 2];
    self.directRoomBorderView.clipsToBounds = YES;
    self.directRoomBorderView.layer.borderColor = directRoomBorderColor;
    self.directRoomBorderView.layer.borderWidth = kDirectRoomBorderWidth;
    
    CFRelease(directRoomBorderColor);
    
    self.avatarImageView.defaultBackgroundColor = [UIColor clearColor];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Round image view
    [self.avatarImageView.layer setCornerRadius:self.avatarImageView.frame.size.width / 2];
    self.avatarImageView.clipsToBounds = YES;
}

- (void)render:(MXRoom *)room
{
    [room.summary setRoomAvatarImageIn:self.avatarImageView];
    
    self.titleLabel.text = room.summary.displayname;
    
    self.directRoomBorderView.hidden = !room.isDirect;
    
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.directRoomBorderView.hidden = YES;
    self.encryptedRoomIcon.hidden = YES;
}

+ (CGFloat)cellHeight
{
    return 74;
}

@end
