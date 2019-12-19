/*
 Copyright 2018 Lintel 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import "RoomMembershipExpandedBubbleCell.h"

#import "ThemeService.h"
#import "LucChatSDK-Swift.h"

#import "RoomBubbleCellData.h"

NSString *const kRoomMembershipExpandedBubbleCellTapOnCollapseButton = @"kRoomMembershipExpandedBubbleCellTapOnCollapseButton";

@implementation RoomMembershipExpandedBubbleCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    NSString* title = NSLocalizedStringFromTableInBundle(@"collapse", @"Vector",[NSBundle bundleForClass:[self class]], nil);
    [self.collapseButton setTitle:title forState:UIControlStateNormal];
    [self.collapseButton setTitle:title forState:UIControlStateHighlighted];
}

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.separatorView.backgroundColor = ThemeService.shared.theme.lineBreakColor;
    
    [self.collapseButton setTintColor:ThemeService.shared.theme.tintColor];
    self.collapseButton.titleLabel.font = [UIFont systemFontOfSize:14];
}

- (IBAction)onCollapseButtonTap:(id)sender
{
    if (self.delegate)
    {
        [self.delegate cell:self didRecognizeAction:kRoomMembershipExpandedBubbleCellTapOnCollapseButton userInfo:nil];
    }
}

@end
