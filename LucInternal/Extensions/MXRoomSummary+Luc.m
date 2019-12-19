/*
 Copyright 2018 Lintel 
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import "MXRoomSummary+Luc.h"

#import "AvatarGenerator.h"

@implementation MXRoomSummary (Riot)

- (void)setRoomAvatarImageIn:(MXKImageView*)mxkImageView
{
    // Use the room display name to prepare the default avatar image.
    NSString *avatarDisplayName = self.displayname;
    UIImage* avatarImage = [AvatarGenerator generateAvatarForMatrixItem:self.roomId withDisplayName:avatarDisplayName];
    
    if (self.avatar)
    {
        mxkImageView.enableInMemoryCache = YES;
        
        [mxkImageView setImageURI:self.avatar
                         withType:nil
              andImageOrientation:UIImageOrientationUp
                    toFitViewSize:mxkImageView.frame.size
                       withMethod:MXThumbnailingMethodCrop
                     previewImage:avatarImage
                     mediaManager:self.mxSession.mediaManager];
    }
    else
    {
        mxkImageView.image = avatarImage;
    }
    
    mxkImageView.contentMode = UIViewContentModeScaleAspectFill;
}

@end
