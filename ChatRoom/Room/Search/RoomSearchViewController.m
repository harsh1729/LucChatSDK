/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import "RoomSearchViewController.h"

#import "RoomMessagesSearchViewController.h"
#import "RoomSearchDataSource.h"

#import "RoomFilesViewController.h"

#import "LucChatSDK-Swift.h"
#import "FilesSearchCellData.h"
#import "ThemeService.h"
#import "RoomViewController.h"

@interface RoomSearchViewController ()
{
    RoomMessagesSearchViewController *messagesSearchViewController;
    RoomSearchDataSource *messagesSearchDataSource;
    
    RoomFilesViewController *filesSearchViewController;
    //FileSearchDataSource *filesSearchDataSource;
}

@end

@implementation RoomSearchViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    // The navigation bar tint color and the rageShake Manager are handled by super (see SegmentedViewController).
}

- (void)viewDidLoad
{
    // Set up the SegmentedVC tabs before calling [super viewDidLoad]
    NSMutableArray* viewControllers = [[NSMutableArray alloc] init];
    NSMutableArray* titles = [[NSMutableArray alloc] init];
    
    [titles addObject: NSLocalizedStringFromTableInBundle(@"search_messages", @"Vector",[NSBundle bundleForClass:[self class]], nil)];
    messagesSearchViewController = [RoomMessagesSearchViewController searchViewController];
    [viewControllers addObject:messagesSearchViewController];
    
    //HARSH change code to show all files of room instead of search
    // add Files tab
    [titles addObject: NSLocalizedStringFromTableInBundle(@"search_files", @"Vector",[NSBundle bundleForClass:[self class]], nil)];
    filesSearchViewController = [RoomFilesViewController roomViewController];
    MXSession* session = self.roomDataSource.mxSession;
    NSString* roomId = self.roomDataSource.roomId;
    
    __block MXKRoomDataSource *roomFilesDataSource;
    [MXKRoomDataSource loadRoomDataSourceWithRoomId:roomId andMatrixSession:session onComplete:^(id roomDataSource) {
        roomFilesDataSource = roomDataSource;
    }];
    roomFilesDataSource.filterMessagesWithURL = YES;
    [roomFilesDataSource finalizeInitialization];
    // Give the data source ownership to the room files view controller.
    filesSearchViewController.hasRoomDataSourceOwnership = YES;
    [filesSearchViewController displayRoom:roomFilesDataSource];

    
    [viewControllers addObject:filesSearchViewController];
    
    [self initWithTitles:titles viewControllers:viewControllers defaultSelected:0];
    
    [super viewDidLoad];
    
    // Add the Riot background image when search bar is empty
    //[self addBackgroundImageViewToView:self.view];
    
    // Initialize here the data sources if a matrix session has been already set.
    [self initializeDataSources];
    
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
   // self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    //self.navigationItem.leftItemsSupplementBackButton = YES;
    
    // Enable the search field by default at the screen opening
    if (self.searchBarHidden)
    {
        [self showSearch:NO];
    }
}

- (void)userInterfaceThemeDidChange
{
    [super userInterfaceThemeDidChange];
    
    UIImageView *backgroundImageView = self.backgroundImageView;
    if (backgroundImageView)
    {
        UIImage *image = [MXKTools paintImage:backgroundImageView.image withColor:ThemeService.shared.theme.matrixSearchBackgroundImageTintColor];
        backgroundImageView.image = image;
    }
}

- (void)destroy
{
    [super destroy];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Let's child display the loading not this view controller
    if (self.activityIndicator)
    {
        [self.activityIndicator stopAnimating];
        self.activityIndicator = nil;
    }

    
    self.navigationItem.hidesBackButton = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Refresh the search results.
    // Note: We wait for 'viewDidAppear' call to consider the actual view size during this update.
    [self updateSearch];
}

#pragma mark -

- (void)setRoomDataSource:(MXKRoomDataSource *)roomDataSource
{
    // Remove existing matrix session if any
    while (self.mainSession)
    {
        [self removeMatrixSession:self.mainSession];
    }
    
    _roomDataSource = roomDataSource;
    
    [self addMatrixSession:_roomDataSource.mxSession];
    
    // Check whether the controller's view is already loaded into memory.
    if (messagesSearchViewController)
    {
        // Prepare data sources
        [self initializeDataSources];
    }
}

