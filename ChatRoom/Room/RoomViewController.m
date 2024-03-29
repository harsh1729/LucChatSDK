/*
 Copyright 2018 Lintel
 */

#import "RoomViewController.h"

#import "RoomDataSource.h"
#import "RoomBubbleCellData.h"

#import "RoomInputToolbarView.h"
#import "DisabledRoomInputToolbarView.h"

#import "RoomActivitiesView.h"

#import "AttachmentsViewController.h"

#import "EventDetailsView.h"

#import "RoomAvatarTitleView.h"
#import "ExpandedRoomTitleView.h"
#import "SimpleRoomTitleView.h"
#import "PreviewRoomTitleView.h"

#import "SegmentedViewController.h"

#import "RoomSearchViewController.h"

#import "ReadReceiptsViewController.h"


#import "RoomEmptyBubbleCell.h"

#import "RoomIncomingTextMsgBubbleCell.h"
#import "RoomIncomingTextMsgWithoutSenderInfoBubbleCell.h"
#import "RoomIncomingTextMsgWithPaginationTitleBubbleCell.h"
#import "RoomIncomingTextMsgWithoutSenderNameBubbleCell.h"
#import "RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.h"
#import "RoomIncomingAttachmentBubbleCell.h"
#import "RoomIncomingAttachmentWithoutSenderInfoBubbleCell.h"
#import "RoomIncomingAttachmentWithPaginationTitleBubbleCell.h"


#import "RoomOutgoingTextMsgBubbleCell.h"
#import "RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.h"
#import "RoomOutgoingTextMsgWithPaginationTitleBubbleCell.h"
#import "RoomOutgoingTextMsgWithoutSenderNameBubbleCell.h"
#import "RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.h"
#import "RoomOutgoingAttachmentBubbleCell.h"
#import "RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.h"
#import "RoomOutgoingAttachmentWithPaginationTitleBubbleCell.h"


#import "RoomMembershipBubbleCell.h"
#import "RoomMembershipWithPaginationTitleBubbleCell.h"
#import "RoomMembershipCollapsedBubbleCell.h"
#import "RoomMembershipCollapsedWithPaginationTitleBubbleCell.h"
#import "RoomMembershipExpandedBubbleCell.h"
#import "RoomMembershipExpandedWithPaginationTitleBubbleCell.h"

#import "RoomSelectedStickerBubbleCell.h"
#import "RoomPredecessorBubbleCell.h"

#import "MXKRoomBubbleTableViewCell+Luc.h"

#import "AvatarGenerator.h"
#import "Tools.h"
#import "WidgetManager.h"

#import "GBDeviceInfo_iOS.h"


#import "MXRoom+Luc.h"

#import "EventFormatter.h"
#import <MatrixKit/MXKSlashCommands.h>

#import "LucChatSDK-Swift.h"
#import "LucUtility.h"
#import "ThemeService.h"

@interface RoomViewController () <UISearchBarDelegate, UIGestureRecognizerDelegate, RoomTitleViewTapGestureDelegate, MXServerNoticesDelegate, RoomContextualMenuViewControllerDelegate,
    ReactionsMenuViewModelCoordinatorDelegate, MXKDocumentPickerPresenterDelegate, EmojiPickerCoordinatorBridgePresenterDelegate, CameraPresenterDelegate, MediaPickerCoordinatorBridgePresenterDelegate>
{
    // The expanded header
    ExpandedRoomTitleView *expandedHeader;
    
    // The preview header
    PreviewRoomTitleView *previewHeader;
    
    // The customized room data source for Vector
    RoomDataSource *customizedRoomDataSource;
    
    // The user taps on a member thumbnail
    MXRoomMember *selectedRoomMember;
    
    // The user taps on a user id contained in a message
    MXKContact *selectedContact;
    
    // List of members who are typing in the room.
    NSArray *currentTypingUsers;
    
    // Typing notifications listener.
    id typingNotifListener;
    
    // The first tab is selected by default in room details screen
    // Use this flag to select a specific tab (0: people, 1: files, 2: settings).
    NSUInteger selectedRoomDetailsIndex;
    
    
    // The position of the first touch down event stored in case of scrolling when the expanded header is visible.
    CGPoint startScrollingPoint;
    
    // Missed discussions badge
    NSUInteger missedDiscussionsCount;
    NSUInteger missedHighlightCount;
    UIBarButtonItem *missedDiscussionsButton;
    UILabel *missedDiscussionsBadgeLabel;
    UIView  *missedDiscussionsBadgeLabelBgView;
    UIView  *missedDiscussionsBarButtonCustomView;
    
    
    // The list of unknown devices that prevent outgoing messages from being sent
    MXUsersDevicesMap<MXDeviceInfo*> *unknownDevices;
    
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    id kAppDelegateDidTapStatusBarNotificationObserver;
    
    // Observe kAppDelegateNetworkStatusDidChangeNotification to handle network status change.
    id kAppDelegateNetworkStatusDidChangeNotificationObserver;

    // Observers to manage MXSession state (and sync errors)
    id kMXSessionStateDidChangeObserver;

    // Observers to manage ongoing conference call banner
    id kMXCallStateDidChangeObserver;
    id kMXCallManagerConferenceStartedObserver;
    id kMXCallManagerConferenceFinishedObserver;

    // Observers to manage widgets
    id kMXKWidgetManagerDidUpdateWidgetObserver;
    
    // Observer kMXRoomSummaryDidChangeNotification to keep updated the missed discussion count
    id mxRoomSummaryDidChangeObserver;

    // Observer for removing the re-request explanation/waiting dialog
    id mxEventDidDecryptNotificationObserver;
    
    // The table view cell in which the read marker is displayed (nil by default).
    MXKRoomBubbleTableViewCell *readMarkerTableViewCell;
    
    // Tell whether the view controller is appeared or not.
    BOOL isAppeared;
    
    // The right bar button items back up.
    NSArray<UIBarButtonItem *> *rightBarButtonItems;

    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;
    
    // Listener for `m.room.tombstone` event type
    id tombstoneEventNotificationsListener;

    // Homeserver notices
    MXServerNotices *serverNotices;
}

@property (nonatomic, weak) IBOutlet UIView *overlayContainerView;


@property (nonatomic, strong) RoomContextualMenuViewController *roomContextualMenuViewController;
@property (nonatomic, strong) RoomContextualMenuPresenter *roomContextualMenuPresenter;
@property (nonatomic, strong) MXKErrorAlertPresentation *errorPresenter;
@property (nonatomic, strong) NSString *textMessageBeforeEditing;
@property (nonatomic, strong) EditHistoryCoordinatorBridgePresenter *editHistoryPresenter;
@property (nonatomic, strong) MXKDocumentPickerPresenter *documentPickerPresenter;
@property (nonatomic, strong) EmojiPickerCoordinatorBridgePresenter *emojiPickerCoordinatorBridgePresenter;

@property (nonatomic, strong) CameraPresenter *cameraPresenter;
@property (nonatomic, strong) MediaPickerCoordinatorBridgePresenter *mediaPickerPresenter;

@end

@implementation RoomViewController
@synthesize roomPreviewData;

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self.class)
                          bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)roomViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass(self.class)
                                          bundle:[NSBundle bundleForClass:self.class]];
}

#pragma mark -

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Disable auto join
        self.autoJoinInvitedRoom = NO;
        
        // Disable auto scroll to bottom on keyboard presentation
        self.scrollHistoryToTheBottomOnKeyboardPresentation = NO;
    }
    
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        // Disable auto join
        self.autoJoinInvitedRoom = NO;
        
        // Disable auto scroll to bottom on keyboard presentation
        self.scrollHistoryToTheBottomOnKeyboardPresentation = NO;
    }
    
    return self;
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    
    _showExpandedHeader = NO;
    _showMissedDiscussionsBadge = YES;
    
    
    // Listen to the event sent state changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventDidChangeIdentifier:) name:kMXEventDidChangeIdentifierNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Register first customized cell view classes used to render bubbles
    [self.bubblesTableView registerClass:RoomIncomingTextMsgBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingTextMsgWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingTextMsgWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingAttachmentBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingAttachmentWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingAttachmentWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingTextMsgWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    
    
    
    [self.bubblesTableView registerClass:RoomOutgoingAttachmentBubbleCell.class forCellReuseIdentifier:RoomOutgoingAttachmentBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingAttachmentWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomOutgoingAttachmentWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    
    
    
    [self.bubblesTableView registerClass:RoomEmptyBubbleCell.class forCellReuseIdentifier:RoomEmptyBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:RoomMembershipBubbleCell.class forCellReuseIdentifier:RoomMembershipBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomMembershipWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomMembershipWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomMembershipCollapsedBubbleCell.class forCellReuseIdentifier:RoomMembershipCollapsedBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomMembershipCollapsedWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomMembershipCollapsedWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomMembershipExpandedBubbleCell.class forCellReuseIdentifier:RoomMembershipExpandedBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomMembershipExpandedWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomMembershipExpandedWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:RoomSelectedStickerBubbleCell.class forCellReuseIdentifier:RoomSelectedStickerBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomPredecessorBubbleCell.class forCellReuseIdentifier:RoomPredecessorBubbleCell.defaultReuseIdentifier];
    
    // Prepare expanded header
    expandedHeader = [ExpandedRoomTitleView roomTitleView];
    expandedHeader.delegate = self;
    expandedHeader.tapGestureDelegate = self;
    expandedHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.expandedHeaderContainer addSubview:expandedHeader];
    // Force expanded header in full width
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:expandedHeader
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.expandedHeaderContainer
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:0];
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:expandedHeader
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.expandedHeaderContainer
                                                                      attribute:NSLayoutAttributeLeading
                                                                     multiplier:1.0
                                                                       constant:0];
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:expandedHeader
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.expandedHeaderContainer
                                                                       attribute:NSLayoutAttributeTrailing
                                                                      multiplier:1.0
                                                                        constant:0];
    
    [NSLayoutConstraint activateConstraints:@[leftConstraint, rightConstraint, topConstraint]];
    
    
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipeGesture:)];
    [swipe setNumberOfTouchesRequired:1];
    [swipe setDirection:UISwipeGestureRecognizerDirectionUp];
    [self.expandedHeaderContainer addGestureRecognizer:swipe];
    
    // Replace the default input toolbar view.
    // Note: this operation will force the layout of subviews. That is why cell view classes must be registered before.
    [self updateRoomInputToolbarViewClassIfNeeded];
    
    // set extra area
    [self setRoomActivitiesViewClass:RoomActivitiesView.class];
    
    // Custom the attachmnet viewer
    [self setAttachmentsViewerClass:AttachmentsViewController.class];
    
    // Custom the event details view
    [self setEventDetailsViewClass:EventDetailsView.class];
    
    
    // Update navigation bar items
    
    UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(onButtonPressed:)];
    [self.navigationItem setRightBarButtonItem:searchItem animated:FALSE];
    
//    for (UIBarButtonItem *barButtonItem in self.navigationItem.rightBarButtonItems)
//    {
//        barButtonItem.target = self;
//        barButtonItem.action = @selector(onButtonPressed:);
//    }

    // Prepare missed dicussion badge (if any)
    self.showMissedDiscussionsBadge = _showMissedDiscussionsBadge;
    
    // Set up the room title view according to the data source (if any)
    //[self refreshRoomTitle]; //Already Doing in ViewWillAppear
    
    // Refresh tool bar if the room data source is set.
    if (self.roomDataSource)
    {
        [self refreshRoomInputToolbar];
    }
    
    self.roomContextualMenuPresenter = [RoomContextualMenuPresenter new];
    self.errorPresenter = [MXKErrorAlertPresentation new];
    
    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
    
    
    
    
}

- (void)userInterfaceThemeDidChange
{
    // Consider the main navigation controller if the current view controller is embedded inside a split view controller.
    UINavigationController *mainNavigationController = self.navigationController;
    if (self.splitViewController.isCollapsed && self.splitViewController.viewControllers.count)
    {
        mainNavigationController = self.splitViewController.viewControllers.firstObject;
    }
    
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];
    if (mainNavigationController)
    {
        [ThemeService.shared.theme applyStyleOnNavigationBar:mainNavigationController.navigationBar];
    }

    // Keep navigation bar transparent in some cases
    if (!self.expandedHeaderContainer.hidden || !self.previewHeaderContainer.hidden)
    {
        self.navigationController.navigationBar.translucent = YES;
        mainNavigationController.navigationBar.translucent = YES;
    }
    
    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    // Prepare jump to last unread banner
    self.jumpToLastUnreadBannerContainer.backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.jumpToLastUnreadLabel.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"room_jump_to_first_unread", @"Vector",[NSBundle bundleForClass:[self class]], nil) attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle), NSUnderlineColorAttributeName: ThemeService.shared.theme.textPrimaryColor, NSForegroundColorAttributeName: ThemeService.shared.theme.textPrimaryColor}];
    self.jumpToLastUnreadBannerSeparatorView.backgroundColor = ThemeService.shared.theme.headerBorderColor;
    
    
    self.expandedHeaderContainer.backgroundColor = ThemeService.shared.theme.baseColor;
    self.previewHeaderContainer.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    
    missedDiscussionsBadgeLabel.textColor = ThemeService.shared.theme.baseTextPrimaryColor;
    missedDiscussionsBadgeLabel.font = [UIFont boldSystemFontOfSize:14];
    missedDiscussionsBadgeLabel.backgroundColor = [UIColor clearColor];
    
    // Check the table view style to select its bg color.
    self.bubblesTableView.backgroundColor = ((self.bubblesTableView.style == UITableViewStylePlain) ? ThemeService.shared.theme.backgroundColor : ThemeService.shared.theme.headerBackgroundColor);
    self.bubblesTableView.separatorColor = ThemeService.shared.theme.lineBreakColor;
    self.view.backgroundColor = self.bubblesTableView.backgroundColor;
    
    if (self.bubblesTableView.dataSource)
    {
        [self.bubblesTableView reloadData];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    
    // Refresh the room title view
    [self refreshRoomTitle];
    
    // Refresh tool bar if the room data source is set.
    if (self.roomDataSource)
    {
        [self refreshRoomInputToolbar];
    }
    
    [self listenTypingNotifications];
    [self listenCallNotifications];
    [self listenWidgetNotifications];
    [self listenTombstoneEventNotifications];
    [self listenMXSessionStateChangeNotifications];
    
    if (self.showExpandedHeader)
    {
        [self showExpandedHeader:YES];
    }
    
    // Observe kAppDelegateDidTapStatusBarNotification.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self.bubblesTableView setContentOffset:CGPointMake(-self.bubblesTableView.mxk_adjustedContentInset.left, -self.bubblesTableView.mxk_adjustedContentInset.top) animated:YES];
        
    }];
    
    [self.titleView setNeedsDisplay];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // hide action
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    [self removeTypingNotificationsListener];
    
    if (customizedRoomDataSource)
    {
        // Cancel potential selected event (to leave edition mode)
        if (customizedRoomDataSource.selectedEventId)
        {
            [self cancelEventSelection];
        }
    }
    
    // Hide expanded/preview header to restore navigation bar settings
    [self showExpandedHeader:NO];
    [self showPreviewHeader:NO];
    
    if (kAppDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateDidTapStatusBarNotificationObserver];
        kAppDelegateDidTapStatusBarNotificationObserver = nil;
    }
    
    [self removeCallNotificationsListeners];
    [self removeWidgetNotificationsListeners];
    [self removeTombstoneEventNotificationsListener];
    [self removeMXSessionStateChangeNotificationsListener];

    // Re-enable the read marker display, and disable its update.
    self.roomDataSource.showReadMarker = YES;
    self.updateRoomReadMarker = NO;
    isAppeared = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    isAppeared = YES;
    [self checkReadMarkerVisibility];
    
    if (self.roomDataSource)
    {
        // Set visible room id
        [LucUtility instance].visibleRoomId = self.roomDataSource.roomId;
    }
    
    // Observe network reachability
    kAppDelegateNetworkStatusDidChangeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateNetworkStatusDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self refreshActivitiesViewDisplay];
        
    }];
    [self refreshActivitiesViewDisplay];
    [self refreshJumpToLastUnreadBannerDisplay];
    
    // Observe missed notifications
    mxRoomSummaryDidChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXRoomSummaryDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

        MXRoomSummary *roomSummary = notif.object;

        if ([roomSummary.roomId isEqualToString:self.roomDataSource.roomId])
        {
            [self refreshMissedDiscussionsCount:NO];
        }
    }];
    [self refreshMissedDiscussionsCount:YES];
    
