/*
 

 

 
 */

#import <MatrixKit/MatrixKit.h>

// Custom tags for MXKRoomBubbleCellDataStoring.tag
typedef NS_ENUM(NSInteger, RoomBubbleCellDataTag)
{
    RoomBubbleCellDataTagMessage = 0, // Default value used for messages
    RoomBubbleCellDataTagMembership,
    RoomBubbleCellDataTagRoomCreateWithPredecessor
};

/**
 `RoomBubbleCellData` defines Vector bubble cell data model.
 */
@interface RoomBubbleCellData : MXKRoomBubbleCellDataWithAppendingMode

/**
 A Boolean value that determines whether this bubble contains the current last message.
 Used to keep displaying the timestamp of the last message.
 */
@property(nonatomic) BOOL containsLastMessage;

/**
 Indicate true to display the timestamp of the selected component.
 */
@property(nonatomic) BOOL showTimestampForSelectedComponent;

/**
 Indicate true to display the timestamp of the selected component on the left if possible (YES by default).
 */
@property(nonatomic) BOOL displayTimestampForSelectedComponentOnLeftWhenPossible;

/**
 The event id of the current selected event inside the bubble. Default is nil.
 */
@property(nonatomic) NSString *selectedEventId;

/**
 The index of the oldest component (component with a timestamp, and an actual display). NSNotFound by default.
 */
@property(nonatomic, readonly) NSInteger oldestComponentIndex;

/**
 The index of the most recent component (component with a timestamp, and an actual display). NSNotFound by default.
 */
@property(nonatomic, readonly) NSInteger mostRecentComponentIndex;

/**
 The index of the current selected component. NSNotFound by default.
 */
@property(nonatomic, readonly) NSInteger selectedComponentIndex;

/**
 Return additional content height (read receipts, reactions).
 */
@property(nonatomic, readonly) CGFloat additionalContentHeight;

/**
 Indicate to update additional content height.
 */
- (void)setNeedsUpdateAdditionalContentHeight;

/**
 Update additional content height if needed.
 */
- (void)updateAdditionalContentHeightIfNeeded;

/**
 The index of the first visible component. NSNotFound by default.
 */
- (NSInteger)firstVisibleComponentIndex;

#pragma mark - Show all reactions

- (BOOL)showAllReactionsForEvent:(NSString*)eventId;
- (void)setShowAllReactions:(BOOL)showAllReactions forEvent:(NSString*)eventId;

@end