- (void)initializeDataSources
{
    MXSession *mainSession = self.mainSession;
    
    if (mainSession && _roomDataSource)
    {
        // Init the search for messages
        messagesSearchDataSource = [[RoomSearchDataSource alloc] initWithRoomDataSource:_roomDataSource];
        [messagesSearchViewController displaySearch:messagesSearchDataSource];
        
        //Init the search for attachments
//        filesSearchDataSource = [[FileSearchDataSource alloc] initWithMatrixSession:mainSession];
//        filesSearchDataSource.roomEventFilter.rooms = @[_roomDataSource.roomId];
//        filesSearchDataSource.roomEventFilter.containsURL = YES;
//        filesSearchDataSource.shouldShowRoomDisplayName = NO;
//        [filesSearchDataSource registerCellDataClass:FilesSearchCellData.class forCellIdentifier:kMXKSearchCellDataIdentifier];
//        [filesSearchViewController displaySearch:filesSearchDataSource];
    }
}

#pragma mark - Override MXKViewController

- (void)setKeyboardHeight:(CGFloat)keyboardHeight
{
    [self setKeyboardHeightForBackgroundImage:keyboardHeight];
    
    [super setKeyboardHeight:keyboardHeight];
    
    [self checkAndShowBackgroundImage];
}

- (void)startActivityIndicator
{
    // Redirect the operation to the currently displayed VC
    // It is a MXKViewController or a MXKTableViewController. So it supports startActivityIndicator
    [self.selectedViewController performSelector:@selector(startActivityIndicator)];
}

- (void)stopActivityIndicator
{
    // The selected view controller mwy have changed since the call of [self startActivityIndicator]
    // So, stop the activity indicator for all children
    for (UIViewController *viewController in self.viewControllers)
    {
        [viewController performSelector:@selector(stopActivityIndicator)];
    }
}

#pragma mark - Override UIViewController+VectorSearch

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (!self.searchBar.text.length)
    {
        // Reset current search if any
        [self updateSearch];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
    if (self.selectedViewController == messagesSearchViewController || self.selectedViewController == filesSearchViewController)
    {
        // As the messages/files search is done homeserver-side, launch it only on the "Search" button
        [self updateSearch];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
    // Leave the screen
    [self.navigationController popViewControllerAnimated:YES]; 
    
    //searchBar.text = @"";
    //[self updateSearch];
}

- (void)setKeyboardHeightForBackgroundImage:(CGFloat)keyboardHeight
{
    [super setKeyboardHeightForBackgroundImage:keyboardHeight];
    
    if (keyboardHeight > 0)
    {
        [self checkAndShowBackgroundImage];
    }
}

// Check conditions before displaying the background
- (void)checkAndShowBackgroundImage
{
    
    self.backgroundImageView.hidden = YES;
    
    // Note: This background is hidden when keyboard is dismissed.
    // The other conditions depend on the current selected view controller.
//    if (self.selectedViewController == messagesSearchViewController)
//    {
//        self.backgroundImageView.hidden = ((messagesSearchDataSource.serverCount != 0) || !messagesSearchViewController.noResultsLabel.isHidden || (self.keyboardHeight == 0));
//    }
//    else if (self.selectedViewController == filesSearchViewController)
//    {
////        self.backgroundImageView.hidden = ((filesSearchDataSource.serverCount != 0) || !filesSearchViewController.noResultsLabel.isHidden || (self.keyboardHeight == 0));
//    }
//    else
//    {
//        self.backgroundImageView.hidden = (self.keyboardHeight == 0);
//    }
//
//    if (!self.backgroundImageView.hidden)
//    {
//        [self.backgroundImageView layoutIfNeeded];
//        [self.selectedViewController.view layoutIfNeeded];
//
//        // Check whether there is enough space to display this background
//        // For example, in landscape with the iPhone 5 & 6 screen size, the backgroundImageView must be hidden.
//        if (self.backgroundImageView.frame.origin.y < 0 || (self.selectedViewController.view.frame.size.height - self.backgroundImageViewBottomConstraint.constant) < self.backgroundImageView.frame.size.height)
//        {
//            self.backgroundImageView.hidden = YES;
//        }
//    }
}

#pragma mark - Override SegmentedViewController

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    [super setSelectedIndex:selectedIndex];
    
    if (self.selectedViewController == filesSearchViewController){
        
        self.searchBar.hidden = TRUE;
        [self.searchBar resignFirstResponder];
        
        self.navigationItem.hidesBackButton = NO;
        //self.navigationItem.titleView = nil;//self.searchInternals.backupTitleView;
        //self.navigationItem.leftBarButtonItem = self.searchInternals.backupLeftBarButtonItem;
        self.searchBar.text = @"";
        
    }else{
        self.searchBar.hidden = FALSE;
        self.navigationItem.hidesBackButton = NO;
        //self.navigationItem.titleView = self.searchBar;
    }
    
    [self updateSearch];
}