//    [self.titleView setNeedsDisplay];
//    
//    
//    if ([self.titleView isKindOfClass:[RoomTitleView class]])
//    {
//        RoomTitleView *roomTitleView = (RoomTitleView*)self.titleView;
//        [roomTitleView layoutSubviews];
//        [roomTitleView updateConstraints];
//        
//        [roomTitleView.voiceCallButton setNeedsDisplay];
//        [roomTitleView.voiceCallButton layoutIfNeeded];
//        [roomTitleView.voiceCallButton updateConstraints];
//    }
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Hide contextual menu if needed
    [self hideContextualMenuAnimated:NO];
    
    // Reset visible room id
    [LucUtility instance].visibleRoomId = nil;
    
    if (kAppDelegateNetworkStatusDidChangeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateNetworkStatusDidChangeNotificationObserver];
        kAppDelegateNetworkStatusDidChangeNotificationObserver = nil;
    }
    
    if (mxRoomSummaryDidChangeObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:mxRoomSummaryDidChangeObserver];
        mxRoomSummaryDidChangeObserver = nil;
    }

    if (mxEventDidDecryptNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:mxEventDidDecryptNotificationObserver];
        mxEventDidDecryptNotificationObserver = nil;
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    UIEdgeInsets contentInset = self.bubblesTableView.contentInset;
    contentInset.bottom = self.bottomLayoutGuide.length;
    self.bubblesTableView.contentInset = contentInset;
    
    
    
    if (eventDetailsView)
    {
        if (eventDetailsView.superview)
        {
            // Hide the potential expanded header when a subview is added.
            self.showExpandedHeader = NO;
        }
        else
        {
            // Reset
            eventDetailsView = nil;
        }
    }
    
    // Check whether the expanded header is visible
    if (self.expandedHeaderContainer.isHidden == NO)
    {
        // Adjust the expanded header height by taking into account the actual position of the room avatar
        // This position depends automatically on the screen orientation.
        if ([self.titleView isKindOfClass:[RoomAvatarTitleView class]])
        {
            RoomAvatarTitleView *avatarTitleView = (RoomAvatarTitleView*)self.titleView;
            CGPoint roomAvatarOriginInTitleView = avatarTitleView.roomAvatarMask.frame.origin;
            CGPoint roomAvatarActualPosition = [avatarTitleView convertPoint:roomAvatarOriginInTitleView toView:self.view];
            
            CGFloat avatarHeaderHeight = roomAvatarActualPosition.y + expandedHeader.roomAvatar.frame.size.height;
            if (expandedHeader.roomAvatarHeaderBackgroundHeightConstraint.constant != avatarHeaderHeight)
            {
                expandedHeader.roomAvatarHeaderBackgroundHeightConstraint.constant = avatarHeaderHeight;
                
                // Force the layout of expandedHeader to update the position of 'bottomBorderView' which
                // is used to define the actual height of the expanded header container.
                [expandedHeader layoutIfNeeded];
            }
        }

        self.edgesForExtendedLayout = UIRectEdgeAll;
        
        // Adjust the top constraint of the bubbles table
        CGRect frame = expandedHeader.bottomBorderView.frame;
        self.expandedHeaderContainerHeightConstraint.constant = frame.origin.y + frame.size.height;

        self.bubblesTableViewTopConstraint.constant = self.expandedHeaderContainerHeightConstraint.constant - self.bubblesTableView.mxk_adjustedContentInset.top;
        self.jumpToLastUnreadBannerContainerTopConstraint.constant = self.expandedHeaderContainerHeightConstraint.constant;
    }
    // Check whether the preview header is visible
    else if (previewHeader)
    {
        if (previewHeader.mainHeaderContainer.isHidden)
        {
            // Check here the main background height to display a correct navigation bar background.
            CGRect frame = self.navigationController.navigationBar.frame;
            
            CGFloat mainHeaderBackgroundHeight = frame.size.height + (frame.origin.y > 0 ? frame.origin.y : 0);
            
            if (previewHeader.mainHeaderBackgroundHeightConstraint.constant != mainHeaderBackgroundHeight)
            {
                previewHeader.mainHeaderBackgroundHeightConstraint.constant = mainHeaderBackgroundHeight;
                
                // Force the layout of previewHeader to update the position of 'bottomBorderView' which
                // is used to define the actual height of the preview container.
                [previewHeader layoutIfNeeded];
            }
        }

        self.edgesForExtendedLayout = UIRectEdgeAll;

        // Adjust the top constraint of the bubbles table
        CGRect frame = previewHeader.bottomBorderView.frame;
        self.previewHeaderContainerHeightConstraint.constant = frame.origin.y + frame.size.height;

        self.bubblesTableViewTopConstraint.constant = self.previewHeaderContainerHeightConstraint.constant - self.bubblesTableView.mxk_adjustedContentInset.top;
        self.jumpToLastUnreadBannerContainerTopConstraint.constant = self.previewHeaderContainerHeightConstraint.constant;
    }
    else
    {
        // In non expanded header mode, the navigation bar is opaque
        // The table view must not display behind it
        self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;

        self.jumpToLastUnreadBannerContainerTopConstraint.constant = self.bubblesTableView.mxk_adjustedContentInset.top; // no expanded
    }
    
    [self refreshMissedDiscussionsCount:YES];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    // Hide the expanded header or the preview in case of iPad and iPhone 6 plus.
    // On these devices, the display mode of the splitviewcontroller may change during screen rotation.
    // It may correspond to an overlay mode in portrait and a side-by-side mode in landscape.
    // This display mode change involves a change at the navigation bar level.
    // If we don't hide the header, the navigation bar is in a wrong state after rotation. FIXME: Find a way to keep visible the header on rotation.
    if ([GBDeviceInfo deviceInfo].family == GBDeviceFamilyiPad || [GBDeviceInfo deviceInfo].displayInfo.display >= GBDeviceDisplay5p5Inch)
    {
        // Hide the expanded header (if any) on device rotation
        [self showExpandedHeader:NO];
        
        // Hide the preview header (if any) before rotating (It will be restored by `refreshRoomTitle` call if this is still a room preview).
        [self showPreviewHeader:NO];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((coordinator.transitionDuration + 0.5) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            // Let [self refreshRoomTitle] refresh this title view correctly
            [self refreshRoomTitle];
            
        });
    }
    else if (previewHeader)
    {
        // Refresh here the preview header according to the coming screen orientation.
        
        // Retrieve the affine transform indicating the amount of rotation being applied to the interface.
        // This transform is the identity transform when no rotation is applied;
        // otherwise, it is a transform that applies a 90 degree, -90 degree, or 180 degree rotation.
        CGAffineTransform transform = coordinator.targetTransform;
        
        // Consider here only the transform that applies a +/- 90 degree.
        if (transform.b * transform.c == -1)
        {
            UIInterfaceOrientation currentScreenOrientation = [[UIApplication sharedApplication] statusBarOrientation];
            BOOL isLandscapeOriented = YES;
            
            switch (currentScreenOrientation)
            {
                case UIInterfaceOrientationLandscapeRight:
                case UIInterfaceOrientationLandscapeLeft:
                {
                    // We leave here landscape orientation
                    isLandscapeOriented = NO;
                    break;
                }
                default:
                    break;
            }
            
            [self refreshPreviewHeader:isLandscapeOriented];
        }
    }
    else
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((coordinator.transitionDuration + 0.5) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            // Refresh the room title at the end of the transition to take into account the potential changes during the transition.
            // For example the display of a preview header is ignored during transition.
            [self refreshRoomTitle];
            
        });
    }
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark - Override MXKRoomViewController

- (void)onMatrixSessionChange
{
    [super onMatrixSessionChange];
    
    // Re-enable the read marker display, and disable its update.
    self.roomDataSource.showReadMarker = YES;
    self.updateRoomReadMarker = NO;
}

- (void)displayRoom:(MXKRoomDataSource *)dataSource
{
    // Remove potential preview Data
    if (roomPreviewData)
    {
        roomPreviewData = nil;
        [self removeMatrixSession:self.mainSession];
    }
    
    // Enable the read marker display, and disable its update.
    dataSource.showReadMarker = YES;
    self.updateRoomReadMarker = NO;
    
    [super displayRoom:dataSource];
    
    customizedRoomDataSource = nil;
    
    if (self.roomDataSource)
    {
        [self listenToServerNotices];

        self.eventsAcknowledgementEnabled = YES;
        
        // Set room title view
        [self refreshRoomTitle];
        
        // Store ref on customized room data source
        if ([dataSource isKindOfClass:RoomDataSource.class])
        {
            customizedRoomDataSource = (RoomDataSource*)dataSource;
        }
    }
    else
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
    [self refreshRoomInputToolbar];
}

- (void)onRoomDataSourceReady
{
    // Handle here invitation
    if (self.roomDataSource.room.summary.membership == MXMembershipInvite)
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        // Show preview header
        [self showPreviewHeader:YES];
    }
    else
    {
        [super onRoomDataSourceReady];
    }
}

- (void)updateViewControllerAppearanceOnRoomDataSourceState
{
    [super updateViewControllerAppearanceOnRoomDataSourceState];
    
    if (self.isRoomPreview)
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        // Remove input tool bar if any
        if (self.inputToolbarView)
        {
            [super setRoomInputToolbarViewClass:nil];
        }
        
        if (previewHeader)
        {
            previewHeader.mxRoom = self.roomDataSource.room;
            
            // Force the layout of subviews (some constraints may have been updated)
            [self forceLayoutRefresh];
        }
    }
    else
    {
        [self showPreviewHeader:NO];
        
        self.navigationItem.rightBarButtonItem.enabled = (self.roomDataSource != nil);
        
        self.titleView.editable = NO;
        
        if (self.roomDataSource)
        {
            // Force expanded header refresh if it is visible
            if (self.expandedHeaderContainer.isHidden == NO)
            {
                expandedHeader.mxRoom = self.roomDataSource.room;
                
                // Force the layout of subviews (some constraints may have been updated)
                [self forceLayoutRefresh];
            }
            
            // Restore tool bar view and room activities view if none
            if (!self.inputToolbarView)
            {
                [self updateRoomInputToolbarViewClassIfNeeded];
                
                [self refreshRoomInputToolbar];
                
                self.inputToolbarView.hidden = (self.roomDataSource.state != MXKDataSourceStateReady);
            }
            
            if (!self.activitiesView)
            {
                // And the extra area
                [self setRoomActivitiesViewClass:RoomActivitiesView.class];
            }
        }
    }
}

- (void)leaveRoomOnEvent:(MXEvent*)event
{
    [self showExpandedHeader:NO];
    
    // Force a simple title view initialised with the current room before leaving actually the room.
    [self setRoomTitleViewClass:SimpleRoomTitleView.class];
    self.titleView.editable = NO;
    self.titleView.mxRoom = self.roomDataSource.room;
    
    // Hide the potential read marker banner.
    self.jumpToLastUnreadBannerContainer.hidden = YES;
    
    [super leaveRoomOnEvent:event];
}

// Set the input toolbar according to the current display
- (void)updateRoomInputToolbarViewClassIfNeeded
{
    Class roomInputToolbarViewClass = RoomInputToolbarView.class;
    
    BOOL shouldDismissContextualMenu = NO;

    // Check the user has enough power to post message
    if (self.roomDataSource.roomState)
    {
        MXRoomPowerLevels *powerLevels = self.roomDataSource.roomState.powerLevels;
        NSInteger userPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId];
        
        BOOL canSend = (userPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsMessage:kMXEventTypeStringRoomMessage]);
        BOOL isRoomObsolete = self.roomDataSource.roomState.isObsolete;
        BOOL isResourceLimitExceeded = [self.roomDataSource.mxSession.syncError.errcode isEqualToString:kMXErrCodeStringResourceLimitExceeded];
        
        if (isRoomObsolete || isResourceLimitExceeded)
        {
            roomInputToolbarViewClass = nil;
            shouldDismissContextualMenu = YES;
        }
        else if (!canSend)
        {
            roomInputToolbarViewClass = DisabledRoomInputToolbarView.class;
            shouldDismissContextualMenu = YES;
        }
    }

    // Do not show toolbar in case of preview
    if (self.isRoomPreview)
    {
        roomInputToolbarViewClass = nil;
        shouldDismissContextualMenu = YES;
    }
    
    if (shouldDismissContextualMenu)
    {
        [self hideContextualMenuAnimated:NO];
    }
    
    // Change inputToolbarView class only if given class is different from current one
    if (!self.inputToolbarView || ![self.inputToolbarView isMemberOfClass:roomInputToolbarViewClass])
    {
        [super setRoomInputToolbarViewClass:roomInputToolbarViewClass];
        [self updateInputToolBarViewHeight];
    }
}

// Get the height of the current room input toolbar
- (CGFloat)inputToolbarHeight
{
    CGFloat height = 0;

    if ([self.inputToolbarView isKindOfClass:RoomInputToolbarView.class])
    {
        height = ((RoomInputToolbarView*)self.inputToolbarView).mainToolbarHeightConstraint.constant;
    }
    else if ([self.inputToolbarView isKindOfClass:DisabledRoomInputToolbarView.class])
    {
        height = ((DisabledRoomInputToolbarView*)self.inputToolbarView).mainToolbarMinHeightConstraint.constant;
    }

    return height;
}

- (void)setRoomActivitiesViewClass:(Class)roomActivitiesViewClass
{
    // Do not show room activities in case of preview (FIXME: show it when live events will be supported during peeking)
    if (self.isRoomPreview)
    {
        roomActivitiesViewClass = nil;
    }
    
    [super setRoomActivitiesViewClass:roomActivitiesViewClass];
}

- (BOOL)isIRCStyleCommand:(NSString*)string
{
    // Override the default behavior for `/join` command in order to open automatically the joined room
    
    if ([string hasPrefix:kMXKSlashCmdJoinRoom])
    {
        // Join a room
        NSString *roomAlias;
        
        // Sanity check
        if (string.length > kMXKSlashCmdJoinRoom.length)
        {
            roomAlias = [string substringFromIndex:kMXKSlashCmdJoinRoom.length + 1];
            
            // Remove white space from both ends
            roomAlias = [roomAlias stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
        
        // Check
        if (roomAlias.length)
        {
            // TODO: /join command does not support via parameters yet
            [self.mainSession joinRoom:roomAlias viaServers:nil success:^(MXRoom *room) {
                
                // Show the room
                [[LucUtility instance] showRoom:room.roomId andEventId:nil withMatrixSession:self.mainSession];
                
            } failure:^(NSError *error) {
                
                NSLog(@"[RoomVC] Join roomAlias (%@) failed", roomAlias);
                //Alert user
                [[LucUtility instance] showErrorAsAlert:error];
                
            }];
        }
        else
        {
            // Display cmd usage in text input as placeholder
            self.inputToolbarView.placeholder = @"Usage: /join <room_alias>";
        }
        return YES;
    }
    return [super isIRCStyleCommand:string];
}

- (void)setKeyboardHeight:(CGFloat)keyboardHeight
{
    [super setKeyboardHeight:keyboardHeight];
    
    if (keyboardHeight)
    {
        // Hide the potential expanded header when keyboard appears.
        // Dispatch this operation to prevent flickering in navigation bar.
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self showExpandedHeader:NO];
            
        });
    }
    
    // Make the activity indicator follow the keyboard
    // At runtime, this creates a smooth animation
    CGPoint activityIndicatorCenter = self.activityIndicator.center;
    activityIndicatorCenter.y = self.view.center.y - keyboardHeight / 2;
    self.activityIndicator.center = activityIndicatorCenter;
}

- (void)dismissTemporarySubViews
{
    [super dismissTemporarySubViews];
    
}

- (void)setBubbleTableViewDisplayInTransition:(BOOL)bubbleTableViewDisplayInTransition
{
    if (self.isBubbleTableViewDisplayInTransition != bubbleTableViewDisplayInTransition)
    {
        [super setBubbleTableViewDisplayInTransition:bubbleTableViewDisplayInTransition];
        
        // Refresh additional displays when the table is ready.
        if (!bubbleTableViewDisplayInTransition && !self.bubblesTableView.isHidden)
        {
            [self refreshActivitiesViewDisplay];
            
            [self checkReadMarkerVisibility];
            [self refreshJumpToLastUnreadBannerDisplay];
        }
    }
}

- (void)sendTextMessage:(NSString*)msgTxt
{
    if (self.inputToolBarSendMode == RoomInputToolbarViewSendModeReply && customizedRoomDataSource.selectedEventId)
    {
        [self.roomDataSource sendReplyToEventWithId:customizedRoomDataSource.selectedEventId withTextMessage:msgTxt success:nil failure:^(NSError *error) {
            // Just log the error. The message will be displayed in red in the room history
            NSLog(@"[MXKRoomViewController] sendTextMessage failed.");
        }];
    }
    else if (self.inputToolBarSendMode == RoomInputToolbarViewSendModeEdit && customizedRoomDataSource.selectedEventId)
    {
        [self.roomDataSource replaceTextMessageForEventWithId:customizedRoomDataSource.selectedEventId withTextMessage:msgTxt success:nil failure:^(NSError *error) {
            // Just log the error. The message will be displayed in red
            NSLog(@"[MXKRoomViewController] sendTextMessage failed.");
        }];
    }
    else
    {
        // Let the datasource send it and manage the local echo
        [self.roomDataSource sendTextMessage:msgTxt success:nil failure:^(NSError *error)
         {
             // Just log the error. The message will be displayed in red in the room history
             NSLog(@"[MXKRoomViewController] sendTextMessage failed.");
         }];
    }
    
    [self cancelEventSelection];
}

- (void)destroy
{
    rightBarButtonItems = nil;
    for (UIBarButtonItem *barButtonItem in self.navigationItem.rightBarButtonItems)
    {
        barButtonItem.enabled = NO;
    }
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    if (customizedRoomDataSource)
    {
        customizedRoomDataSource.selectedEventId = nil;
        customizedRoomDataSource = nil;
    }
    
    [self removeTypingNotificationsListener];
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
    if (kAppDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateDidTapStatusBarNotificationObserver];
        kAppDelegateDidTapStatusBarNotificationObserver = nil;
    }
    if (kAppDelegateNetworkStatusDidChangeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateNetworkStatusDidChangeNotificationObserver];
        kAppDelegateNetworkStatusDidChangeNotificationObserver = nil;
    }
    if (mxRoomSummaryDidChangeObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:mxRoomSummaryDidChangeObserver];
        mxRoomSummaryDidChangeObserver = nil;
    }
    if (mxEventDidDecryptNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:mxEventDidDecryptNotificationObserver];
        mxEventDidDecryptNotificationObserver = nil;
    }
    
    [self removeCallNotificationsListeners];
    [self removeWidgetNotificationsListeners];
    [self removeTombstoneEventNotificationsListener];
    [self removeMXSessionStateChangeNotificationsListener];
    [self removeServerNoticesListener];

    if (previewHeader || (self.expandedHeaderContainer.isHidden == NO))
    {
        // Here [destroy] is called before [viewWillDisappear:]
        NSLog(@"[RoomVC] destroyed whereas it is still visible");
        
        [previewHeader removeFromSuperview];
        previewHeader = nil;
        
        // Hide preview header container to ignore [self showPreviewHeader:NO] call (if any).
        self.previewHeaderContainer.hidden = YES;
    }
    
    [expandedHeader removeFromSuperview];
    expandedHeader = nil;
    
    roomPreviewData = nil;
    
    missedDiscussionsBarButtonCustomView = nil;
    missedDiscussionsBadgeLabelBgView = nil;
    missedDiscussionsBadgeLabel = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXEventDidChangeIdentifierNotification object:nil];
    
    [super destroy];
}

#pragma mark -

- (void)setShowExpandedHeader:(BOOL)showExpandedHeader
{
    _showExpandedHeader = showExpandedHeader;
    [self showExpandedHeader:showExpandedHeader];
}

- (void)setShowMissedDiscussionsBadge:(BOOL)showMissedDiscussionsBadge
{
    _showMissedDiscussionsBadge = showMissedDiscussionsBadge;
    
    if (_showMissedDiscussionsBadge && !missedDiscussionsBarButtonCustomView)
    {
        // Prepare missed dicussion badge
        missedDiscussionsBarButtonCustomView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 21)];
        missedDiscussionsBarButtonCustomView.backgroundColor = [UIColor clearColor];
        missedDiscussionsBarButtonCustomView.clipsToBounds = NO;
        
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:missedDiscussionsBarButtonCustomView
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                                           multiplier:1.0
                                                                             constant:21];
        
        missedDiscussionsBadgeLabelBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 21, 21)];
        [missedDiscussionsBadgeLabelBgView.layer setCornerRadius:10];
        
        [missedDiscussionsBarButtonCustomView addSubview:missedDiscussionsBadgeLabelBgView];
        missedDiscussionsBarButtonCustomView.accessibilityIdentifier = @"RoomVCMissedDiscussionsBarButton";
        
        missedDiscussionsBadgeLabel = [[UILabel alloc]initWithFrame:CGRectMake(2, 2, 17, 17)];
        missedDiscussionsBadgeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [missedDiscussionsBadgeLabelBgView addSubview:missedDiscussionsBadgeLabel];
        
        NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:missedDiscussionsBadgeLabel
                                                                             attribute:NSLayoutAttributeCenterX
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:missedDiscussionsBadgeLabelBgView
                                                                             attribute:NSLayoutAttributeCenterX
                                                                            multiplier:1.0
                                                                              constant:0];
        NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:missedDiscussionsBadgeLabel
                                                                             attribute:NSLayoutAttributeCenterY
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:missedDiscussionsBadgeLabelBgView
                                                                             attribute:NSLayoutAttributeCenterY
                                                                            multiplier:1.0
                                                                              constant:0];
        
        [NSLayoutConstraint activateConstraints:@[heightConstraint, centerXConstraint, centerYConstraint]];
    }
    else
    {
        missedDiscussionsBarButtonCustomView = nil;
        missedDiscussionsBadgeLabelBgView = nil;
        missedDiscussionsBadgeLabel = nil;
    }
}

