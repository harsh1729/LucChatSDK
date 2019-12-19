/*
 
 Copyright 2018 Lintel 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import "RecentCellData.h"

#import "MXRoom+Luc.h"

@implementation RecentCellData
// trick to hide the mother class property as it is readonly one.
// self.roomDisplayname returns this value instead of the mother class.
@synthesize roomDisplayname;

- (NSString*)notificationCountStringValue
{
    NSString *stringValue;
    NSUInteger notificationCount = self.notificationCount;
    
    if (notificationCount > 1000)
    {
        CGFloat value = notificationCount / 1000.0;
        stringValue = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"large_badge_value_k_format", @"Vector",[NSBundle bundleForClass:[self class]], nil), value];
    }
    else
    {
        stringValue = [NSString stringWithFormat:@"%tu", notificationCount];
    }
    
    return stringValue;
}

- (NSUInteger)notificationCount
{
    // Ignore the regular notification count if the room is in 'mentions only" mode at the Riot level.
    if (self.roomSummary.room.isMentionsOnly)
    {
        // Only the highlighted missed messages must be considered here.
        return self.roomSummary.highlightCount;
    }
    
    return self.roomSummary.notificationCount;
}

- (void)update
{
    [super update];
    roomDisplayname = self.roomSummary.displayname;
    if (!roomDisplayname.length)
    {
        roomDisplayname = [NSBundle mxk_localizedStringForKey:@"room_displayname_empty_room"];
    }
}

@end
