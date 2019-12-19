/*
 Copyright 2018 Lintel 
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import "MXGroup+Luc.h"

#import "AvatarGenerator.h"

@implementation MXGroup (Riot)

- (void)setGroupAvatarImageIn:(MXKImageView*)mxkImageView matrixSession:(MXSession*)mxSession
{
    // Use the group display name to prepare the default avatar image.
    NSString *avatarDisplayName = self.profile.name;
    UIImage* avatarImage = [AvatarGenerator generateAvatarForMatrixItem:self.groupId withDisplayName:avatarDisplayName];
    
    if (self.profile.avatarUrl && mxSession)
    {
        mxkImageView.enableInMemoryCache = YES;
        
        [mxkImageView setImageURI:self.profile.avatarUrl
                         withType:nil
              andImageOrientation:UIImageOrientationUp
                    toFitViewSize:mxkImageView.frame.size
                       withMethod:MXThumbnailingMethodCrop
                     previewImage:avatarImage
                     mediaManager:mxSession.mediaManager];
    }
    else
    {
        mxkImageView.image = avatarImage;
    }
    
    mxkImageView.contentMode = UIViewContentModeScaleAspectFill;
}

@end