#pragma mark - Internals

- (void)forceLayoutRefresh
{
    // Sanity check: check whether the table view data source is set.
    if (self.bubblesTableView.dataSource)
    {
        [self.view layoutIfNeeded];
    }
}

- (BOOL)isRoomPreview
{
    // Check first whether some preview data are defined.
    if (roomPreviewData)
    {
        return YES;
    }
    
    if (self.roomDataSource && self.roomDataSource.state == MXKDataSourceStateReady && self.roomDataSource.room.summary.membership == MXMembershipInvite)
    {
        return YES;
    }
    
    return NO;
}

- (void)refreshRoomTitle
{
    if (rightBarButtonItems && !self.navigationItem.rightBarButtonItems)
    {
        // Restore by default the search bar button.
        self.navigationItem.rightBarButtonItems = rightBarButtonItems;
        
    }
    
    
     //Set the right room title view
    if (self.isRoomPreview)
    {
        // Do not show the right buttons
        self.navigationItem.rightBarButtonItems = nil;

        [self showPreviewHeader:YES];
    }
    else if (self.roomDataSource)
    {
        [self showPreviewHeader:NO];

        if (self.roomDataSource.isLive)
        {
            // Enable the right buttons (Search and Integrations)
            for (UIBarButtonItem *barButtonItem in self.navigationItem.rightBarButtonItems)
            {
                barButtonItem.enabled = YES;
            }
            
            //HARSH already set above, only search button is needed

            if (self.navigationItem.rightBarButtonItems.count == 2)
            {
                //HARSH : Matrix apps are not enabled
                BOOL matrixAppsEnabled = false;//[[NSUserDefaults standardUserDefaults] boolForKey:@"matrixApps"];
                if (!matrixAppsEnabled)
                {
                    // If the setting is disabled, do not show the icon
                    self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItem];
                }
                else if ([self widgetsCount:NO])
                {
                    // Show there are widgets by changing the "apps" icon color
                    // Show it in red only for room widgets, not user's widgets
                    // TODO: Design must be reviewed
                    UIImage *icon = self.navigationItem.rightBarButtonItems[1].image;
                    icon = [MXKTools paintImage:icon withColor:ThemeService.shared.theme.warningColor];
                    icon = [icon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

                    self.navigationItem.rightBarButtonItems[1].image = icon;
                }
                else
                {
                    // Reset original icon
                    self.navigationItem.rightBarButtonItems[1].image = [UIImage imageNamed:@"apps-icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
                }
            }

            // Do not change title view class here if the expanded header is visible.
            if (self.expandedHeaderContainer.hidden)
            {
                [self setRoomTitleViewClass:RoomTitleView.class];
                ((RoomTitleView*)self.titleView).tapGestureDelegate = self;
            }
            else
            {
                // Force expanded header refresh
                expandedHeader.mxRoom = self.roomDataSource.room;

                // Force the layout of subviews (some constraints may have been updated)
                [self forceLayoutRefresh];
            }
        }
        else
        {
            // Remove the search button temporarily
            rightBarButtonItems = self.navigationItem.rightBarButtonItems;
            self.navigationItem.rightBarButtonItems = nil;

            [self setRoomTitleViewClass:SimpleRoomTitleView.class];
            self.titleView.editable = NO;
        }
    }
    else
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
    
}

- (void)refreshRoomInputToolbar
{
    MXKImageView *userPictureView;

    // Check whether the input toolbar is ready before updating it.
    if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:RoomInputToolbarView.class])
    {
        RoomInputToolbarView *roomInputToolbarView = (RoomInputToolbarView*)self.inputToolbarView;
        
        // Check whether the call option is supported
        roomInputToolbarView.supportCallOption = self.roomDataSource.mxSession.callManager && self.roomDataSource.room.summary.membersCount.joined >= 2;
        
        // Get user picture view in input toolbar
        userPictureView = roomInputToolbarView.pictureView;
        
        // Show the hangup button if there is an active call
        //  in the current room
        MXCall *callInRoom = [self.roomDataSource.mxSession.callManager callInRoom:self.roomDataSource.roomId];
        if ((callInRoom && callInRoom.state != MXCallStateEnded))
        {
            roomInputToolbarView.activeCall = YES;
        }
        else
        {
            roomInputToolbarView.activeCall = NO;
            
            // Hide the call button if there is an active call in another room
            roomInputToolbarView.supportCallOption &= ([[LucUtility instance] callStatusBarWindow] == nil);
        }
        
        
    }
    else if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:DisabledRoomInputToolbarView.class])
    {
        DisabledRoomInputToolbarView *roomInputToolbarView = (DisabledRoomInputToolbarView*)self.inputToolbarView;

        // Get user picture view in input toolbar
        userPictureView = roomInputToolbarView.pictureView;

        // For the moment, there is only one reason to use `DisabledRoomInputToolbarView`
        [roomInputToolbarView setDisabledReason:NSLocalizedStringFromTableInBundle(@"room_do_not_have_permission_to_post", @"Vector",[NSBundle bundleForClass:[self class]], nil)];
    }

    // Set user picture in input toolbar
    if (userPictureView)
    {
        UIImage *preview = [AvatarGenerator generateAvatarForMatrixItem:self.mainSession.myUser.userId withDisplayName:self.mainSession.myUser.displayname];
        
        // Suppose the avatar is stored unencrypted on the Matrix media repository.
        userPictureView.enableInMemoryCache = YES;
        [userPictureView setImageURI:self.mainSession.myUser.avatarUrl
                            withType:nil
                 andImageOrientation:UIImageOrientationUp
                       toFitViewSize:userPictureView.frame.size
                          withMethod:MXThumbnailingMethodCrop
                        previewImage:preview
                        mediaManager:self.mainSession.mediaManager];
        [userPictureView.layer setCornerRadius:userPictureView.frame.size.width / 2];
        userPictureView.clipsToBounds = YES;
    }
}

- (void)setInputToolBarSendMode:(RoomInputToolbarViewSendMode)sendMode
{
    if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:[RoomInputToolbarView class]])
    {
        RoomInputToolbarView *roomInputToolbarView = (RoomInputToolbarView*)self.inputToolbarView;
        roomInputToolbarView.sendMode = sendMode;
    }
}

- (RoomInputToolbarViewSendMode)inputToolBarSendMode
{
    RoomInputToolbarViewSendMode sendMode = RoomInputToolbarViewSendModeSend;
    if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:[RoomInputToolbarView class]])
    {
        RoomInputToolbarView *roomInputToolbarView = (RoomInputToolbarView*)self.inputToolbarView;
        sendMode = roomInputToolbarView.sendMode;
    }

    return sendMode;
}

- (void)onSwipeGesture:(UISwipeGestureRecognizer*)swipeGestureRecognizer
{
    UIView *view = swipeGestureRecognizer.view;
    
    if (view == self.expandedHeaderContainer)
    {
        // Hide the expanded header when user swipes upward on expanded header.
        // We reset here the property 'showExpandedHeader'. Then the header is not expanded automatically on viewWillAppear.
        self.showExpandedHeader = NO;
    }
    else if (view == self.activitiesView)
    {
        // Dismiss the keyboard when user swipes down on activities view.
        [self.inputToolbarView dismissKeyboard];
    }
}

- (void)updateInputToolBarViewHeight
{
    // Update the inputToolBar height.
    CGFloat height = [self inputToolbarHeight];
    // Disable animation during the update
    [UIView setAnimationsEnabled:NO];
    [self roomInputToolbarView:self.inputToolbarView heightDidChanged:height completion:nil];
    [UIView setAnimationsEnabled:YES];
}

- (void)handleLongPressFromCell:(id<MXKCellRendering>)cell withTappedEvent:(MXEvent*)event
{
    if (event && !customizedRoomDataSource.selectedEventId)
    {
        [self showContextualMenuForEvent:event fromSingleTapGesture:NO cell:cell animated:YES];
    }
}

- (void)showReactionHistoryForEventId:(NSString*)eventId animated:(BOOL)animated
{
    //HARSH : no rection History for framework
}

- (void)showCameraControllerAnimated:(BOOL)animated
{
    CameraPresenter *cameraPresenter = [CameraPresenter new];
    cameraPresenter.delegate = self;
    [cameraPresenter presentCameraFrom:self with:@[MXKUTI.image, MXKUTI.movie] animated:YES];

    self.cameraPresenter = cameraPresenter;
}


- (void)showMediaPickerAnimated:(BOOL)animated
{
    MediaPickerCoordinatorBridgePresenter *mediaPickerPresenter = [[MediaPickerCoordinatorBridgePresenter alloc] initWithSession:self.mainSession mediaUTIs:@[MXKUTI.image, MXKUTI.movie] allowsMultipleSelection:YES];
    mediaPickerPresenter.delegate = self;
    
    UIView *sourceView;
    
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    
    if (roomInputToolbarView)
    {
        sourceView = roomInputToolbarView.attachMediaButton;
    }
    else
    {
        sourceView = self.inputToolbarView;
    }

    [mediaPickerPresenter presentFrom:self sourceView:sourceView sourceRect:sourceView.bounds animated:YES];
    
    self.mediaPickerPresenter = mediaPickerPresenter;
}

#pragma mark - Hide/Show expanded header

- (void)showExpandedHeader:(BOOL)isVisible
{
    if (self.expandedHeaderContainer.isHidden == isVisible)
    {
        // Check conditions before making the expanded room header visible.
        // This operation is ignored:
        // - if a screen rotation is in progress.
        // - if the room data source has been removed.
        // - if the room data source does not manage a live timeline.
        // - if the user's membership is not 'join'.
        // - if the view controller is not embedded inside a split view controller yet.
        // - if the encryption view is displayed
        // - if the event details view is displayed
        if (isVisible && (isSizeTransitionInProgress == YES || !self.roomDataSource || !self.roomDataSource.isLive || (self.roomDataSource.room.summary.membership != MXMembershipJoin) || !self.splitViewController))
        {
            NSLog(@"[RoomVC] Show expanded header ignored");
            return;
        }
        
        self.expandedHeaderContainer.hidden = !isVisible;
        
        // Consider the main navigation controller if the current view controller is embedded inside a split view controller.
        UINavigationController *mainNavigationController = self.navigationController;
        if (self.splitViewController.isCollapsed && self.splitViewController.viewControllers.count)
        {
            mainNavigationController = self.splitViewController.viewControllers.firstObject;
        }
        
        // When the expanded header is displayed, we hide the bottom border of the navigation bar (the shadow image).
        // The default shadow image is nil. When non-nil, this property represents a custom shadow image to show instead
        // of the default. For a custom shadow image to be shown, a custom background image must also be set with the
        // setBackgroundImage:forBarMetrics: method. If the default background image is used, then the default shadow
        // image will be used regardless of the value of this property.
        UIImage *shadowImage = nil;
        
        if (isVisible)
        {
            [self setRoomTitleViewClass:RoomAvatarTitleView.class];
            // Note the avatar title view does not define tap gesture.
            
            expandedHeader.roomAvatar.alpha = 0.0;
            
            shadowImage = [[UIImage alloc] init];
            
            // Dismiss the keyboard when header is expanded.
            [self.inputToolbarView dismissKeyboard];
        }
        else
        {
            [self setRoomTitleViewClass:RoomTitleView.class];
            ((RoomTitleView*)self.titleView).tapGestureDelegate = self;
        }
        
        // Force the layout of expandedHeader to update the position of 'bottomBorderView' which is used
        // to define the actual height of the expandedHeader container.
        [expandedHeader layoutIfNeeded];
        CGRect frame = expandedHeader.bottomBorderView.frame;
        self.expandedHeaderContainerHeightConstraint.constant = frame.origin.y + frame.size.height;
        
        // Report shadow image
        [mainNavigationController.navigationBar setShadowImage:shadowImage];
        [mainNavigationController.navigationBar setBackgroundImage:shadowImage forBarMetrics:UIBarMetricsDefault];
        mainNavigationController.navigationBar.translucent = isVisible;
        self.navigationController.navigationBar.translucent = isVisible;
        
        // Hide contextual menu if needed
        [self hideContextualMenuAnimated:YES];
        
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             
                             self.bubblesTableViewTopConstraint.constant = (isVisible ? self.expandedHeaderContainerHeightConstraint.constant - self.bubblesTableView.mxk_adjustedContentInset.top : 0);
                             self.jumpToLastUnreadBannerContainerTopConstraint.constant = (isVisible ? self.expandedHeaderContainerHeightConstraint.constant : self.bubblesTableView.mxk_adjustedContentInset.top);
                             
                             expandedHeader.roomAvatar.alpha = 1;
                             
                             // Force to render the view
                             [self forceLayoutRefresh];
                             
                         }
                         completion:^(BOOL finished){
                         }];
    }
}

#pragma mark - Hide/Show preview header

- (void)showPreviewHeader:(BOOL)isVisible
{
    if (self.previewHeaderContainer && self.previewHeaderContainer.isHidden == isVisible)
    {
        // Check conditions before making the preview room header visible.
        // This operation is ignored if a screen rotation is in progress,
        // or if the view controller is not embedded inside a split view controller yet.
        if (isVisible && (isSizeTransitionInProgress == YES || !self.splitViewController))
        {
            NSLog(@"[RoomVC] Show preview header ignored");
            return;
        }
        
        if (isVisible)
        {
            previewHeader = [PreviewRoomTitleView roomTitleView];
            previewHeader.delegate = self;
            previewHeader.tapGestureDelegate = self;
            previewHeader.translatesAutoresizingMaskIntoConstraints = NO;
            [self.previewHeaderContainer addSubview:previewHeader];
            // Force preview header in full width
            NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:previewHeader
                                                                              attribute:NSLayoutAttributeLeading
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:self.previewHeaderContainer
                                                                              attribute:NSLayoutAttributeLeading
                                                                             multiplier:1.0
                                                                               constant:0];
            NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:previewHeader
                                                                               attribute:NSLayoutAttributeTrailing
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:self.previewHeaderContainer
                                                                               attribute:NSLayoutAttributeTrailing
                                                                              multiplier:1.0
                                                                                constant:0];
            // Vertical constraints are required for iOS > 8
            NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:previewHeader
                                                                             attribute:NSLayoutAttributeTop
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self.previewHeaderContainer
                                                                             attribute:NSLayoutAttributeTop
                                                                            multiplier:1.0
                                                                              constant:0];
            NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:previewHeader
                                                                                attribute:NSLayoutAttributeBottom
                                                                                relatedBy:NSLayoutRelationEqual
                                                                                   toItem:self.previewHeaderContainer
                                                                                attribute:NSLayoutAttributeBottom
                                                                               multiplier:1.0
                                                                                 constant:0];
            
            [NSLayoutConstraint activateConstraints:@[leftConstraint, rightConstraint, topConstraint, bottomConstraint]];
            
            if (roomPreviewData)
            {
                previewHeader.roomPreviewData = roomPreviewData;
            }
            else if (self.roomDataSource)
            {
                previewHeader.mxRoom = self.roomDataSource.room;
            }
            
            self.previewHeaderContainer.hidden = NO;

            // Consider the main navigation controller if the current view controller is embedded inside a split view controller.
            UINavigationController *mainNavigationController = self.navigationController;
            if (self.splitViewController.isCollapsed && self.splitViewController.viewControllers.count)
            {
                mainNavigationController = self.splitViewController.viewControllers.firstObject;
            }
            mainNavigationController.navigationBar.translucent = isVisible;
            self.navigationController.navigationBar.translucent = isVisible;
            
            // Finalize preview header display according to the screen orientation
            [self refreshPreviewHeader:UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])];
        }
        else
        {
            [previewHeader removeFromSuperview];
            previewHeader = nil;
            
            self.previewHeaderContainer.hidden = YES;
            
            // Consider the main navigation controller if the current view controller is embedded inside a split view controller.
            UINavigationController *mainNavigationController = self.navigationController;
            if (self.splitViewController.isCollapsed && self.splitViewController.viewControllers.count)
            {
                mainNavigationController = self.splitViewController.viewControllers.firstObject;
            }
            
            // Set a default title view class without handling tap gesture (Let [self refreshRoomTitle] refresh this view correctly).
            [self setRoomTitleViewClass:RoomTitleView.class];
            
            // Remove details icon
            RoomTitleView *roomTitleView = (RoomTitleView*)self.titleView;
            [roomTitleView.roomDetailsIconImageView removeFromSuperview];
            roomTitleView.roomDetailsIconImageView = nil;
            
            // Remove the shadow image used to hide the bottom border of the navigation bar when the preview header is displayed
            [mainNavigationController.navigationBar setShadowImage:nil];
            [mainNavigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
            
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 
                                 self.bubblesTableViewTopConstraint.constant = 0;
                                 self.jumpToLastUnreadBannerContainerTopConstraint.constant = self.bubblesTableView.mxk_adjustedContentInset.top;
                                 
                                 // Force to render the view
                                 [self forceLayoutRefresh];
                                 
                             }
                             completion:^(BOOL finished){
                             }];
        }
    }
}

