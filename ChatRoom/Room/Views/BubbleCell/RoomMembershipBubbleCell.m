/*
 Copyright 2018 Lintel 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import "RoomMembershipBubbleCell.h"

#import "ThemeService.h"
#import "LucChatSDK-Swift.h"

#import "RoomBubbleCellData.h"

@interface RoomMembershipBubbleCell ()
{
    CGFloat xibPictureViewTopConstraintConstant;
}
@end

@implementation RoomMembershipBubbleCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    // Get original xib values
    xibPictureViewTopConstraintConstant = self.pictureViewTopConstraint.constant;
}

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.messageTextView.tintColor = ThemeService.shared.theme.tintColor;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    if (self.pictureViewTopConstraint.constant != xibPictureViewTopConstraintConstant)
    {
        self.pictureViewTopConstraint.constant = xibPictureViewTopConstraintConstant;
    }
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];

    RoomBubbleCellData *data = (RoomBubbleCellData*)cellData;

    // If the text was moved down (selected cell or last event), do the same for the icon
    if ((data.containsLastMessage || data.selectedComponentIndex != NSNotFound)
        && [data.attributedTextMessage.string hasPrefix:@"\n"])
    {
        self.pictureViewTopConstraint.constant = xibPictureViewTopConstraintConstant + 14;
    }
}

@end
