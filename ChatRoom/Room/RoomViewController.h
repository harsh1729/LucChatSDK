/*
 Copyright 2018 Lintel
 
 */

#import <MatrixKit/MatrixKit.h>

#import "RoomTitleView.h"

#import "RoomPreviewData.h"

#import "UIViewController+LucSearch.h"

@interface RoomViewController : MXKRoomViewController

// The expanded header
@property (weak, nonatomic) IBOutlet UIView *expandedHeaderContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *expandedHeaderContainerHeightConstraint;

// The preview header
@property (weak, nonatomic) IBOutlet UIView *previewHeaderContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewHeaderContainerHeightConstraint;

// The jump to last unread banner
@property (weak, nonatomic) IBOutlet UIView *jumpToLastUnreadBannerContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *jumpToLastUnreadBannerContainerTopConstraint;
@property (weak, nonatomic) IBOutlet UIButton *jumpToLastUnreadButton;
@property (weak, nonatomic) IBOutlet UILabel *jumpToLastUnreadLabel;
@property (weak, nonatomic) IBOutlet UIButton *resetReadMarkerButton;
@property (weak, nonatomic) IBOutlet UIView *jumpToLastUnreadBannerSeparatorView;

/**
 Force the display of the expanded header.
 The default value is NO: this expanded header is hidden on new instantiated RoomViewController object.
 
 When this property is YES, the expanded header is forced each time the view controller appears.
 */
@property (nonatomic) BOOL showExpandedHeader;

/**
 Preview data for a room invitation received by email, or a link to a room.
 */
@property (nonatomic, readonly) RoomPreviewData *roomPreviewData;

/**
 Tell whether a badge must be added next to the chevron (back button) showing number of unread rooms.
 YES by default.
 */
@property (nonatomic) BOOL showMissedDiscussionsBadge;

/**
 Display the preview of a room that is unknown for the user.

 This room can come from an email invitation link or a simple link to a room.

 @param roomPreviewData the data for the room preview.
 */
- (void)displayRoomPreview:(RoomPreviewData*)roomPreviewData;

/**
 Action used to handle some buttons.
 */
- (IBAction)onButtonPressed:(id)sender;

@end