- (void)refreshPreviewHeader:(BOOL)isLandscapeOriented
{
    if (previewHeader)
    {
        if (isLandscapeOriented
            && [GBDeviceInfo deviceInfo].family != GBDeviceFamilyiPad)
        {
            CGRect frame = self.navigationController.navigationBar.frame;
            
            previewHeader.mainHeaderContainer.hidden = YES;
            previewHeader.mainHeaderBackgroundHeightConstraint.constant = frame.size.height + (frame.origin.y > 0 ? frame.origin.y : 0);
            
            [self setRoomTitleViewClass:RoomTitleView.class];
            // We don't want to handle tap gesture here
            
            // Remove details icon
            RoomTitleView *roomTitleView = (RoomTitleView*)self.titleView;
            [roomTitleView.roomDetailsIconImageView removeFromSuperview];
            roomTitleView.roomDetailsIconImageView = nil;
            
            // Set preview data to provide the room name
            roomTitleView.roomPreviewData = roomPreviewData;
        }
        else
        {
            previewHeader.mainHeaderContainer.hidden = NO;
            previewHeader.mainHeaderBackgroundHeightConstraint.constant = previewHeader.mainHeaderContainer.frame.size.height;

            if ([previewHeader isKindOfClass:PreviewRoomTitleView.class])
            {
                // In case of preview, update the header height so that we can
                // display as much as possible the room topic in this header.
                // Note: the header height is handled by the previewHeader.mainHeaderBackgroundHeightConstraint.
                PreviewRoomTitleView *previewRoomTitleView = (PreviewRoomTitleView *)previewHeader;

                // Compute the height required to display all the room topic
                CGSize sizeThatFitsTextView = [previewRoomTitleView.roomTopic sizeThatFits:CGSizeMake(previewRoomTitleView.roomTopic.frame.size.width, MAXFLOAT)];

                // Increase the preview header height according to the room topic height
                // but limit it in order to let room for room messages at the screen bottom.
                // This free space depends on the device.
                // On an iphone 5 screen, the room topic height cannot be more than 50px.
                // Then, on larger screen, we can allow it a bit more height but we
                // apply a factor to give more priority to the display of more messages.
                CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
                CGFloat maxRoomTopicHeight = 50 + (screenHeight - 568) / 3;

                CGFloat additionalHeight = MIN(maxRoomTopicHeight, sizeThatFitsTextView.height)
                                            - previewRoomTitleView.roomTopic.frame.size.height;

                previewHeader.mainHeaderBackgroundHeightConstraint.constant += additionalHeight;
            }

            [self setRoomTitleViewClass:RoomAvatarTitleView.class];
            // Note the avatar title view does not define tap gesture.
            
            previewHeader.roomAvatar.alpha = 0.0;
            
            // Set the avatar provided in preview data
            if (roomPreviewData.roomAvatarUrl)
            {
                previewHeader.roomAvatarURL = roomPreviewData.roomAvatarUrl;
            }
            else if (roomPreviewData.roomId && roomPreviewData.roomName)
            {
                previewHeader.roomAvatarPlaceholder = [AvatarGenerator generateAvatarForMatrixItem:roomPreviewData.roomId withDisplayName:roomPreviewData.roomName];
            }
            else
            {
                previewHeader.roomAvatarPlaceholder = [MXKTools paintImage:[UIImage imageNamed:@"placeholder" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil]
                                                                 withColor:ThemeService.shared.theme.tintColor];
            }
        }
        
        // Force the layout of previewHeader to update the position of 'bottomBorderView' which is used
        // to define the actual height of the preview container.
        [previewHeader layoutIfNeeded];
        CGRect frame = previewHeader.bottomBorderView.frame;
        self.previewHeaderContainerHeightConstraint.constant = frame.origin.y + frame.size.height;
        
        // Consider the main navigation controller if the current view controller is embedded inside a split view controller.
        UINavigationController *mainNavigationController = self.navigationController;
        if (self.splitViewController.isCollapsed && self.splitViewController.viewControllers.count)
        {
            mainNavigationController = self.splitViewController.viewControllers.firstObject;
        }
        
        // When the preview header is displayed, we hide the bottom border of the navigation bar (the shadow image).
        // The default shadow image is nil. When non-nil, this property represents a custom shadow image to show instead
        // of the default. For a custom shadow image to be shown, a custom background image must also be set with the
        // setBackgroundImage:forBarMetrics: method. If the default background image is used, then the default shadow
        // image will be used regardless of the value of this property.
        UIImage *shadowImage = [[UIImage alloc] init];
        [mainNavigationController.navigationBar setShadowImage:shadowImage];
        [mainNavigationController.navigationBar setBackgroundImage:shadowImage forBarMetrics:UIBarMetricsDefault];
        
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             
                             self.bubblesTableViewTopConstraint.constant = self.previewHeaderContainerHeightConstraint.constant - self.bubblesTableView.mxk_adjustedContentInset.top;
                             self.jumpToLastUnreadBannerContainerTopConstraint.constant = self.previewHeaderContainerHeightConstraint.constant;
                             
                             previewHeader.roomAvatar.alpha = 1;
                             
                             // Force to render the view
                             [self forceLayoutRefresh];
                             
                         }
                         completion:^(BOOL finished){
                         }];
    }
}

#pragma mark - Preview

- (void)displayRoomPreview:(RoomPreviewData *)previewData
{
    // Release existing room data source or preview
    [self displayRoom:nil];
    
    if (previewData)
    {
        self.eventsAcknowledgementEnabled = NO;
        
        [self addMatrixSession:previewData.mxSession];
        
        roomPreviewData = previewData;
        
        [self refreshRoomTitle];
        
        if (roomPreviewData.roomDataSource)
        {
            [super displayRoom:roomPreviewData.roomDataSource];
        }
    }
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    Class cellViewClass = nil;
    BOOL isEncryptedRoom = false;//HARSH: no encryption in framework self.roomDataSource.room.summary.isEncrypte;
    
    // Sanity check
    if ([cellData conformsToProtocol:@protocol(MXKRoomBubbleCellDataStoring)])
    {
        id<MXKRoomBubbleCellDataStoring> bubbleData = (id<MXKRoomBubbleCellDataStoring>)cellData;
        
        // Select the suitable table view cell class, by considering first the empty bubble cell.
        if (bubbleData.hasNoDisplay)
        {
            cellViewClass = RoomEmptyBubbleCell.class;
        }
        else if (bubbleData.tag == RoomBubbleCellDataTagRoomCreateWithPredecessor)
        {
            cellViewClass = RoomPredecessorBubbleCell.class;
        }
        else if (bubbleData.tag == RoomBubbleCellDataTagMembership)
        {
            if (bubbleData.collapsed)
            {
                if (bubbleData.nextCollapsableCellData)
                {
                    cellViewClass = bubbleData.isPaginationFirstBubble ? RoomMembershipCollapsedWithPaginationTitleBubbleCell.class : RoomMembershipCollapsedBubbleCell.class;
                }
                else
                {
                    // Use a normal membership cell for a single membership event
                    cellViewClass = bubbleData.isPaginationFirstBubble ? RoomMembershipWithPaginationTitleBubbleCell.class : RoomMembershipBubbleCell.class;
                }
            }
            else if (bubbleData.collapsedAttributedTextMessage)
            {
                // The cell (and its series) is not collapsed but this cell is the first
                // of the series. So, use the cell with the "collapse" button.
                cellViewClass = bubbleData.isPaginationFirstBubble ? RoomMembershipExpandedWithPaginationTitleBubbleCell.class : RoomMembershipExpandedBubbleCell.class;
            }
            else
            {
                cellViewClass = bubbleData.isPaginationFirstBubble ? RoomMembershipWithPaginationTitleBubbleCell.class : RoomMembershipBubbleCell.class;
            }
        }
        else if (bubbleData.isIncoming)
        {
            if (bubbleData.isAttachmentWithThumbnail)
            {
                // Check whether the provided celldata corresponds to a selected sticker
                if (customizedRoomDataSource.selectedEventId && (bubbleData.attachment.type == MXKAttachmentTypeSticker) && [bubbleData.attachment.eventId isEqualToString:customizedRoomDataSource.selectedEventId])
                {
                    cellViewClass = RoomSelectedStickerBubbleCell.class;
                }
                else if (bubbleData.isPaginationFirstBubble)
                {
                    cellViewClass =  RoomIncomingAttachmentWithPaginationTitleBubbleCell.class;
                }
                else if (bubbleData.shouldHideSenderInformation)
                {
                    cellViewClass =  RoomIncomingAttachmentWithoutSenderInfoBubbleCell.class;
                }
                else
                {
                    cellViewClass = RoomIncomingAttachmentBubbleCell.class;
                }
            }
            else
            {
                if (bubbleData.isPaginationFirstBubble)
                {
                    if (bubbleData.shouldHideSenderName)
                    {
                        cellViewClass =  RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class;
                    }
                    else
                    {
                        cellViewClass =  RoomIncomingTextMsgWithPaginationTitleBubbleCell.class;
                    }
                }
                else if (bubbleData.shouldHideSenderInformation)
                {
                    cellViewClass =  RoomIncomingTextMsgWithoutSenderInfoBubbleCell.class;
                }
                else if (bubbleData.shouldHideSenderName)
                {
                    cellViewClass =  RoomIncomingTextMsgWithoutSenderNameBubbleCell.class;
                }
                else
                {
                    cellViewClass =  RoomIncomingTextMsgBubbleCell.class;
                }
            }
        }
        else
        {
            // Handle here outgoing bubbles
            if (bubbleData.isAttachmentWithThumbnail)
            {
                // Check whether the provided celldata corresponds to a selected sticker
                if (customizedRoomDataSource.selectedEventId && (bubbleData.attachment.type == MXKAttachmentTypeSticker) && [bubbleData.attachment.eventId isEqualToString:customizedRoomDataSource.selectedEventId])
                {
                    cellViewClass = RoomSelectedStickerBubbleCell.class;
                }
                else if (bubbleData.isPaginationFirstBubble)
                {
                    cellViewClass = RoomOutgoingAttachmentWithPaginationTitleBubbleCell.class;
                }
                else if (bubbleData.shouldHideSenderInformation)
                {
                    cellViewClass =  RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.class;
                }
                else
                {
                    cellViewClass =  RoomOutgoingAttachmentBubbleCell.class;
                }
            }
            else
            {
                if (bubbleData.isPaginationFirstBubble)
                {
                    if (bubbleData.shouldHideSenderName)
                    {
                        cellViewClass =  RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class;
                    }
                    else
                    {
                        cellViewClass =  RoomOutgoingTextMsgWithPaginationTitleBubbleCell.class;
                    }
                }
                else if (bubbleData.shouldHideSenderInformation)
                {
                    cellViewClass = RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.class;
                }
                else if (bubbleData.shouldHideSenderName)
                {
                    cellViewClass =  RoomOutgoingTextMsgWithoutSenderNameBubbleCell.class;
                }
                else
                {
                    cellViewClass =  RoomOutgoingTextMsgBubbleCell.class;
                }
            }
        }
    }
    
    return cellViewClass;
}

#pragma mark - MXKDataSource delegate

- (void)dataSource:(MXKDataSource *)dataSource didRecognizeAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo
{
    // Handle here user actions on bubbles for Vector app
    if (customizedRoomDataSource)
    {
        id<MXKRoomBubbleCellDataStoring> bubbleData;
        
        if ([cell isKindOfClass:[MXKRoomBubbleTableViewCell class]])
        {
            MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell*)cell;
            bubbleData = roomBubbleTableViewCell.bubbleData;
        }
        
        

        if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellLongPressOnAvatarView])
        {
            // Add the member display name in text input
            MXRoomMember *roomMember = [self.roomDataSource.roomState.members memberWithUserId:userInfo[kMXKRoomBubbleCellUserIdKey]];
            if (roomMember)
            {
                [self mention:roomMember];
            }
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnMessageTextView] || [actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnContentView])
        {
            // Retrieve the tapped event
            MXEvent *tappedEvent = userInfo[kMXKRoomBubbleCellEventKey];
            
            // Check whether a selection already exist or not
            if (customizedRoomDataSource.selectedEventId)
            {
                [self cancelEventSelection];
            }
            else if (tappedEvent)
            {
                if (tappedEvent.eventType == MXEventTypeRoomCreate)
                {
                    // Handle tap on RoomPredecessorBubbleCell
                    MXRoomCreateContent *createContent = [MXRoomCreateContent modelFromJSON:tappedEvent.content];
                    NSString *predecessorRoomId = createContent.roomPredecessorInfo.roomId;
                    
                    if (predecessorRoomId)
                    {
                        // Show predecessor room
                        [[LucUtility instance] showRoom:predecessorRoomId andEventId:nil withMatrixSession:self.mainSession];
                    }
                }
                else
                {
                    // Show contextual menu on single tap if bubble is not collapsed
                    if (bubbleData.collapsed)
                    {
                        [self selectEventWithId:tappedEvent.eventId];
                    }
                    else
                    {
                        [self showContextualMenuForEvent:tappedEvent fromSingleTapGesture:YES cell:cell animated:YES];
                    }
                }
            }
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnOverlayContainer])
        {
            // Cancel the current event selection
            [self cancelEventSelection];
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellRiotEditButtonPressed])
        {
            [self dismissKeyboard];
            
            MXEvent *selectedEvent = userInfo[kMXKRoomBubbleCellEventKey];
            
            if (selectedEvent)
            {
                [self showContextualMenuForEvent:selectedEvent fromSingleTapGesture:YES cell:cell animated:YES];
            }
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnAttachmentView])
        {
            if (((MXKRoomBubbleTableViewCell*)cell).bubbleData.attachment.eventSentState == MXEventSentStateFailed)
            {
                // Shortcut: when clicking on an unsent media, show the action sheet to resend it
                MXEvent *selectedEvent = [self.roomDataSource eventWithEventId:((MXKRoomBubbleTableViewCell*)cell).bubbleData.attachment.eventId];
                [self dataSource:dataSource didRecognizeAction:kMXKRoomBubbleCellRiotEditButtonPressed inCell:cell userInfo:@{kMXKRoomBubbleCellEventKey:selectedEvent}];
            }
            else if (((MXKRoomBubbleTableViewCell*)cell).bubbleData.attachment.type == MXKAttachmentTypeSticker)
            {
                // We don't open the attachments viewer when the user taps on a sticker.
                // We consider this tap like a selection.
                
                // Check whether a selection already exist or not
                if (customizedRoomDataSource.selectedEventId)
                {
                    [self cancelEventSelection];
                }
                else
                {
                    // Highlight this event in displayed message
                    [self selectEventWithId:((MXKRoomBubbleTableViewCell*)cell).bubbleData.attachment.eventId];
                }
            }
            else
            {
                // Keep default implementation
                [super dataSource:dataSource didRecognizeAction:actionIdentifier inCell:cell userInfo:userInfo];
            }
        }
        
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnReceiptsContainer])
        {
            MXKReceiptSendersContainer *container = userInfo[kMXKRoomBubbleCellReceiptsContainerKey];
            [ReadReceiptsViewController openInViewController:self fromContainer:container withSession:self.mainSession];
        }
        else if ([actionIdentifier isEqualToString:kRoomMembershipExpandedBubbleCellTapOnCollapseButton])
        {
            // Reset the selection before collapsing
            customizedRoomDataSource.selectedEventId = nil;
            
            [self.roomDataSource collapseRoomBubble:((MXKRoomBubbleTableViewCell*)cell).bubbleData collapsed:YES];
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellLongPressOnEvent])
        {
            MXEvent *tappedEvent = userInfo[kMXKRoomBubbleCellEventKey];
            
            if (!bubbleData.collapsed)
            {
                [self handleLongPressFromCell:cell withTappedEvent:tappedEvent];
            }
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellLongPressOnReactionView])
        {
            NSString *tappedEventId = userInfo[kMXKRoomBubbleCellEventIdKey];
            if (tappedEventId)
            {
                [self showReactionHistoryForEventId:tappedEventId animated:YES];
            }
        }
        else
        {
            // Keep default implementation for other actions
            [super dataSource:dataSource didRecognizeAction:actionIdentifier inCell:cell userInfo:userInfo];
        }
    }
    else
    {
        // Keep default implementation for other actions
        [super dataSource:dataSource didRecognizeAction:actionIdentifier inCell:cell userInfo:userInfo];
    }
}

// Display the additiontal event actions menu

//HARSH Redifining method to show fewer options