#pragma mark - Navigation

- (void)
showTimelineInRoomVC
{
    
    RoomViewController *roomViewController = [[RoomViewController alloc] initWithNibName: @"RoomViewController" bundle: [NSBundle bundleForClass:[RoomViewController class]]];
    
    
    // Check whether an event has been selected from messages or files search tab
    MXEvent *selectedSearchEvent = messagesSearchViewController.selectedEvent;
    MXSession *selectedSearchEventSession = messagesSearchDataSource.mxSession;
    if (!selectedSearchEvent)
    {
        //selectedSearchEvent = filesSearchViewController.selectedEvent;
        //selectedSearchEventSession = filesSearchDataSource.mxSession;
    }
    
    if (selectedSearchEvent)
    {

        [RoomDataSource loadRoomDataSourceWithRoomId:selectedSearchEvent.roomId
                                      initialEventId:selectedSearchEvent.eventId
                                    andMatrixSession:selectedSearchEventSession onComplete:^(RoomDataSource *roomDataSource) {

                                        [roomDataSource finalizeInitialization];
                                        roomDataSource.markTimelineInitialEvent = YES;

                                        [roomViewController displayRoom:roomDataSource];
                                        roomViewController.hasRoomDataSourceOwnership = YES;

                                        roomViewController.navigationItem.leftItemsSupplementBackButton = YES;
                                    }];
        
        
        [ self.navigationController pushViewController:(roomViewController)
                                              animated:true];
        
        // Hide back button title
        self.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    }
    
        
        
    
}

#pragma mark - Search

// Update search results under the currently selected tab
- (void)updateSearch
{
    
    if (self.searchBar.text.length)
    {
        self.backgroundImageView.hidden = YES;
        
        // Forward the search request to the data source
        if (self.selectedViewController == messagesSearchViewController)
        {
            // Launch the search only if the keyboard is no more visible
            if (!self.searchBar.isFirstResponder)
            {
                // Do it asynchronously to give time to messagesSearchViewController to be set up
                // so that it can display its loading wheel
                dispatch_async(dispatch_get_main_queue(), ^{
                    [messagesSearchDataSource searchMessages:self.searchBar.text force:NO];
                    messagesSearchViewController.shouldScrollToBottomOnRefresh = YES;
                    
                    
                    self.navigationItem.hidesBackButton = NO;
                });
            }
        }
        else if (self.selectedViewController == filesSearchViewController)
        {
            // Launch the search only if the keyboard is no more visible
            if (!self.searchBar.isFirstResponder)
            {
                // Do it asynchronously to give time to filesSearchViewController to be set up
                // so that it can display its loading wheel
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self->filesSearchDataSource searchMessages:self.searchBar.text force:NO];
//                    self->filesSearchViewController.shouldScrollToBottomOnRefresh = YES;
//                });
            }
        }
    }
    else
    {
        // Nothing to search - Reset search result (if any)
        if (messagesSearchDataSource.searchText.length)
        {
            [messagesSearchDataSource searchMessages:nil force:NO];
        }
        
        if (self.selectedViewController == filesSearchViewController){
            
            //if (filesSearchDataSource.searchText.length)
            //{
                //Harsh : show the search results
               // [filesSearchDataSource searchMessages:nil force:NO];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self->filesSearchDataSource searchMessages:@"im" force:NO];
//                self->filesSearchViewController.shouldScrollToBottomOnRefresh = YES;
//            });
            
            //}
        }
        
    }
    
    [self checkAndShowBackgroundImage];
}

@end
