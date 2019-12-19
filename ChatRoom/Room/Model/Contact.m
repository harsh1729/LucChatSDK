/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import "Contact.h"

#import "AvatarGenerator.h"

@implementation Contact

- (UIImage*)thumbnailWithPreferedSize:(CGSize)size
{
    UIImage* thumbnail = nil;
    
    // replace the identicon icon by the Vector style one
    if (_mxMember && ([_mxMember.avatarUrl rangeOfString:@"identicon"].location != NSNotFound))
    {        
        thumbnail = [AvatarGenerator generateAvatarForMatrixItem:_mxMember.userId withDisplayName:_mxMember.displayname];
    }
    else
    {
        thumbnail = [super thumbnailWithPreferedSize:size];
    }
    
    // ensure that the thumbnail will have a vector style.
    if (!thumbnail)
    {
        thumbnail = [AvatarGenerator generateAvatarForText:self.displayName];
    }
    
    return thumbnail;
}

@end