- (void)showAdditionalActionsMenuForEvent:(MXEvent*)selectedEvent inCell:(id<MXKCellRendering>)cell animated:(BOOL)animated
{
    MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell *)cell;
    MXKAttachment *attachment = roomBubbleTableViewCell.bubbleData.attachment;
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    __weak __typeof(self) weakSelf = self;
    currentAlert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // Add actions for a failed event
    if (selectedEvent.sentState == MXEventSentStateFailed)
    {
        [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"room_event_action_resend", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               
                                                               [self cancelEventSelection];
                                                               
                                                               // Let the datasource resend. It will manage local echo, etc.
                                                               [self.roomDataSource resendEventWithEventId:selectedEvent.eventId success:nil failure:nil];
                                                           }
                                                           
                                                       }]];
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"room_event_action_delete", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               
                                                               [self cancelEventSelection];
                                                               
                                                               [self.roomDataSource removeEventWithEventId:selectedEvent.eventId];
                                                           }
                                                           
                                                       }]];
    }
    
    // Add actions for text message
    if (!attachment)
    {
        // Retrieved data related to the selected event
        NSArray *components = roomBubbleTableViewCell.bubbleData.bubbleComponents;
        MXKRoomBubbleComponent *selectedComponent;
        for (selectedComponent in components)
        {
            if ([selectedComponent.event.eventId isEqualToString:selectedEvent.eventId])
            {
                break;
            }
            selectedComponent = nil;
        }
        
        
        // Check status of the selected event
        if (selectedEvent.sentState == MXEventSentStatePreparing ||
            selectedEvent.sentState == MXEventSentStateEncrypting ||
            selectedEvent.sentState == MXEventSentStateSending)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"room_event_action_cancel_send", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action)
                                     {
                                         if (weakSelf)
                                         {
                                             typeof(self) self = weakSelf;
                                             
                                             self->currentAlert = nil;
                                             
                                             // Cancel and remove the outgoing message
                                             [self.roomDataSource.room cancelSendingOperation:selectedEvent.eventId];
                                             [self.roomDataSource removeEventWithEventId:selectedEvent.eventId];
                                             
                                             [self cancelEventSelection];
                                         }
                                         
                                     }]];
        }
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"room_event_action_quote", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               
                                                               [self cancelEventSelection];
                                                               
                                                               // Quote the message a la Markdown into the input toolbar composer
                                                               self.inputToolbarView.textMessage = [NSString stringWithFormat:@"%@\n>%@\n\n", self.inputToolbarView.textMessage, selectedComponent.textMessage];
                                                               
                                                               // And display the keyboard
                                                               [self.inputToolbarView becomeFirstResponder];
                                                           }
                                                           
                                                       }]];
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"room_event_action_share", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               
                                                               [self cancelEventSelection];
                                                               
                                                               NSArray *activityItems = @[selectedComponent.textMessage];
                                                               
                                                               UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
                                                               
                                                               if (activityViewController)
                                                               {
                                                                   activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                                                                   activityViewController.popoverPresentationController.sourceView = roomBubbleTableViewCell;
                                                                   activityViewController.popoverPresentationController.sourceRect = roomBubbleTableViewCell.bounds;
                                                                   
                                                                   [self presentViewController:activityViewController animated:YES completion:nil];
                                                               }
                                                           }
                                                           
                                                       }]];
    }
    else // Add action for attachment
    {
        if (attachment.type == MXKAttachmentTypeImage || attachment.type == MXKAttachmentTypeVideo)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"room_event_action_save", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   
                                                                   [self cancelEventSelection];
                                                                   
                                                                   [self startActivityIndicator];
                                                                   
                                                                   [attachment save:^{
                                                                       
                                                                       __strong __typeof(weakSelf)self = weakSelf;
                                                                       [self stopActivityIndicator];
                                                                       
                                                                   } failure:^(NSError *error) {
                                                                       
                                                                       __strong __typeof(weakSelf)self = weakSelf;
                                                                       [self stopActivityIndicator];
                                                                       
                                                                       //Alert user
                                                                       [[LucUtility instance] showErrorAsAlert:error];
                                                                       
                                                                   }];
                                                                   
                                                                   // Start animation in case of download during attachment preparing
                                                                   [roomBubbleTableViewCell startProgressUI];
                                                               }
                                                               
                                                           }]];
        }
        
        // Check status of the selected event
        if (selectedEvent.sentState == MXEventSentStatePreparing ||
            selectedEvent.sentState == MXEventSentStateEncrypting ||
            selectedEvent.sentState == MXEventSentStateUploading ||
            selectedEvent.sentState == MXEventSentStateSending)
        {
            // Upload id is stored in attachment url (nasty trick)
            NSString *uploadId = roomBubbleTableViewCell.bubbleData.attachment.contentURL;
            if ([MXMediaManager existingUploaderWithId:uploadId])
            {
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"room_event_action_cancel_send", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   // Get again the loader
                                                                   MXMediaLoader *loader = [MXMediaManager existingUploaderWithId:uploadId];
                                                                   if (loader)
                                                                   {
                                                                       [loader cancel];
                                                                   }
                                                                   // Hide the progress animation
                                                                   roomBubbleTableViewCell.progressView.hidden = YES;
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       
                                                                       self->currentAlert = nil;
                                                                       
                                                                       // Remove the outgoing message and its related cached file.
                                                                       [[NSFileManager defaultManager] removeItemAtPath:roomBubbleTableViewCell.bubbleData.attachment.cacheFilePath error:nil];
                                                                       [[NSFileManager defaultManager] removeItemAtPath:roomBubbleTableViewCell.bubbleData.attachment.thumbnailCachePath error:nil];
                                                                       
                                                                       // Cancel and remove the outgoing message
                                                                       [self.roomDataSource.room cancelSendingOperation:selectedEvent.eventId];
                                                                       [self.roomDataSource removeEventWithEventId:selectedEvent.eventId];
                                                                       
                                                                       [self cancelEventSelection];
                                                                   }
                                                                   
                                                               }]];
            }
        }
        
        if (attachment.type != MXKAttachmentTypeSticker)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"room_event_action_share", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   
                                                                   [self cancelEventSelection];
                                                                   
                                                                   [attachment prepareShare:^(NSURL *fileURL) {
                                                                       
                                                                       __strong __typeof(weakSelf)self = weakSelf;
                                                                       self->documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
                                                                       [self->documentInteractionController setDelegate:self];
                                                                       self->currentSharedAttachment = attachment;
                                                                       
                                                                       if (![self->documentInteractionController presentOptionsMenuFromRect:self.view.frame inView:self.view animated:YES])
                                                                       {
                                                                           self->documentInteractionController = nil;
                                                                           [attachment onShareEnded];
                                                                           self->currentSharedAttachment = nil;
                                                                       }
                                                                       
                                                                   } failure:^(NSError *error) {
                                                                       
                                                                       //Alert user
                                                                       [[LucUtility instance] showErrorAsAlert:error];
                                                                       
                                                                   }];
                                                                   
                                                                   // Start animation in case of download during attachment preparing
                                                                   [roomBubbleTableViewCell startProgressUI];
                                                               }
                                                               
                                                           }]];
        }
    }
    
    // Check status of the selected event
    if (selectedEvent.sentState == MXEventSentStateSent)
    {
        // Check whether download is in progress
        if (selectedEvent.isMediaAttachment)
        {
            NSString *downloadId = roomBubbleTableViewCell.bubbleData.attachment.downloadId;
            if ([MXMediaManager existingDownloaderWithIdentifier:downloadId])
            {
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"room_event_action_cancel_download", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       
                                                                       [self cancelEventSelection];
                                                                       
                                                                       // Get again the loader
                                                                       MXMediaLoader *loader = [MXMediaManager existingDownloaderWithIdentifier:downloadId];
                                                                       if (loader)
                                                                       {
                                                                           [loader cancel];
                                                                       }
                                                                       // Hide the progress animation
                                                                       roomBubbleTableViewCell.progressView.hidden = YES;
                                                                   }
                                                                   
                                                               }]];
            }
        }
        
        // Do not allow to redact the event that enabled encryption (m.room.encryption)
        // because it breaks everything
        if (selectedEvent.eventType != MXEventTypeRoomEncryption)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"room_event_action_redact", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   
                                                                   [self cancelEventSelection];
                                                                   
                                                                   [self startActivityIndicator];
                                                                   
                                                                   [self.roomDataSource.room redactEvent:selectedEvent.eventId reason:nil success:^{
                                                                       
                                                                       __strong __typeof(weakSelf)self = weakSelf;
                                                                       [self stopActivityIndicator];
                                                                       
                                                                   } failure:^(NSError *error) {
                                                                       
                                                                       __strong __typeof(weakSelf)self = weakSelf;
                                                                       [self stopActivityIndicator];
                                                                       
                                                                       NSLog(@"[RoomVC] Redact event (%@) failed", selectedEvent.eventId);
                                                                       //Alert user
                                                                       [[LucUtility instance] showErrorAsAlert:error];
                                                                       
                                                                   }];
                                                               }
                                                               
                                                           }]];
        }
        
        
        
    }
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"cancel", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           [self hideContextualMenuAnimated:YES];
                                                       }
                                                       
                                                   }]];
    
    // Do not display empty action sheet
    if (currentAlert.actions.count > 1)
    {
        NSInteger bubbleComponentIndex = [roomBubbleTableViewCell.bubbleData bubbleComponentIndexForEventId:selectedEvent.eventId];
        
        CGRect sourceRect = [roomBubbleTableViewCell componentFrameInContentViewForIndex:bubbleComponentIndex];
        
        [currentAlert mxk_setAccessibilityIdentifier:@"RoomVCEventMenuAlert"];
        [currentAlert popoverPresentationController].sourceView = roomBubbleTableViewCell;
        [currentAlert popoverPresentationController].sourceRect = sourceRect;
        [self presentViewController:currentAlert animated:animated completion:nil];
    }
    else
    {
        currentAlert = nil;
    }
}



- (BOOL)dataSource:(MXKDataSource *)dataSource shouldDoAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo defaultValue:(BOOL)defaultValue
{
    BOOL shouldDoAction = defaultValue;
    
    if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellShouldInteractWithURL])
    {
        // Try to catch universal link supported by the app
        NSURL *url = userInfo[kMXKRoomBubbleCellUrl];
        // Retrieve the type of interaction expected with the URL (See UITextItemInteraction)
        NSNumber *urlItemInteractionValue = userInfo[kMXKRoomBubbleCellUrlItemInteraction];
        
        // When a link refers to a room alias/id, a user id or an event id, the non-ASCII characters (like '#' in room alias) has been escaped
        // to be able to convert it into a legal URL string.
        NSString *absoluteURLString = [url.absoluteString stringByRemovingPercentEncoding];
        
        // If the link can be open it by the app, let it do
        if ([Tools isUniversalLink:url])
        {
            shouldDoAction = NO;
            
            // iOS Patch: fix vector.im urls before using it
            //NSURL *fixedURL = [Tools fixURLWithSeveralHashKeys:url];
            
            //[[LucUtility instance] handleUniversalLinkFragment:fixedURL.fragment];
        }

        // Open the clicked room
        else if ([MXTools isMatrixRoomIdentifier:absoluteURLString] || [MXTools isMatrixRoomAlias:absoluteURLString])
        {
           shouldDoAction = NO;
//
//            NSString *roomIdOrAlias = absoluteURLString;
//
//            // Open the room or preview it
//            NSString *fragment = [NSString stringWithFormat:@"/room/%@", [MXTools encodeURIComponent:roomIdOrAlias]];
//            [[LucUtility instance] handleUniversalLinkFragment:fragment];
        }
        // Preview the clicked group
        else if ([MXTools isMatrixGroupIdentifier:absoluteURLString])
        {
            shouldDoAction = NO;
//
//            // Open the group or preview it
//            NSString *fragment = [NSString stringWithFormat:@"/group/%@", [MXTools encodeURIComponent:absoluteURLString]];
//            [[LucUtility instance] handleUniversalLinkFragment:fragment];
        }
        else if ([absoluteURLString hasPrefix:EventFormatterOnReRequestKeysLinkAction])
        {
            NSArray<NSString*> *arguments = [absoluteURLString componentsSeparatedByString:EventFormatterLinkActionSeparator];
            if (arguments.count > 1)
            {
                NSString *eventId = arguments[1];
                MXEvent *event = [self.roomDataSource eventWithEventId:eventId];

                if (event)
                {
                    [self reRequestKeysAndShowExplanationAlert:event];
                }
            }
        }
        else if ([absoluteURLString hasPrefix:EventFormatterEditedEventLinkAction])
        {
            NSArray<NSString*> *arguments = [absoluteURLString componentsSeparatedByString:EventFormatterLinkActionSeparator];
            if (arguments.count > 1)
            {
                NSString *eventId = arguments[1];
                [self showEditHistoryForEventId:eventId animated:YES];
            }
            shouldDoAction = NO;
        }
        
        else
        {
            [self showUnableToOpenLinkErrorAlert];
        }
    }
    
    return shouldDoAction;
}

- (void)selectEventWithId:(NSString*)eventId
{
    [self selectEventWithId:eventId inputToolBarSendMode:RoomInputToolbarViewSendModeSend showTimestamp:YES];
}

- (void)selectEventWithId:(NSString*)eventId inputToolBarSendMode:(RoomInputToolbarViewSendMode)inputToolBarSendMode showTimestamp:(BOOL)showTimestamp
{
    [self setInputToolBarSendMode:inputToolBarSendMode];
    
    customizedRoomDataSource.showBubbleDateTimeOnSelection = showTimestamp;
    customizedRoomDataSource.selectedEventId = eventId;
    
    // Force table refresh
    [self dataSource:self.roomDataSource didCellChange:nil];
}

- (void)cancelEventSelection
{
    [self setInputToolBarSendMode:RoomInputToolbarViewSendModeSend];
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    customizedRoomDataSource.showBubbleDateTimeOnSelection = YES;
    customizedRoomDataSource.selectedEventId = nil;
    
    [self restoreTextMessageBeforeEditing];
    
    // Force table refresh
    [self dataSource:self.roomDataSource didCellChange:nil];
}

- (void)showUnableToOpenLinkErrorAlert
{
    [[LucUtility instance] showAlertWithTitle:[NSBundle mxk_localizedStringForKey:@"error"]
                                          message:NSLocalizedStringFromTableInBundle(@"room_message_unable_open_link_error_message", @"Vector",[NSBundle bundleForClass:[self class]], nil)];
}

- (void)editEventContentWithId:(NSString*)eventId
{
    MXEvent *event = [self.roomDataSource eventWithEventId:eventId];
    
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    
    if (roomInputToolbarView)
    {
        self.textMessageBeforeEditing = roomInputToolbarView.textMessage;
        roomInputToolbarView.textMessage = [self.roomDataSource editableTextMessageForEvent:event];
    }
    
    [self selectEventWithId:eventId inputToolBarSendMode:RoomInputToolbarViewSendModeEdit showTimestamp:YES];
}

- (void)restoreTextMessageBeforeEditing
{
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    
    if (self.textMessageBeforeEditing)
    {
        roomInputToolbarView.textMessage = self.textMessageBeforeEditing;
    }
    
    self.textMessageBeforeEditing = nil;
}

- (RoomInputToolbarView*)inputToolbarViewAsRoomInputToolbarView
{
    RoomInputToolbarView *roomInputToolbarView;
    
    if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:[RoomInputToolbarView class]])
    {
        roomInputToolbarView = (RoomInputToolbarView*)self.inputToolbarView;
    }
    
    return roomInputToolbarView;
}

#pragma mark - RoomInputToolbarViewDelegate

- (void)roomInputToolbarViewPresentStickerPicker:(MXKRoomInputToolbarView*)toolbarView
{
    // Search for the sticker picker widget in the user account
    //Widget *widget = [[WidgetManager sharedManager] userWidgets:self.roomDataSource.mxSession ofTypes:@[kWidgetTypeStickerPicker]].firstObject;

    //HARSH: Don't do anything for framework
}

#pragma mark - MXKRoomInputToolbarViewDelegate

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView isTyping:(BOOL)typing
{
    [super roomInputToolbarView:toolbarView isTyping:typing];

    // Cancel potential selected event (to leave edition mode)
    NSString *selectedEventId = customizedRoomDataSource.selectedEventId;
    if (typing && selectedEventId && ![self.roomDataSource canReplyToEventWithId:selectedEventId])
    {
        [self cancelEventSelection];
    }
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView placeCallWithVideo:(BOOL)video
{
    __weak __typeof(self) weakSelf = self;

    NSString *appDisplayName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];

    // Check app permissions first
    [MXKTools checkAccessForCall:video
     manualChangeMessageForAudio:[NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"microphone_access_not_granted_for_call"], appDisplayName]
     manualChangeMessageForVideo:[NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"camera_access_not_granted_for_call"], appDisplayName]
       showPopUpInViewController:self completionHandler:^(BOOL granted) {

           if (weakSelf)
           {
               typeof(self) self = weakSelf;

               if (granted)
               {
                   [self roomInputToolbarView:toolbarView placeCallWithVideo2:video];
               }
               else
               {
                   NSLog(@"RoomViewController: Warning: The application does not have the perssion to place the call");
               }
           }
       }];
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView1 placeCallWithVideo2:(BOOL)video
{
     __weak __typeof(self) weakSelf = self;

    
    {
        [self.roomDataSource.room placeCallWithVideo:video success:nil failure:nil];
    }
}

