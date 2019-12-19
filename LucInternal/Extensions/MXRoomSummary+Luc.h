/*
 Copyright 2018 Lintel 

 

 
 */

#import <MatrixKit/MatrixKit.h>

/**
 Define a `MXRoomSummary` category at Riot level.
 */
@interface MXRoomSummary (Riot)

/**
 Set the room avatar in the dedicated MXKImageView.
 The riot style implies to use in order :
 1 - the default avatar if there is one
 2 - the member avatar for < 3 members rooms
 3 - the first letter of the room name.
 
 @param mxkImageView the destinated MXKImageView.
 */
- (void)setRoomAvatarImageIn:(MXKImageView*)mxkImageView;

@end
