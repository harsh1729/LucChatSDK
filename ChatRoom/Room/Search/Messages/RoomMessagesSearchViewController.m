/*
 
 Copyright 2018 Lintel 

 

 
 */

#import "RoomMessagesSearchViewController.h"

#import "RoomSearchViewController.h"

#import "UIViewController+LucSearch.h"

// Use RoomViewController cells to display results
#import "RoomBubbleCellData.h"
#import "RoomIncomingAttachmentBubbleCell.h"
#import "RoomIncomingTextMsgBubbleCell.h"

#import "LucChatSDK-Swift.h"
#import "ThemeService.h"
#import "LucUtility.h"
@interface RoomMessagesSearchViewController ()
{
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    id kAppDelegateDidTapStatusBarNotificationObserver;
    
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;
}

@end

@implementation RoomMessagesSearchViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Hide line separators of empty cells
    self.searchTableView.tableFooterView = [[UIView alloc] init];

    // Reuse cells from the RoomViewController to display results
    [self.searchTableView registerClass:RoomIncomingTextMsgBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgBubbleCell.defaultReuseIdentifier];
    [self.searchTableView registerClass:RoomIncomingAttachmentBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentBubbleCell.defaultReuseIdentifier];
    
    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    // Check the table view style to select its bg color.
    self.searchTableView.backgroundColor = ((self.searchTableView.style == UITableViewStylePlain) ? ThemeService.shared.theme.backgroundColor : ThemeService.shared.theme.headerBackgroundColor);
    self.view.backgroundColor = self.searchTableView.backgroundColor;
    self.searchTableView.separatorColor = ThemeService.shared.theme.lineBreakColor;
    
    self.noResultsLabel.textColor = ThemeService.shared.theme.backgroundColor;
    
    if (self.searchTableView.dataSource)
    {
        [self.searchTableView reloadData];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (void)destroy
{
    [super destroy];
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];


    // Observe kAppDelegateDidTapStatusBarNotificationObserver.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self.searchTableView setContentOffset:CGPointMake(-self.searchTableView.mxk_adjustedContentInset.left, -self.searchTableView.mxk_adjustedContentInset.top) animated:YES];
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (kAppDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateDidTapStatusBarNotificationObserver];
        kAppDelegateDidTapStatusBarNotificationObserver = nil;
    }
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    Class cellViewClass = nil;

    // Sanity check
    if ([cellData conformsToProtocol:@protocol(MXKRoomBubbleCellDataStoring)])
    {
        id<MXKRoomBubbleCellDataStoring> bubbleData = (id<MXKRoomBubbleCellDataStoring>)cellData;

        // Select the suitable table view cell class
        if (bubbleData.isAttachmentWithThumbnail)
        {
            cellViewClass = RoomIncomingAttachmentBubbleCell.class;
        }
        else
        {
            cellViewClass = RoomIncomingTextMsgBubbleCell.class;
        }
    }

    return cellViewClass;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    Class class = [self cellViewClassForCellData:cellData];

    if ([class respondsToSelector:@selector(defaultReuseIdentifier)])
    {
        return [class defaultReuseIdentifier];
    }

    return nil;
}


#pragma mark - Override UITableView delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
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
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // `MXKRoomBubbleTableViewCell` cells displayed by the `RoomViewController`
    // do not have line separators.
    // The +1 here is for the line separator which is displayed by `RoomSearchViewController`.
    return [super tableView:tableView heightForRowAtIndexPath:indexPath] + 1;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Data in the cells are actually Vector RoomBubbleCellData
    RoomBubbleCellData *cellData = (RoomBubbleCellData*)[self.dataSource cellDataAtIndex:indexPath.row];
    _selectedEvent = cellData.bubbleComponents[0].event;
    
    // Hide the keyboard handled by the search text input which belongs to RoomSearchViewController
    [((RoomSearchViewController*)self.parentViewController).searchBar resignFirstResponder];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Make the RoomSearchViewController (that contains this VC) open the RoomViewController
    RoomSearchViewController *parentVC = self.parentViewController;
    
    if(parentVC){
        
        [parentVC showTimelineInRoomVC];
    }
    // Reset the selected event. RoomSearchViewController got it when here
    _selectedEvent = nil;
}

@end