- (void)roomInputToolbarViewHangupCall:(MXKRoomInputToolbarView *)toolbarView
{
    MXCall *callInRoom = [self.roomDataSource.mxSession.callManager callInRoom:self.roomDataSource.roomId];
    if (callInRoom)
    {
        [callInRoom hangup];
    }
    

    [self refreshActivitiesViewDisplay];
    [self refreshRoomInputToolbar];
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView heightDidChanged:(CGFloat)height completion:(void (^)(BOOL finished))completion
{
    if (self.roomInputToolbarContainerHeightConstraint.constant != height)
    {
        // Hide temporarily the placeholder to prevent its distorsion during height animation
        if (!savedInputToolbarPlaceholder)
        {
            savedInputToolbarPlaceholder = toolbarView.placeholder.length ? toolbarView.placeholder : @"";
        }
        toolbarView.placeholder = nil;
        
        [super roomInputToolbarView:toolbarView heightDidChanged:height completion:^(BOOL finished) {
            
            if (completion)
            {
                completion (finished);
            }
            
            // Consider here the saved placeholder only if no new placeholder has been defined during the height animation.
            if (!toolbarView.placeholder)
            {
                // Restore the placeholder if any
                toolbarView.placeholder =  savedInputToolbarPlaceholder.length ? savedInputToolbarPlaceholder : nil;
            }
            savedInputToolbarPlaceholder = nil;
        }];
    }
}

- (void)roomInputToolbarViewDidTapFileUpload:(MXKRoomInputToolbarView *)toolbarView
{
    MXKDocumentPickerPresenter *documentPickerPresenter = [MXKDocumentPickerPresenter new];
    documentPickerPresenter.delegate = self;
                                      
    NSArray<MXKUTI*> *allowedUTIs = @[MXKUTI.data];
    [documentPickerPresenter presentDocumentPickerWith:allowedUTIs from:self animated:YES completion:nil];
    
    self.documentPickerPresenter = documentPickerPresenter;
}

- (void)roomInputToolbarViewDidTapCamera:(MXKRoomInputToolbarView*)toolbarView
{
    [self showCameraControllerAnimated:YES];
}

- (void)roomInputToolbarViewDidTapMediaLibrary:(MXKRoomInputToolbarView*)toolbarView
{
    [self showMediaPickerAnimated:YES];
}



#pragma mark - Action

- (IBAction)onButtonPressed:(id)sender
{
    // Search button
    if (sender == self.navigationItem.rightBarButtonItem)
    {
        
        RoomSearchViewController* roomSearchViewController = [[RoomSearchViewController alloc] init];
        
        [self dismissKeyboard];
        
        // Add the current data source to be able to search messages.
        roomSearchViewController.roomDataSource = self.roomDataSource;
        
        
        [self.navigationController pushViewController:roomSearchViewController animated:true];
        
        
        // Hide back button title
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    }
    
    else if (sender == self.jumpToLastUnreadButton)
    {
        // Hide expanded header to restore navigation bar settings.
        [self showExpandedHeader:NO];
        // Dismiss potential keyboard.
        [self dismissKeyboard];

        // Jump to the last unread event by using a temporary room data source initialized with the last unread event id.
        MXWeakify(self);
        [RoomDataSource loadRoomDataSourceWithRoomId:self.roomDataSource.roomId initialEventId:self.roomDataSource.room.accountData.readMarkerEventId andMatrixSession:self.mainSession onComplete:^(id roomDataSource) {
            MXStrongifyAndReturnIfNil(self);

            [roomDataSource finalizeInitialization];

            // Center the bubbles table content on the bottom of the read marker event in order to display correctly the read marker view.
            self.centerBubblesTableViewContentOnTheInitialEventBottom = YES;
            [self displayRoom:roomDataSource];

            // Give the data source ownership to the room view controller.
            self.hasRoomDataSourceOwnership = YES;
        }];
    }
    else if (sender == self.resetReadMarkerButton)
    {
        // Move the read marker to the current read receipt position.
        [self.roomDataSource.room forgetReadMarker];
        
        // Hide the banner
        self.jumpToLastUnreadBannerContainer.hidden = YES;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    // Update the selected background view
    if (ThemeService.shared.theme.selectedBackgroundColor)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = ThemeService.shared.theme.selectedBackgroundColor;
    }
    else
    {
        if (tableView.style == UITableViewStylePlain)
        {
            cell.selectedBackgroundView = nil;
        }
        else
        {
            cell.selectedBackgroundView.backgroundColor = nil;
        }
    }
    
    if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
    {
        MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell*)cell;
        if (roomBubbleTableViewCell.readMarkerView)
        {
            readMarkerTableViewCell = roomBubbleTableViewCell;
            
            [self checkReadMarkerVisibility];
        }
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (cell == readMarkerTableViewCell)
    {
        readMarkerTableViewCell = nil;
    }
    
    [super tableView:tableView didEndDisplayingCell:cell forRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark -

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    
    [self checkReadMarkerVisibility];
    
    // Switch back to the live mode when the user scrolls to the bottom of the non live timeline.
    if (!self.roomDataSource.isLive && ![self isRoomPreview])
    {
        CGFloat contentBottomPosY = self.bubblesTableView.contentOffset.y + self.bubblesTableView.frame.size.height - self.bubblesTableView.mxk_adjustedContentInset.bottom;
        if (contentBottomPosY >= self.bubblesTableView.contentSize.height && ![self.roomDataSource.timeline canPaginate:MXTimelineDirectionForwards])
        {
            [self goBackToLive];
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([MXKRoomViewController instancesRespondToSelector:@selector(scrollViewWillBeginDragging:)])
    {
        [super scrollViewWillBeginDragging:scrollView];
    }
    
    if (!self.expandedHeaderContainer.isHidden)
    {
        // Store here the position of the first touch down event
        UIPanGestureRecognizer *panGestureRecognizer = scrollView.panGestureRecognizer;
        if (panGestureRecognizer && panGestureRecognizer.numberOfTouches)
        {
            startScrollingPoint = [panGestureRecognizer locationOfTouch:0 inView:self.view];
        }
        else
        {
            startScrollingPoint = CGPointZero;
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([MXKRoomViewController instancesRespondToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)])
    {
        [super scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
    
    if (decelerate == NO)
    {
        // Handle swipe on expanded header
        [self onScrollViewDidEndScrolling:scrollView];
        
        [self refreshActivitiesViewDisplay];
        [self refreshJumpToLastUnreadBannerDisplay];
    }
    else
    {
        // Dispatch async the expanded header handling in order to let the deceleration go first.
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // Handle swipe on expanded header
            [self onScrollViewDidEndScrolling:scrollView];
            
        });
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([MXKRoomViewController instancesRespondToSelector:@selector(scrollViewDidEndDecelerating:)])
    {
        [super scrollViewDidEndDecelerating:scrollView];
    }
    
    [self refreshActivitiesViewDisplay];
    [self refreshJumpToLastUnreadBannerDisplay];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if ([MXKRoomViewController instancesRespondToSelector:@selector(scrollViewDidEndScrollingAnimation:)])
    {
        [super scrollViewDidEndScrollingAnimation:scrollView];
    }
    
    [self refreshActivitiesViewDisplay];
    [self refreshJumpToLastUnreadBannerDisplay];
}

- (void)onScrollViewDidEndScrolling:(UIScrollView *)scrollView
{
    // Check whether the user's finger has been dragged over the expanded header.
    // In that case the expanded header is collapsed
    if (self.expandedHeaderContainer.isHidden == NO && (startScrollingPoint.y != 0))
    {
        UIPanGestureRecognizer *panGestureRecognizer = scrollView.panGestureRecognizer;
        CGPoint translate = [panGestureRecognizer translationInView:self.view];
        
        if (startScrollingPoint.y + translate.y < self.expandedHeaderContainer.frame.size.height)
        {
            // Hide the expanded header by reseting the property 'showExpandedHeader'. Then the header is not expanded automatically on viewWillAppear.
            self.showExpandedHeader = NO;
        }
    }
}

#pragma mark - MXKRoomTitleViewDelegate

- (BOOL)roomTitleViewShouldBeginEditing:(MXKRoomTitleView*)titleView
{
    // Disable room name edition
    return NO;
}

#pragma mark - RoomTitleViewTapGestureDelegate

- (void)roomTitleView:(RoomTitleView*)titleView recognizeTapGesture:(UITapGestureRecognizer*)tapGestureRecognizer
{
    UIView *tappedView = tapGestureRecognizer.view;
    
    if (tappedView == titleView.titleMask)
    {
        if (self.expandedHeaderContainer.isHidden)
        {
            // Expand the header
            [self showExpandedHeader:YES];
        }
        
    }

    else if (tappedView == previewHeader.rightButton)
    {
        // 'Join' button has been pressed
        if (roomPreviewData)
        {
            // Attempt to join the room (keep reference on the potential eventId, the preview data will be removed automatically in case of success).
            NSString *eventId = roomPreviewData.eventId;
            
            // We promote here join by room alias instead of room id when an alias is available.
            NSString *roomIdOrAlias = roomPreviewData.roomId;
            if (roomPreviewData.roomAliases.count)
            {
                roomIdOrAlias = roomPreviewData.roomAliases.firstObject;
            }
            
            // Note in case of simple link to a room the signUrl param is nil
            [self joinRoomWithRoomIdOrAlias:roomIdOrAlias viaServers:roomPreviewData.viaServers  andSignUrl:roomPreviewData.emailInvitation.signUrl completion:^(BOOL succeed) {
                
                if (succeed)
                {
                    // If an event was specified, replace the datasource by a non live datasource showing the event
                    if (eventId)
                    {
                        MXWeakify(self);
                        [RoomDataSource loadRoomDataSourceWithRoomId:self.roomDataSource.roomId initialEventId:eventId andMatrixSession:self.mainSession onComplete:^(id roomDataSource) {
                            MXStrongifyAndReturnIfNil(self);

                            [roomDataSource finalizeInitialization];
                            ((RoomDataSource*)roomDataSource).markTimelineInitialEvent = YES;

                            [self displayRoom:roomDataSource];

                            self.hasRoomDataSourceOwnership = YES;
                        }];
                    }
                    else
                    {
                        // Enable back the text input
                        [self setRoomInputToolbarViewClass:RoomInputToolbarView.class];
                        [self updateInputToolBarViewHeight];
                        
                        // And the extra area
                        [self setRoomActivitiesViewClass:RoomActivitiesView.class];
                        
                        [self refreshRoomTitle];
                        [self refreshRoomInputToolbar];
                    }
                }
                
            }];
        }
        else
        {
            [self joinRoom:^(BOOL succeed) {
                
                if (succeed)
                {
                    [self refreshRoomTitle];
                }
                
            }];
        }
    }
    else if (tappedView == previewHeader.leftButton)
    {
        // 'Decline' button has been pressed
        if (roomPreviewData)
        {
            // Decline this invitation = leave this page
            [[LucUtility instance] restoreInitialDisplay:^{}];
        }
        else
        {
            [self startActivityIndicator];
            
            [self.roomDataSource.room leave:^{
                
                [self stopActivityIndicator];
                
                // We remove the current view controller.
                // Pop to homes view controller
                [[LucUtility instance] restoreInitialDisplay:^{}];
                
            } failure:^(NSError *error) {
                
                [self stopActivityIndicator];
                NSLog(@"[RoomVC] Failed to reject an invited room (%@) failed", self.roomDataSource.room.roomId);
                
            }];
        }
    }
}

#pragma mark - Typing management

- (void)removeTypingNotificationsListener
{
    if (self.roomDataSource)
    {
        // Remove the previous live listener
        if (typingNotifListener)
        {
            MXWeakify(self);
            [self.roomDataSource.room liveTimeline:^(MXEventTimeline *liveTimeline) {
                MXStrongifyAndReturnIfNil(self);

                [liveTimeline removeListener:self->typingNotifListener];
                self->typingNotifListener = nil;
            }];
        }
    }
    
    currentTypingUsers = nil;
}

- (void)listenTypingNotifications
{
    if (self.roomDataSource)
    {
        // Add typing notification listener
        MXWeakify(self);
        self->typingNotifListener = [self.roomDataSource.room listenToEventsOfTypes:@[kMXEventTypeStringTypingNotification] onEvent:^(MXEvent *event, MXTimelineDirection direction, MXRoomState *roomState) {
            MXStrongifyAndReturnIfNil(self);

            // Handle only live events
            if (direction == MXTimelineDirectionForwards)
            {
                // Retrieve typing users list
                NSMutableArray *typingUsers = [NSMutableArray arrayWithArray:self.roomDataSource.room.typingUsers];
                // Remove typing info for the current user
                NSUInteger index = [typingUsers indexOfObject:self.mainSession.myUser.userId];
                if (index != NSNotFound)
                {
                    [typingUsers removeObjectAtIndex:index];
                }

                // Ignore this notification if both arrays are empty
                if (self->currentTypingUsers.count || typingUsers.count)
                {
                    self->currentTypingUsers = typingUsers;
                    [self refreshActivitiesViewDisplay];
                }
            }
        }];

        // Retrieve the current typing users list
        NSMutableArray *typingUsers = [NSMutableArray arrayWithArray:self.roomDataSource.room.typingUsers];
        // Remove typing info for the current user
        NSUInteger index = [typingUsers indexOfObject:self.mainSession.myUser.userId];
        if (index != NSNotFound)
        {
            [typingUsers removeObjectAtIndex:index];
        }
        currentTypingUsers = typingUsers;
        [self refreshActivitiesViewDisplay];
    }
}

- (void)refreshTypingNotification
{
    if ([self.activitiesView isKindOfClass:RoomActivitiesView.class])
    {
        // Prepare here typing notification
        NSString* text = nil;
        NSUInteger count = currentTypingUsers.count;
        
        // get the room member names
        NSMutableArray *names = [[NSMutableArray alloc] init];
        
        // keeps the only the first two users
        for(int i = 0; i < MIN(count, 2); i++)
        {
            NSString* name = currentTypingUsers[i];
            
            MXRoomMember* member = [self.roomDataSource.roomState.members memberWithUserId:name];
            
            if (member && member.displayname.length)
            {
                name = member.displayname;
            }
            
            // sanity check
            if (name)
            {
                [names addObject:name];
            }
        }
        
        if (0 == names.count)
        {
            // something to do ?
        }
        else if (1 == names.count)
        {
            text = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"room_one_user_is_typing", @"Vector",[NSBundle bundleForClass:[self class]], nil), names[0]];
        }
        else if (2 == names.count)
        {
            text = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"room_two_users_are_typing", @"Vector",[NSBundle bundleForClass:[self class]], nil), names[0], names[1]];
        }
        else
        {
            text = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"room_many_users_are_typing", @"Vector",[NSBundle bundleForClass:[self class]], nil), names[0], names[1]];
        }
        
        [((RoomActivitiesView*) self.activitiesView) displayTypingNotification:text];
    }
}

#pragma mark - Call notifications management

- (void)removeCallNotificationsListeners
{
    if (kMXCallStateDidChangeObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kMXCallStateDidChangeObserver];
        kMXCallStateDidChangeObserver = nil;
    }
    if (kMXCallManagerConferenceStartedObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kMXCallManagerConferenceStartedObserver];
        kMXCallManagerConferenceStartedObserver = nil;
    }
    if (kMXCallManagerConferenceFinishedObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kMXCallManagerConferenceFinishedObserver];
        kMXCallManagerConferenceFinishedObserver = nil;
    }
}

- (void)listenCallNotifications
{
    kMXCallStateDidChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallStateDidChange object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXCall *call = notif.object;
        if ([call.room.roomId isEqualToString:customizedRoomDataSource.roomId])
        {
            [self refreshActivitiesViewDisplay];
            [self refreshRoomInputToolbar];
        }
    }];
    kMXCallManagerConferenceStartedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallManagerConferenceStarted object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        NSString *roomId = notif.object;
        if ([roomId isEqualToString:customizedRoomDataSource.roomId])
        {
            [self refreshActivitiesViewDisplay];
        }
    }];
    kMXCallManagerConferenceFinishedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallManagerConferenceFinished object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        NSString *roomId = notif.object;
        if ([roomId isEqualToString:customizedRoomDataSource.roomId])
        {
            [self refreshActivitiesViewDisplay];
            [self refreshRoomInputToolbar];
        }
    }];
}


#pragma mark - Server notices management

- (void)removeServerNoticesListener
{
    if (serverNotices)
    {
        [serverNotices close];
        serverNotices = nil;
    }
}

- (void)listenToServerNotices
{
    if (!serverNotices)
    {
        serverNotices = [[MXServerNotices alloc] initWithMatrixSession:self.roomDataSource.mxSession];
        serverNotices.delegate = self;
    }
}

- (void)serverNoticesDidChangeState:(MXServerNotices *)serverNotices
{
    [self refreshActivitiesViewDisplay];
}

#pragma mark - Widget notifications management

- (void)removeWidgetNotificationsListeners
{
    if (kMXKWidgetManagerDidUpdateWidgetObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kMXKWidgetManagerDidUpdateWidgetObserver];
        kMXKWidgetManagerDidUpdateWidgetObserver = nil;
    }
}

- (void)listenWidgetNotifications
{
    kMXKWidgetManagerDidUpdateWidgetObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kWidgetManagerDidUpdateWidgetNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

        Widget *widget = notif.object;
        if (widget.mxSession == self.roomDataSource.mxSession
            && [widget.roomId isEqualToString:customizedRoomDataSource.roomId])
        {
            // Jitsi conference widget existence is shown in the bottom bar
            // Update the bar
            [self refreshActivitiesViewDisplay];
            [self refreshRoomInputToolbar];
            [self refreshRoomTitle];
        }
    }];
}

- (void)showJitsiErrorAsAlert:(NSError*)error
{
    // Customise the error for permission issues
    if ([error.domain isEqualToString:WidgetManagerErrorDomain] && error.code == WidgetManagerErrorCodeNotEnoughPower)
    {
        error = [NSError errorWithDomain:error.domain
                                    code:error.code
                                userInfo:@{
                                           NSLocalizedDescriptionKey: NSLocalizedStringFromTableInBundle(@"room_conference_call_no_power", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                           }];
    }

    // Alert user
    [[LucUtility instance] showErrorAsAlert:error];
}

- (NSUInteger)widgetsCount:(BOOL)includeUserWidgets
{
    NSUInteger widgetsCount = [[WidgetManager sharedManager] widgetsNotOfTypes:@[]
                                                                        inRoom:self.roomDataSource.room
                                                                 withRoomState:self.roomDataSource.roomState].count;
    if (includeUserWidgets)
    {
        widgetsCount += [[WidgetManager sharedManager] userWidgets:self.roomDataSource.room.mxSession].count;
    }

    return widgetsCount;
}

#pragma mark - Unreachable Network Handling

- (void)refreshActivitiesViewDisplay
{
    if ([self.activitiesView isKindOfClass:RoomActivitiesView.class])
    {
        RoomActivitiesView *roomActivitiesView = (RoomActivitiesView*)self.activitiesView;

        // Reset gesture recognizers
        while (roomActivitiesView.gestureRecognizers.count)
        {
            [roomActivitiesView removeGestureRecognizer:roomActivitiesView.gestureRecognizers[0]];
        }

        if ([self.roomDataSource.mxSession.syncError.errcode isEqualToString:kMXErrCodeStringResourceLimitExceeded])
        {
            [roomActivitiesView showResourceLimitExceededError:self.roomDataSource.mxSession.syncError.userInfo onAdminContactTapped:^(NSURL *adminContact) {
                if ([[UIApplication sharedApplication] canOpenURL:adminContact])
                {
                    [[UIApplication sharedApplication] openURL:adminContact];
                }
                else
                {
                    NSLog(@"[RoomVC] refreshActivitiesViewDisplay: adminContact(%@) cannot be opened", adminContact);
                }
            }];
        }
        else if ([LucUtility instance].isOffline)
        {
            [roomActivitiesView displayNetworkErrorNotification:NSLocalizedStringFromTableInBundle(@"room_offline_notification", @"Vector",[NSBundle bundleForClass:[self class]], nil)];
        }
        else if (customizedRoomDataSource.roomState.isObsolete)
        {
            MXWeakify(self);
            [roomActivitiesView displayRoomReplacementWithRoomLinkTappedHandler:^{
                MXStrongifyAndReturnIfNil(self);

                MXEvent *stoneTombEvent = [self->customizedRoomDataSource.roomState stateEventsWithType:kMXEventTypeStringRoomTombStone].lastObject;

                NSString *replacementRoomId = self->customizedRoomDataSource.roomState.tombStoneContent.replacementRoomId;
                if ([self.roomDataSource.mxSession roomWithRoomId:replacementRoomId])
                {
                    // Open the room if it is already joined
                    [[LucUtility instance] showRoom:replacementRoomId andEventId:nil withMatrixSession:self.roomDataSource.mxSession];
                }
                else
                {
                    // Else auto join it via the server that sent the event
                    NSLog(@"[RoomVC] Auto join an upgraded room: %@ -> %@. Sender: %@",                              self->customizedRoomDataSource.roomState.roomId,
                          replacementRoomId, stoneTombEvent.sender);
                          
                    NSString *viaSenderServer = [MXTools serverNameInMatrixIdentifier:stoneTombEvent.sender];

                    if (viaSenderServer)
                    {
                        [self startActivityIndicator];
                        [self.roomDataSource.mxSession joinRoom:replacementRoomId viaServers:@[viaSenderServer] success:^(MXRoom *room) {
                            [self stopActivityIndicator];

                            [[LucUtility instance] showRoom:replacementRoomId andEventId:nil withMatrixSession:self.roomDataSource.mxSession];

                        } failure:^(NSError *error) {
                            [self stopActivityIndicator];

                            NSLog(@"[RoomVC] Failed to join an upgraded room. Error: %@",
                                  error);
                            [[LucUtility instance] showErrorAsAlert:error];
                        }];
                    }
                }
            }];
        }
        else if (customizedRoomDataSource.roomState.isOngoingConferenceCall)
        {
            // Show the "Ongoing conference call" banner only if the user is not in the conference
            MXCall *callInRoom = [self.roomDataSource.mxSession.callManager callInRoom:self.roomDataSource.roomId];
            if (callInRoom && callInRoom.state != MXCallStateEnded)
            {
                if ([self checkUnsentMessages] == NO)
                {
                    [self refreshTypingNotification];
                }
            }
            else
            {
                [roomActivitiesView displayOngoingConferenceCall:^(BOOL video) {
                    
                    NSLog(@"[RoomVC] onOngoingConferenceCallPressed");
                    
                    // Make sure there is not yet a call
                    if (![customizedRoomDataSource.mxSession.callManager callInRoom:customizedRoomDataSource.roomId])
                    {
                        [customizedRoomDataSource.room placeCallWithVideo:video success:nil failure:nil];
                    }
                } onClosePressed:nil];
            }
        }
        
        else if ([self checkUnsentMessages] == NO)
        {
            // Show "scroll to bottom" icon when the most recent message is not visible,
            // or when the timelime is not live (this icon is used to go back to live).
            // Note: we check if `currentEventIdAtTableBottom` is set to know whether the table has been rendered at least once.
            if (!self.roomDataSource.isLive || (currentEventIdAtTableBottom && [self isBubblesTableScrollViewAtTheBottom] == NO))
            {
                // Retrieve the unread messages count
                NSUInteger unreadCount = self.roomDataSource.room.summary.localUnreadEventCount;
                
                if (unreadCount == 0)
                {
                    // Refresh the typing notification here
                    // We will keep visible this notification (if any) beside the "scroll to bottom" icon.
                    [self refreshTypingNotification];
                }
                
                [roomActivitiesView displayScrollToBottomIcon:unreadCount onIconTapGesture:^{
                    
                    [self goBackToLive];
                    
                }];
            }
            else if (serverNotices.usageLimit && serverNotices.usageLimit.isServerNoticeUsageLimit)
            {
                [roomActivitiesView showResourceUsageLimitNotice:serverNotices.usageLimit onAdminContactTapped:^(NSURL *adminContact) {

                    if ([[UIApplication sharedApplication] canOpenURL:adminContact])
                    {
                        [[UIApplication sharedApplication] openURL:adminContact];
                    }
                    else
                    {
                        NSLog(@"[RoomVC] refreshActivitiesViewDisplay: adminContact(%@) cannot be opened", adminContact);
                    }
                }];
            }
            else
            {
                [self refreshTypingNotification];
            }
        }
        
        // Recognize swipe downward to dismiss keyboard if any
        UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipeGesture:)];
        [swipe setNumberOfTouchesRequired:1];
        [swipe setDirection:UISwipeGestureRecognizerDirectionDown];
        [roomActivitiesView addGestureRecognizer:swipe];
    }
}

