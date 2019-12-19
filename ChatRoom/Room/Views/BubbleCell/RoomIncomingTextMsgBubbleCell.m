/*
 
 Copyright 2018 Lintel 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import "RoomIncomingTextMsgBubbleCell.h"

#import "ThemeService.h"
#import "LucChatSDK-Swift.h"
#import "MXKRoomBubbleTableViewCell+Luc.h"

@implementation RoomIncomingTextMsgBubbleCell

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    [self updateUserNameColor];
    
    self.messageTextView.tintColor = ThemeService.shared.theme.tintColor;
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];
    
    [self updateUserNameColor];
}

@end
