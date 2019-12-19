/*
 Copyright 2018 Lintel 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import "RoomEmptyBubbleCell.h"

@implementation RoomEmptyBubbleCell

- (void)prepareForReuse
{
    [super prepareForReuse];

    if (self.heightConstraint != 0)
    {
        self.heightConstraint = 0;
    }
}

@end