- (void)goBackToLive
{
    if (self.roomDataSource.isLive)
    {
        // Enable the read marker display, and disable its update (in order to not mark as read all the new messages by default).
        self.roomDataSource.showReadMarker = YES;
        self.updateRoomReadMarker = NO;
        
        [self scrollBubblesTableViewToBottomAnimated:YES];
    }
    else
    {
        // Switch back to the room live timeline managed by MXKRoomDataSourceManager
        MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:self.mainSession];

        MXWeakify(self);
        [roomDataSourceManager roomDataSourceForRoom:self.roomDataSource.roomId create:YES onComplete:^(MXKRoomDataSource *roomDataSource) {
            MXStrongifyAndReturnIfNil(self);

            // Scroll to bottom the bubble history on the display refresh.
            self->shouldScrollToBottomOnTableRefresh = YES;

            [self displayRoom:roomDataSource];

            // The room view controller do not have here the data source ownership.
            self.hasRoomDataSourceOwnership = NO;

            [self refreshActivitiesViewDisplay];
            [self refreshJumpToLastUnreadBannerDisplay];

            if (self.saveProgressTextInput)
            {
                // Restore the potential message partially typed before jump to last unread messages.
                self.inputToolbarView.textMessage = roomDataSource.partialTextMessage;
            }
        }];
    }
}

#pragma mark - Missed discussions handling

- (void)refreshMissedDiscussionsCount:(BOOL)force
{
    // Ignore this action when no room is displayed
    if (!self.roomDataSource || !missedDiscussionsBarButtonCustomView)
    {
        return;
    }
    
    NSUInteger highlightCount = 0;
    NSUInteger missedCount = [[LucUtility instance].lucMasterController missedDiscussionsCount];
    
    // Compute the missed notifications count of the current room by considering its notification mode in Riot.
    NSUInteger roomNotificationCount = self.roomDataSource.room.summary.notificationCount;
    if (self.roomDataSource.room.isMentionsOnly)
    {
        // Only the highlighted missed messages must be considered here.
        roomNotificationCount = self.roomDataSource.room.summary.highlightCount;
    }
    
    // Remove the current room from the missed discussion counter.
    if (missedCount && roomNotificationCount)
    {
        missedCount--;
    }
    
    if (missedCount)
    {
        // Compute the missed highlight count
        highlightCount = [[LucUtility instance].lucMasterController missedHighlightDiscussionsCount];
        if (highlightCount && self.roomDataSource.room.summary.highlightCount)
        {
            // Remove the current room from the missed highlight counter
            highlightCount--;
        }
    }
    
    if (force || missedDiscussionsCount != missedCount || missedHighlightCount != highlightCount)
    {
        missedDiscussionsCount = missedCount;
        missedHighlightCount = highlightCount;
        
        NSMutableArray *leftBarButtonItems = [NSMutableArray arrayWithArray: self.navigationItem.leftBarButtonItems];
        
        if (missedCount)
        {
            // Refresh missed discussions count label
            if (missedCount > 99)
            {
                missedDiscussionsBadgeLabel.text = @"99+";
            }
            else
            {
                missedDiscussionsBadgeLabel.text = [NSString stringWithFormat:@"%tu", missedCount];
            }
            
            [missedDiscussionsBadgeLabel sizeToFit];
            
            // Update the label background view frame
            CGRect frame = missedDiscussionsBadgeLabelBgView.frame;
            frame.size.width = round(missedDiscussionsBadgeLabel.frame.size.width + 18);
            
            if ([GBDeviceInfo deviceInfo].osVersion.major < 11)
            {
                // Consider the main navigation controller if the current view controller is embedded inside a split view controller.
                UINavigationController *mainNavigationController = self.navigationController;
                if (self.splitViewController.isCollapsed && self.splitViewController.viewControllers.count)
                {
                    mainNavigationController = self.splitViewController.viewControllers.firstObject;
                }
                UINavigationItem *backItem = mainNavigationController.navigationBar.backItem;
                UIBarButtonItem *backButton = backItem.backBarButtonItem;
                
                if (backButton && !backButton.title.length)
                {
                    // Shift the badge on the left to be close the back icon
                    frame.origin.x = ([GBDeviceInfo deviceInfo].displayInfo.display > GBDeviceDisplay4Inch ? -35 : -25);
                }
                else
                {
                    frame.origin.x = 0;
                }
            }
            
            // Caution: set label background view frame only in case of changes to prevent from looping on 'viewDidLayoutSubviews'.
            if (!CGRectEqualToRect(missedDiscussionsBadgeLabelBgView.frame, frame))
            {
                missedDiscussionsBadgeLabelBgView.frame = frame;
            }
            
            // Set the right background color
            if (highlightCount)
            {
                missedDiscussionsBadgeLabelBgView.backgroundColor = ThemeService.shared.theme.noticeColor;
            }
            else
            {
                missedDiscussionsBadgeLabelBgView.backgroundColor = ThemeService.shared.theme.noticeSecondaryColor;
            }
            
            if (!missedDiscussionsButton || [leftBarButtonItems indexOfObject:missedDiscussionsButton] == NSNotFound)
            {
                missedDiscussionsButton = [[UIBarButtonItem alloc] initWithCustomView:missedDiscussionsBarButtonCustomView];
                
                // Add it in left bar items
                [leftBarButtonItems addObject:missedDiscussionsButton];
            }
        }
        else if (missedDiscussionsButton)
        {
            [leftBarButtonItems removeObject:missedDiscussionsButton];
            missedDiscussionsButton = nil;
        }
        
        self.navigationItem.leftBarButtonItems = leftBarButtonItems;
    }
}

#pragma mark - Unsent Messages Handling

-(BOOL)checkUnsentMessages
{
    BOOL hasUnsent = NO;
    BOOL hasUnsentDueToUnknownDevices = NO;
    
    if ([self.activitiesView isKindOfClass:RoomActivitiesView.class])
    {
        NSArray<MXEvent*> *outgoingMsgs = self.roomDataSource.room.outgoingMessages;
        
        for (MXEvent *event in outgoingMsgs)
        {
            if (event.sentState == MXEventSentStateFailed)
            {
                hasUnsent = YES;
                
                // Check if the error is due to unknown devices
                if ([event.sentError.domain isEqualToString:MXEncryptingErrorDomain]
                    && event.sentError.code == MXEncryptingErrorUnknownDeviceCode)
                {
                    hasUnsentDueToUnknownDevices = YES;
                    break;
                }
            }
        }
        
        if (hasUnsent)
        {
            NSString *notification = hasUnsentDueToUnknownDevices ?
            NSLocalizedStringFromTableInBundle(@"room_unsent_messages_unknown_devices_notification", @"Vector",[NSBundle bundleForClass:[self class]], nil) :
            NSLocalizedStringFromTableInBundle(@"room_unsent_messages_notification", @"Vector",[NSBundle bundleForClass:[self class]], nil);
            
            RoomActivitiesView *roomActivitiesView = (RoomActivitiesView*) self.activitiesView;
            [roomActivitiesView displayUnsentMessagesNotification:notification withResendLink:^{
                
                [self resendAllUnsentMessages];
                
            } andCancelLink:^{
                
                [self cancelAllUnsentMessages];
                
            } andIconTapGesture:^{
                
                if (currentAlert)
                {
                    [currentAlert dismissViewControllerAnimated:NO completion:nil];
                }
                
                __weak __typeof(self) weakSelf = self;
                currentAlert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"room_resend_unsent_messages", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       [self resendAllUnsentMessages];
                                                                       self->currentAlert = nil;
                                                                   }
                                                                   
                                                               }]];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"room_delete_unsent_messages", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       [self cancelAllUnsentMessages];
                                                                       self->currentAlert = nil;
                                                                   }
                                                                   
                                                               }]];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"cancel", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                                 style:UIAlertActionStyleCancel
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       self->currentAlert = nil;
                                                                   }
                                                                   
                                                               }]];
                
                [currentAlert mxk_setAccessibilityIdentifier:@"RoomVCUnsentMessagesMenuAlert"];
                [currentAlert popoverPresentationController].sourceView = roomActivitiesView;
                [currentAlert popoverPresentationController].sourceRect = roomActivitiesView.bounds;
                [self presentViewController:currentAlert animated:YES completion:nil];
                
            }];
        }
    }
    
    return hasUnsent;
}

- (void)eventDidChangeIdentifier:(NSNotification *)notif
{
    MXEvent *event = notif.object;
    NSString *previousId = notif.userInfo[kMXEventIdentifierKey];

    if ([customizedRoomDataSource.selectedEventId isEqualToString:previousId])
    {
        NSLog(@"[RoomVC] eventDidChangeIdentifier: Update selectedEventId");
        customizedRoomDataSource.selectedEventId = event.eventId;
    }
}


- (void)resendAllUnsentMessages
{
    // List unsent event ids
    NSArray *outgoingMsgs = self.roomDataSource.room.outgoingMessages;
    NSMutableArray *failedEventIds = [NSMutableArray arrayWithCapacity:outgoingMsgs.count];
    
    for (MXEvent *event in outgoingMsgs)
    {
        if (event.sentState == MXEventSentStateFailed)
        {
            [failedEventIds addObject:event.eventId];
        }
    }
    
    // Launch iterative operation
    [self resendFailedEvent:0 inArray:failedEventIds];
}

- (void)resendFailedEvent:(NSUInteger)index inArray:(NSArray*)failedEventIds
{
    if (index < failedEventIds.count)
    {
        NSString *failedEventId = failedEventIds[index];
        NSUInteger nextIndex = index + 1;
        
        // Let the datasource resend. It will manage local echo, etc.
        [self.roomDataSource resendEventWithEventId:failedEventId success:^(NSString *eventId) {
            
            [self resendFailedEvent:nextIndex inArray:failedEventIds];
            
        } failure:^(NSError *error) {
            
            [self resendFailedEvent:nextIndex inArray:failedEventIds];
            
        }];
        
        return;
    }
    
    // Refresh activities view
    [self refreshActivitiesViewDisplay];
}

- (void)cancelAllUnsentMessages
{
    // Remove unsent event ids
    for (NSUInteger index = 0; index < self.roomDataSource.room.outgoingMessages.count;)
    {
        MXEvent *event = self.roomDataSource.room.outgoingMessages[index];
        if (event.sentState == MXEventSentStateFailed)
        {
            [self.roomDataSource removeEventWithEventId:event.eventId];
        }
        else
        {
            index ++;
        }
    }
}




#pragma mark - Read marker handling

- (void)checkReadMarkerVisibility
{
    if (readMarkerTableViewCell && isAppeared && !self.isBubbleTableViewDisplayInTransition)
    {
        // Check whether the read marker is visible
        CGFloat contentTopPosY = self.bubblesTableView.contentOffset.y + self.bubblesTableView.mxk_adjustedContentInset.top;
        CGFloat readMarkerViewPosY = readMarkerTableViewCell.frame.origin.y + readMarkerTableViewCell.readMarkerView.frame.origin.y;
        if (contentTopPosY <= readMarkerViewPosY)
        {
            // Compute the max vertical position visible according to contentOffset
            CGFloat contentBottomPosY = self.bubblesTableView.contentOffset.y + self.bubblesTableView.frame.size.height - self.bubblesTableView.mxk_adjustedContentInset.bottom;
            if (readMarkerViewPosY <= contentBottomPosY)
            {
                // Launch animation
                [self animateReadMarkerView];
                
                // Disable the read marker display when it has been rendered once.
                self.roomDataSource.showReadMarker = NO;
                [self refreshJumpToLastUnreadBannerDisplay];
                
                // Update the read marker position according the events acknowledgement in this view controller.
                self.updateRoomReadMarker = YES;
                
                if (self.roomDataSource.isLive)
                {
                    // Move the read marker to the current read receipt position.
                    [self.roomDataSource.room forgetReadMarker];
                }
            }
        }
    }
}

- (void)animateReadMarkerView
{
    // Check whether the cell with the read marker is known and if the marker is not animated yet.
    if (readMarkerTableViewCell && readMarkerTableViewCell.readMarkerView.isHidden)
    {
        RoomBubbleCellData *cellData = (RoomBubbleCellData*)readMarkerTableViewCell.bubbleData;
        
        // Do not display the marker if this is the last message.
        if (cellData.containsLastMessage && readMarkerTableViewCell.readMarkerView.tag == cellData.mostRecentComponentIndex)
        {
            readMarkerTableViewCell.readMarkerView.hidden = YES;
            readMarkerTableViewCell = nil;
        }
        else
        {
            readMarkerTableViewCell.readMarkerView.hidden = NO;
            
            // Animate the layout to hide the read marker
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [UIView animateWithDuration:1.5 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                                 animations:^{
                                     
                                     readMarkerTableViewCell.readMarkerViewLeadingConstraint.constant = readMarkerTableViewCell.readMarkerViewTrailingConstraint.constant = readMarkerTableViewCell.bubbleOverlayContainer.frame.size.width / 2;
                                     readMarkerTableViewCell.readMarkerView.alpha = 0;
                                     
                                     // Force to render the view
                                     [readMarkerTableViewCell.bubbleOverlayContainer layoutIfNeeded];
                                     
                                 }
                                 completion:^(BOOL finished){
                                     
                                     readMarkerTableViewCell.readMarkerView.hidden = YES;
                                     readMarkerTableViewCell.readMarkerView.alpha = 1;
                                     
                                     readMarkerTableViewCell = nil;
                                 }];
                
            });
        }
    }
}

- (void)refreshJumpToLastUnreadBannerDisplay
{
    // This banner is only displayed when the room timeline is in live (and no peeking).
    // Check whether the read marker exists and has not been rendered yet.
    if (self.roomDataSource.isLive && !self.roomDataSource.isPeeking && self.roomDataSource.showReadMarker && self.roomDataSource.room.accountData.readMarkerEventId)
    {
        UITableViewCell *cell = [self.bubblesTableView visibleCells].firstObject;
        if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
        {
            MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell*)cell;
            // Check whether the read marker is inside the first displayed cell.
            if (roomBubbleTableViewCell.readMarkerView)
            {
                // The read marker display is still enabled (see roomDataSource.showReadMarker flag),
                // this means the read marker was not been visible yet.
                // We show the banner if the marker is located in the top hidden part of the cell.
                CGFloat contentTopPosY = self.bubblesTableView.contentOffset.y + self.bubblesTableView.mxk_adjustedContentInset.top;
                CGFloat readMarkerViewPosY = roomBubbleTableViewCell.frame.origin.y + roomBubbleTableViewCell.readMarkerView.frame.origin.y;
                self.jumpToLastUnreadBannerContainer.hidden = (contentTopPosY < readMarkerViewPosY);
            }
            else
            {
                // Check whether the read marker event is anterior to the first event displayed in the first rendered cell.
                MXKRoomBubbleComponent *component = roomBubbleTableViewCell.bubbleData.bubbleComponents.firstObject;
                MXEvent *firstDisplayedEvent = component.event;
                MXEvent *currentReadMarkerEvent = [self.roomDataSource.mxSession.store eventWithEventId:self.roomDataSource.room.accountData.readMarkerEventId inRoom:self.roomDataSource.roomId];
                
                if (!currentReadMarkerEvent || (currentReadMarkerEvent.originServerTs < firstDisplayedEvent.originServerTs))
                {
                    self.jumpToLastUnreadBannerContainer.hidden = NO;
                }
                else
                {
                    self.jumpToLastUnreadBannerContainer.hidden = YES;
                }
            }
        }
    }
    else
    {
        self.jumpToLastUnreadBannerContainer.hidden = YES;
        
        // Initialize the read marker if it does not exist yet, only in case of live timeline.
        if (!self.roomDataSource.room.accountData.readMarkerEventId && self.roomDataSource.isLive && !self.roomDataSource.isPeeking)
        {
            // Move the read marker to the current read receipt position by default.
            [self.roomDataSource.room forgetReadMarker];
        }
    }
}


#pragma mark - Re-request encryption keys

- (void)reRequestKeysAndShowExplanationAlert:(MXEvent*)event
{
    MXWeakify(self);
    __block UIAlertController *alert;

    // Make the re-request
    [self.mainSession.crypto reRequestRoomKeyForEvent:event];

    // Observe kMXEventDidDecryptNotification to remove automatically the dialog
    // if the user has shared the keys from another device
    mxEventDidDecryptNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXEventDidDecryptNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        MXStrongifyAndReturnIfNil(self);

        MXEvent *decryptedEvent = notif.object;

        if ([decryptedEvent.eventId isEqualToString:event.eventId])
        {
            [[NSNotificationCenter defaultCenter] removeObserver:self->mxEventDidDecryptNotificationObserver];
            self->mxEventDidDecryptNotificationObserver = nil;

            if (self->currentAlert == alert)
            {
                [self->currentAlert dismissViewControllerAnimated:YES completion:nil];
                self->currentAlert = nil;
            }
        }
    }];

    // Show the explanation dialog
    alert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"rerequest_keys_alert_title", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                       message:NSLocalizedStringFromTableInBundle(@"rerequest_keys_alert_message", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                preferredStyle:UIAlertControllerStyleAlert];
    currentAlert = alert;


    [alert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action)
                             {
                                 MXStrongifyAndReturnIfNil(self);

                                 [[NSNotificationCenter defaultCenter] removeObserver:self->mxEventDidDecryptNotificationObserver];
                                 self->mxEventDidDecryptNotificationObserver = nil;

                                 self->currentAlert = nil;
                             }]];

    [self presentViewController:currentAlert animated:YES completion:nil];
}

#pragma mark Tombstone event

- (void)listenTombstoneEventNotifications
{
    // Room is already obsolete do not listen to tombstone event
    if (self.roomDataSource.roomState.isObsolete)
    {
        return;
    }
    
    MXWeakify(self);
    
    tombstoneEventNotificationsListener = [self.roomDataSource.room listenToEventsOfTypes:@[kMXEventTypeStringRoomTombStone] onEvent:^(MXEvent *event, MXTimelineDirection direction, MXRoomState *roomState) {
        
        MXStrongifyAndReturnIfNil(self);
        
        // Update activitiesView with room replacement information
        [self refreshActivitiesViewDisplay];
        // Hide inputToolbarView
        [self updateRoomInputToolbarViewClassIfNeeded];
    }];
}

