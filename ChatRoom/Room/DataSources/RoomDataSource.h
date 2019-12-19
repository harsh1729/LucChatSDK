/*
 
 Copyright 2018 Lintel 

 

 
 */

#import <MatrixKit/MatrixKit.h>

#import "WidgetManager.h"

/**
 The data source for `RoomViewController` in Vector.
 */
@interface RoomDataSource : MXKRoomDataSource

/**
 The event id of the current selected event if any. Default is nil.
 */
@property(nonatomic) NSString *selectedEventId;

/**
 Tell whether the initial event of the timeline (if any) must be marked. Default is NO.
 */
@property(nonatomic) BOOL markTimelineInitialEvent;

/**
 Tell whether timestamp should be displayed on event selection. Default is YES.
 */
@property(nonatomic) BOOL showBubbleDateTimeOnSelection;

/**
 Check if there is an active jitsi widget in the room and return it.


/**
 Send a video to the room.
 Note: Move this method to MatrixKit when MatrixKit project will handle Swift module.
 
 While sending, a fake event will be echoed in the messages list.
 Once complete, this local echo will be replaced by the event saved by the homeserver.
 
 @param videoLocalURL the local filesystem path of the video to send.
 @param success A block object called when the operation succeeds. It returns
 the event id of the event generated on the homeserver
 @param failure A block object called when the operation fails.
 */
- (void)sendVideo:(NSURL*)videoLocalURL
          success:(void (^)(NSString *eventId))success
          failure:(void (^)(NSError *error))failure;

@end
