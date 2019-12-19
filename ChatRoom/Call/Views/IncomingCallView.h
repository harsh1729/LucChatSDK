/*
 Copyright 2018 Lintel 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^IncomingCallViewAction)(void);
@class MXMediaManager;

@interface IncomingCallView : UIView

/**
 Size that is applied to displayed user avatar
 */
@property (class, readonly) CGSize callerAvatarSize;

/**
 Block which is performed on call answer action
 */
@property (nonatomic, nullable, copy) IncomingCallViewAction onAnswer;

/**
 Block which is performed on call reject
 */
@property (nonatomic, nullable, copy) IncomingCallViewAction onReject;

/**
 Contructors.
 
 @param mxcAvatarURI the Matrix Content URI of the caller avatar.
 @param mediaManager the media manager used to download this avatar if it is not cached yet.
 @param placeholderImage
 @param callerName
 @param callInfo
 */
- (instancetype)initWithCallerAvatar:(NSString *)mxcAvatarURI
                        mediaManager:(MXMediaManager *)mediaManager
                    placeholderImage:(UIImage *)placeholderImage
                          callerName:(NSString *)callerName
                            callInfo:(NSString *)callInfo;

@end

NS_ASSUME_NONNULL_END