- (void)removeTombstoneEventNotificationsListener
{
    if (self.roomDataSource)
    {
        // Remove the previous live listener
        if (tombstoneEventNotificationsListener)
        {
            [self.roomDataSource.room removeListener:tombstoneEventNotificationsListener];
            tombstoneEventNotificationsListener = nil;
        }
    }
}

#pragma mark MXSession state change

- (void)listenMXSessionStateChangeNotifications
{
    kMXSessionStateDidChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionStateDidChangeNotification object:self.roomDataSource.mxSession queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

        if (self.roomDataSource.mxSession.state == MXSessionStateSyncError
            || self.roomDataSource.mxSession.state == MXSessionStateRunning)
        {
            [self refreshActivitiesViewDisplay];

            // update inputToolbarView
            [self updateRoomInputToolbarViewClassIfNeeded];
        }
    }];
}

- (void)removeMXSessionStateChangeNotificationsListener
{
    if (kMXSessionStateDidChangeObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kMXSessionStateDidChangeObserver];
        kMXSessionStateDidChangeObserver = nil;
    }
}

#pragma mark - Contextual Menu

- (NSArray<RoomContextualMenuItem*>*)contextualMenuItemsForEvent:(MXEvent*)event andCell:(id<MXKCellRendering>)cell
{
    NSString *eventId = event.eventId;
    MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell *)cell;
    MXKAttachment *attachment = roomBubbleTableViewCell.bubbleData.attachment;
    
    MXWeakify(self);
    
    // Copy action
    
    RoomContextualMenuItem *copyMenuItem = [[RoomContextualMenuItem alloc] initWithMenuAction:RoomContextualMenuActionCopy];
    copyMenuItem.isEnabled = !attachment || attachment.type != MXKAttachmentTypeSticker;
    copyMenuItem.action = ^{
        MXStrongifyAndReturnIfNil(self);
        
        if (!attachment)
        {
            NSArray *components = roomBubbleTableViewCell.bubbleData.bubbleComponents;
            MXKRoomBubbleComponent *selectedComponent;
            for (selectedComponent in components)
            {
                if ([selectedComponent.event.eventId isEqualToString:event.eventId])
                {
                    break;
                }
                selectedComponent = nil;
            }
            NSString *textMessage = selectedComponent.textMessage;
            
            [UIPasteboard generalPasteboard].string = textMessage;
            
            [self hideContextualMenuAnimated:YES];
        }
        else if (attachment.type != MXKAttachmentTypeSticker)
        {
            [self hideContextualMenuAnimated:YES completion:^{
                [self startActivityIndicator];
                
                [attachment copy:^{
                    
                    [self stopActivityIndicator];
                    
                } failure:^(NSError *error) {
                    
                    [self stopActivityIndicator];
                    
                    //Alert user
                    [[LucUtility instance] showErrorAsAlert:error];
                }];
                
                // Start animation in case of download during attachment preparing
                [roomBubbleTableViewCell startProgressUI];
            }];
        }
    };
    
    // Reply action
    
    RoomContextualMenuItem *replyMenuItem = [[RoomContextualMenuItem alloc] initWithMenuAction:RoomContextualMenuActionReply];
    replyMenuItem.isEnabled = [self.roomDataSource canReplyToEventWithId:eventId];
    replyMenuItem.action = ^{
        MXStrongifyAndReturnIfNil(self);
        
        [self hideContextualMenuAnimated:YES cancelEventSelection:NO completion:nil];
        [self selectEventWithId:eventId inputToolBarSendMode:RoomInputToolbarViewSendModeReply showTimestamp:NO];

        // And display the keyboard
        [self.inputToolbarView becomeFirstResponder];
    };
    
    // Edit action
    
    RoomContextualMenuItem *editMenuItem = [[RoomContextualMenuItem alloc] initWithMenuAction:RoomContextualMenuActionEdit];
    editMenuItem.action = ^{
        MXStrongifyAndReturnIfNil(self);
        [self hideContextualMenuAnimated:YES cancelEventSelection:NO completion:nil];
        [self editEventContentWithId:eventId];

        // And display the keyboard
        [self.inputToolbarView becomeFirstResponder];
    };
    
    editMenuItem.isEnabled = [self.roomDataSource canEditEventWithId:eventId];
    
    // More action
    
    RoomContextualMenuItem *moreMenuItem = [[RoomContextualMenuItem alloc] initWithMenuAction:RoomContextualMenuActionMore];
    moreMenuItem.action = ^{
        MXStrongifyAndReturnIfNil(self);
        [self hideContextualMenuAnimated:YES completion:nil];
        [self showAdditionalActionsMenuForEvent:event inCell:cell animated:YES];
    };
    
    // Actions list
    
    NSArray<RoomContextualMenuItem*> *actionItems = @[
                                                      copyMenuItem,
                                                      replyMenuItem,
                                                      editMenuItem,
                                                      moreMenuItem
                                                      ];
    
    return actionItems;
}

- (void)showContextualMenuForEvent:(MXEvent*)event fromSingleTapGesture:(BOOL)usedSingleTapGesture cell:(id<MXKCellRendering>)cell animated:(BOOL)animated
{
    if (self.roomContextualMenuPresenter.isPresenting)
    {
        return;
    }
    
    NSString *selectedEventId = event.eventId;
    
    NSArray<RoomContextualMenuItem*>* contextualMenuItems = [self contextualMenuItemsForEvent:event andCell:cell];
    ReactionsMenuViewModel *reactionsMenuViewModel;
    CGRect bubbleComponentFrameInOverlayView = CGRectNull;
    
    if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class] && [self.roomDataSource canReactToEventWithId:event.eventId])
    {
        MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell*)cell;
        MXKRoomBubbleCellData *bubbleCellData = roomBubbleTableViewCell.bubbleData;
        NSArray *bubbleComponents = bubbleCellData.bubbleComponents;
        
        NSInteger foundComponentIndex = [bubbleCellData bubbleComponentIndexForEventId:event.eventId];
        CGRect bubbleComponentFrame;
        
        if (bubbleComponents.count > 0)
        {
            NSInteger selectedComponentIndex = foundComponentIndex != NSNotFound ? foundComponentIndex : 0;
            bubbleComponentFrame = [roomBubbleTableViewCell surroundingFrameInTableViewForComponentIndex:selectedComponentIndex];
        }
        else
        {
            bubbleComponentFrame = roomBubbleTableViewCell.frame;
        }
        
        bubbleComponentFrameInOverlayView = [self.bubblesTableView convertRect:bubbleComponentFrame toView:self.overlayContainerView];
        
        NSString *roomId = self.roomDataSource.roomId;
        MXAggregations *aggregations = self.mainSession.aggregations;
        MXAggregatedReactions *aggregatedReactions = [aggregations aggregatedReactionsOnEvent:selectedEventId inRoom:roomId];
        
        reactionsMenuViewModel = [[ReactionsMenuViewModel alloc] initWithAggregatedReactions:aggregatedReactions eventId:selectedEventId];
        reactionsMenuViewModel.coordinatorDelegate = self;
    }
    
    if (!self.roomContextualMenuViewController)
    {
        self.roomContextualMenuViewController = [RoomContextualMenuViewController instantiate];
        self.roomContextualMenuViewController.delegate = self;
    }
    
    [self.roomContextualMenuViewController updateWithContextualMenuItems:contextualMenuItems reactionsMenuViewModel:reactionsMenuViewModel];
    
    [self enableOverlayContainerUserInteractions:YES];
    
    [self.roomContextualMenuPresenter presentWithRoomContextualMenuViewController:self.roomContextualMenuViewController
                                                                             from:self
                                                                               on:self.overlayContainerView
                                                              contentToReactFrame:bubbleComponentFrameInOverlayView
                                                             fromSingleTapGesture:usedSingleTapGesture
                                                                         animated:animated
                                                                       completion:^{
                                                                       }];
    
    [self selectEventWithId:selectedEventId];
}

- (void)hideContextualMenuAnimated:(BOOL)animated
{
    [self hideContextualMenuAnimated:animated completion:nil];
}

- (void)hideContextualMenuAnimated:(BOOL)animated completion:(void(^)(void))completion
{
    [self hideContextualMenuAnimated:animated cancelEventSelection:YES completion:completion];
}

- (void)hideContextualMenuAnimated:(BOOL)animated cancelEventSelection:(BOOL)cancelEventSelection completion:(void(^)(void))completion
{
    if (!self.roomContextualMenuPresenter.isPresenting)
    {
        return;
    }
    
    if (cancelEventSelection)
    {
        [self cancelEventSelection];
    }
    
    [self.roomContextualMenuPresenter hideContextualMenuWithAnimated:animated completion:^{
        [self enableOverlayContainerUserInteractions:NO];
        
        if (completion)
        {
            completion();
        }
    }];
}

- (void)enableOverlayContainerUserInteractions:(BOOL)enableOverlayContainerUserInteractions
{
    self.inputToolbarView.editable = !enableOverlayContainerUserInteractions;
    self.bubblesTableView.scrollsToTop = !enableOverlayContainerUserInteractions;
    self.overlayContainerView.userInteractionEnabled = enableOverlayContainerUserInteractions;
}

#pragma mark - RoomContextualMenuViewControllerDelegate

- (void)roomContextualMenuViewControllerDidTapBackgroundOverlay:(RoomContextualMenuViewController *)viewController
{
    [self hideContextualMenuAnimated:YES];
}

#pragma mark - ReactionsMenuViewModelCoordinatorDelegate

- (void)reactionsMenuViewModel:(ReactionsMenuViewModel *)viewModel didAddReaction:(NSString *)reaction forEventId:(NSString *)eventId
{
    MXWeakify(self);
    
    [self hideContextualMenuAnimated:YES completion:^{
        
        [self.roomDataSource addReaction:reaction forEventId:eventId success:^{
            
        } failure:^(NSError *error) {
            MXStrongifyAndReturnIfNil(self);
            
            [self.errorPresenter presentErrorFromViewController:self forError:error animated:YES handler:nil];
        }];
    }];
}

- (void)reactionsMenuViewModel:(ReactionsMenuViewModel *)viewModel didRemoveReaction:(NSString *)reaction forEventId:(NSString *)eventId
{
    MXWeakify(self);
    
    [self hideContextualMenuAnimated:YES completion:^{
        
        [self.roomDataSource removeReaction:reaction forEventId:eventId success:^{
            
        } failure:^(NSError *error) {
            MXStrongifyAndReturnIfNil(self);
            
            [self.errorPresenter presentErrorFromViewController:self forError:error animated:YES handler:nil];
        }];
        
    }];
}

- (void)reactionsMenuViewModelDidTapMoreReactions:(ReactionsMenuViewModel *)viewModel forEventId:(NSString *)eventId
{
    [self hideContextualMenuAnimated:YES];
    
    EmojiPickerCoordinatorBridgePresenter *emojiPickerCoordinatorBridgePresenter = [[EmojiPickerCoordinatorBridgePresenter alloc] initWithSession:self.mainSession roomId:self.roomDataSource.roomId eventId:eventId];
    emojiPickerCoordinatorBridgePresenter.delegate = self;
    
    NSInteger cellRow = [self.roomDataSource indexOfCellDataWithEventId:eventId];
    
    UIView *sourceView;
    CGRect sourceRect = CGRectNull;
    
    if (cellRow >= 0)
    {
        NSIndexPath *cellIndexPath = [NSIndexPath indexPathForRow:cellRow inSection:0];        
        UITableViewCell *cell = [self.bubblesTableView cellForRowAtIndexPath:cellIndexPath];
        sourceView = cell;
        
        if ([cell isKindOfClass:[MXKRoomBubbleTableViewCell class]])
        {
            MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell*)cell;
            NSInteger bubbleComponentIndex = [roomBubbleTableViewCell.bubbleData bubbleComponentIndexForEventId:eventId];
            sourceRect = [roomBubbleTableViewCell componentFrameInContentViewForIndex:bubbleComponentIndex];
        }
        
    }
    
    [emojiPickerCoordinatorBridgePresenter presentFrom:self sourceView:sourceView sourceRect:sourceRect animated:YES];
    self.emojiPickerCoordinatorBridgePresenter = emojiPickerCoordinatorBridgePresenter;
}

#pragma mark -

- (void)showEditHistoryForEventId:(NSString*)eventId animated:(BOOL)animated
{
    MXEvent *event = [self.roomDataSource eventWithEventId:eventId];
    EditHistoryCoordinatorBridgePresenter *presenter = [[EditHistoryCoordinatorBridgePresenter alloc] initWithSession:self.roomDataSource.mxSession event:event];
    
    presenter.delegate = self;
    [presenter presentFrom:self animated:animated];
    
    self.editHistoryPresenter = presenter;
}

#pragma mark - EditHistoryCoordinatorBridgePresenterDelegate

- (void)editHistoryCoordinatorBridgePresenterDelegateDidComplete:(EditHistoryCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.editHistoryPresenter = nil;
}

#pragma mark - DocumentPickerPresenterDelegate

- (void)documentPickerPresenterWasCancelled:(MXKDocumentPickerPresenter *)presenter
{
    self.documentPickerPresenter = nil;
}

- (void)documentPickerPresenter:(MXKDocumentPickerPresenter *)presenter didPickDocumentsAt:(NSURL *)url
{
    self.documentPickerPresenter = nil;
    
    MXKUTI *fileUTI = [[MXKUTI alloc] initWithLocalFileURL:url];
    NSString *mimeType = fileUTI.mimeType;
    
    if (fileUTI.isImage)
    {
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:url];
        
        [self.roomDataSource sendImage:imageData mimeType:mimeType success:nil failure:^(NSError *error) {
            // Nothing to do. The image is marked as unsent in the room history by the datasource
            NSLog(@"[MXKRoomViewController] sendImage failed.");
        }];
    }
    else if (fileUTI.isVideo)
    {
        [(RoomDataSource*)self.roomDataSource sendVideo:url success:nil failure:^(NSError *error) {
            // Nothing to do. The video is marked as unsent in the room history by the datasource
            NSLog(@"[MXKRoomViewController] sendVideo failed.");
        }];
    }
    else if (fileUTI.isFile)
    {
        [self.roomDataSource sendFile:url mimeType:mimeType success:nil failure:^(NSError *error) {
            // Nothing to do. The file is marked as unsent in the room history by the datasource
            NSLog(@"[MXKRoomViewController] sendFile failed.");
        }];
    }
    else
    {
        NSLog(@"[MXKRoomViewController] File upload using MIME type %@ is not supported.", mimeType);
        
        [[LucUtility instance] showAlertWithTitle:NSLocalizedStringFromTableInBundle(@"file_upload_error_title", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                              message:NSLocalizedStringFromTableInBundle(@"file_upload_error_unsupported_file_type_message", @"Vector",[NSBundle bundleForClass:[self class]], nil)];
    }
}

#pragma mark - EmojiPickerCoordinatorBridgePresenterDelegate

- (void)emojiPickerCoordinatorBridgePresenter:(EmojiPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter didAddEmoji:(NSString *)emoji forEventId:(NSString *)eventId
{
    MXWeakify(self);
    
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        [self.roomDataSource addReaction:emoji forEventId:eventId success:^{
            
        } failure:^(NSError *error) {
            MXStrongifyAndReturnIfNil(self);
            
            [self.errorPresenter presentErrorFromViewController:self forError:error animated:YES handler:nil];
        }];
    }];
    self.emojiPickerCoordinatorBridgePresenter = nil;
}

- (void)emojiPickerCoordinatorBridgePresenter:(EmojiPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter didRemoveEmoji:(NSString *)emoji forEventId:(NSString *)eventId
{
    MXWeakify(self);
    
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        
        [self.roomDataSource removeReaction:emoji forEventId:eventId success:^{
            
        } failure:^(NSError *error) {
            MXStrongifyAndReturnIfNil(self);
            
            [self.errorPresenter presentErrorFromViewController:self forError:error animated:YES handler:nil];
        }];
    }];
    self.emojiPickerCoordinatorBridgePresenter = nil;
}

- (void)emojiPickerCoordinatorBridgePresenterDidCancel:(EmojiPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.emojiPickerCoordinatorBridgePresenter = nil;
}


#pragma mark - CameraPresenterDelegate

- (void)cameraPresenterDidCancel:(CameraPresenter *)cameraPresenter
{
    [cameraPresenter dismissWithAnimated:YES completion:nil];
    self.cameraPresenter = nil;
}

- (void)cameraPresenter:(CameraPresenter *)cameraPresenter didSelectImageData:(NSData *)imageData withUTI:(MXKUTI *)uti
{
    [cameraPresenter dismissWithAnimated:YES completion:nil];
    self.cameraPresenter = nil;
    
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    if (roomInputToolbarView)
    {
        [roomInputToolbarView sendSelectedImage:imageData withMimeType:uti.mimeType andCompressionMode:MXKRoomInputToolbarCompressionModePrompt isPhotoLibraryAsset:NO];
    }
}

- (void)cameraPresenter:(CameraPresenter *)cameraPresenter didSelectVideoAt:(NSURL *)url
{
    [cameraPresenter dismissWithAnimated:YES completion:nil];
    self.cameraPresenter = nil;
    
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    if (roomInputToolbarView)
    {
        [roomInputToolbarView sendSelectedVideo:url isPhotoLibraryAsset:NO];
    }
}

#pragma mark - MediaPickerCoordinatorBridgePresenterDelegate

- (void)mediaPickerCoordinatorBridgePresenterDidCancel:(MediaPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.mediaPickerPresenter = nil;
}

- (void)mediaPickerCoordinatorBridgePresenter:(MediaPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter didSelectImageData:(NSData *)imageData withUTI:(MXKUTI *)uti
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.mediaPickerPresenter = nil;
    
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    if (roomInputToolbarView)
    {
        [roomInputToolbarView sendSelectedImage:imageData withMimeType:uti.mimeType andCompressionMode:MXKRoomInputToolbarCompressionModePrompt isPhotoLibraryAsset:YES];
    }
}

- (void)mediaPickerCoordinatorBridgePresenter:(MediaPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter didSelectVideoAt:(NSURL *)url
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.mediaPickerPresenter = nil;
    
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    if (roomInputToolbarView)
    {
        [roomInputToolbarView sendSelectedVideo:url isPhotoLibraryAsset:YES];
    }
}

- (void)mediaPickerCoordinatorBridgePresenter:(MediaPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter didSelectAssets:(NSArray<PHAsset *> *)assets
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.mediaPickerPresenter = nil;
    
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    if (roomInputToolbarView)
    {
        [roomInputToolbarView sendSelectedAssets:assets withCompressionMode:MXKRoomInputToolbarCompressionModePrompt];
    }
}

@end

