/*
 Copyright 2018 Lintel 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import <Foundation/Foundation.h>

#import <MatrixSDK/MXSession.h>

@interface MXSession (Riot)

/**
 The current number of rooms with missed notifications, including the invites.
 */
- (NSUInteger)riot_missedDiscussionsCount;

@end
