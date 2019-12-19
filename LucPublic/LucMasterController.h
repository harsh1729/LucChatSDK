/*
 Copyright 2018 Lintel 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import <MatrixKit/MatrixKit.h>

#import "RoomViewController.h"
#import "LucNavigationController.h"

#import "RecentsDataSource.h"

@interface LucMasterController : MXKRecentListViewController


// Add a matrix session. This session is propagated to all view controllers handled by the tab bar controller.
- (void)addMatrixSession:(MXSession*)mxSession;
// Remove a matrix session.
- (void)removeMatrixSession:(MXSession*)mxSession;


/**
 Open the room with the provided identifier in a specific matrix session.
 
 @param roomId the room identifier.
 @param eventId if not nil, the room will be opened on this event.
 @param mxSession the matrix session in which the room should be available.
 */
- (void)selectRoomWithId:(NSString*)roomId andEventId:(NSString*)eventId inMatrixSession:(MXSession*)mxSession;

/**
 Open the room with the provided identifier in a specific matrix session.
 
 @param roomId the room identifier.
 @param eventId if not nil, the room will be opened on this event.
 @param mxSession the matrix session in which the room should be available.
 @param completion the block to execute at the end of the operation.
 */
- (void)selectRoomWithId:(NSString*)roomId andEventId:(NSString*)eventId inMatrixSession:(MXSession*)matrixSession completion:(void (^)(void))completion;

/**
 Open the RoomViewController to display the preview of a room that is unknown for the user.
 
 This room can come from an email invitation link or a simple link to a room.
 
 @param roomPreviewData the data for the room preview.
 */
//- (void)showRoomPreview:(RoomPreviewData*)roomPreviewData;




/**
 Release the current selected item (if any).
 */
- (void)releaseSelectedItem;


/**
 The current number of rooms with missed notifications, including the invites.
 */
- (NSUInteger)missedDiscussionsCount;

/**
 The current number of rooms with unread highlighted messages.
 */
- (NSUInteger)missedHighlightDiscussionsCount;


// References on the currently selected room and its view controller
@property (nonatomic, readonly) RoomViewController *currentRoomViewController;
@property (nonatomic, readonly) NSString  *selectedRoomId;
@property (nonatomic, readonly) NSString  *selectedEventId;
@property (nonatomic, readonly) MXSession *selectedRoomSession;
@property (nonatomic, readonly) MXKRoomDataSource *selectedRoomDataSource;
@property (nonatomic, readonly) RoomPreviewData *selectedRoomPreviewData;
// The recents data source shared between all the view controllers of the tab bar.
@property (nonatomic, readonly) RecentsDataSource *recentsDataSource;

@property (nonatomic, readonly) MXKContact *selectedContact;


@end

