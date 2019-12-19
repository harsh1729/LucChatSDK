/*
 Copyright 2018 Lintel

 */

#import <MatrixKit/MatrixKit.h>

/**
 Define a `MXGroup` category at Riot level.
 */
@interface MXGroup (Riot)

/**
 Set the group avatar in the dedicated MXKImageView.
 The riot style implies to use in order :
 1 - the default avatar if there is one
 2 - the first letter of the group name.
 
 @param mxkImageView the destinated MXKImageView.
 @param mxSession the matrix session 
 */
- (void)setGroupAvatarImageIn:(MXKImageView*)mxkImageView matrixSession:(MXSession*)mxSession;

@end
