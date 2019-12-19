/*
 Copyright 2018 Lintel 
 

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import "LucMasterController.h"



#import "MXRoom+Luc.h"
#import "MXSession+Luc.h"

#import "LucChatSDK-Swift.h"
#import "LucUtility.h"
#import "ThemeService.h"

@interface LucMasterController ()
{   
    
    // Tell whether the authentication screen is preparing.
    BOOL isAuthViewControllerPreparing;
    
   
    
    // The parameters to pass to the Authentification view controller.
    NSDictionary *authViewControllerRegistrationParameters;
    MXCredentials *softLogoutCredentials;
    
    
    
    
    // Current alert (if any).
    UIAlertController *currentAlert;
    
    // Keep reference on the pushed view controllers to release them correctly
    NSMutableArray *childViewControllers;
    
    
}

@property(nonatomic,getter=isHidden) BOOL hidden;

@end

@implementation LucMasterController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    childViewControllers = [NSMutableArray array];
    
    // Initialize here the data sources if a matrix session has been already set.
    [self initializeDataSources];
    
    
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Show the tab bar view controller content only when a user is logged in.
    self.hidden = ([MXKAccountManager sharedManager].accounts.count == 0);
    
    
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"[LucMasterController] viewDidAppear");
    [super viewDidAppear:animated];
    
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)dealloc
{
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    
    childViewControllers = nil;
}

#pragma mark -


- (void)initializeDataSources
{
    NSArray *mxSessionArray = [[LucUtility instance] mxSessions];
    
    MXSession *mainSession = mxSessionArray.firstObject;
    
    if (mainSession)
    {
        NSLog(@"[LucMasterController] initializeDataSources");
        
        // Init the recents data source
        _recentsDataSource = [[RecentsDataSource alloc] initWithMatrixSession:mainSession];
        
        // Restore the right delegate of the shared recent data source.
        id<MXKDataSourceDelegate> recentsDataSourceDelegate = self;
        RecentsDataSourceMode recentsDataSourceMode = RecentsDataSourceModeHome;
        
        [self.recentsDataSource setDelegate:recentsDataSourceDelegate andRecentsDataSourceMode:recentsDataSourceMode];
        
        
        // Check whether there are others sessions
        if (mxSessionArray.count > 1)
        {
            for (MXSession *mxSession in mxSessionArray)
            {
                if (mxSession != mainSession)
                {
                    // Add the session to the recents data source
                    [self.recentsDataSource addMatrixSession:mxSession];
                }
            }
        }
    }
}

- (void)addMatrixSession:(MXSession *)mxSession
{
    // Check whether the data sources have been initialized.
        if (!self.recentsDataSource)
        {
            
            // Prepare data sources and return
            [self initializeDataSources];
            return;
        }
        else
        {
            // Add the session to the existing data sources
            [self.recentsDataSource addMatrixSession:mxSession];
        }
    
    NSArray *mxSessionArray = [[LucUtility instance] mxSessions];
    
    // Add matrix sessions observer on first added session
    if (mxSessionArray.count == 1)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMatrixSessionStateDidChange:) name:kMXSessionStateDidChangeNotification object:nil];
    }
}

- (void)removeMatrixSession:(MXSession *)mxSession
{
    [self.recentsDataSource removeMatrixSession:mxSession];
    
    // Check whether there are others sessions
    if (!self.recentsDataSource.mxSessions.count)
    {
        // Remove matrix sessions observer
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionStateDidChangeNotification object:nil];
        
       
        
        [self.recentsDataSource destroy];
        _recentsDataSource = nil;
    }
    
}

- (void)onMatrixSessionStateDidChange:(NSNotification *)notif
{
    NSLog(@"onMatrixSessionStateDidChange");
}


- (void)selectRoomWithId:(NSString*)roomId andEventId:(NSString*)eventId inMatrixSession:(MXSession*)matrixSession
{
    [self selectRoomWithId:roomId andEventId:eventId inMatrixSession:matrixSession completion:nil];
}

- (void)selectRoomWithId:(NSString*)roomId andEventId:(NSString*)eventId inMatrixSession:(MXSession*)matrixSession completion:(void (^)(void))completion
{
    if (_selectedRoomId && [_selectedRoomId isEqualToString:roomId]
        && _selectedEventId && [_selectedEventId isEqualToString:eventId]
        && _selectedRoomSession && _selectedRoomSession == matrixSession)
    {
        // Nothing to do
        if (completion)
        {
            completion();
        }
        return;
    }
    
    _selectedRoomId = roomId;
    _selectedEventId = eventId;
    _selectedRoomSession = matrixSession;
    
    if (roomId && matrixSession)
    {
        // Preload the data source 
        MXWeakify(self);
        [self dataSourceOfRoomToDisplay:^(MXKRoomDataSource *roomDataSource) {
            MXStrongifyAndReturnIfNil(self);
            
            self->_selectedRoomDataSource = roomDataSource;
            
            self->_currentRoomViewController = [[RoomViewController alloc] initWithNibName: @"RoomViewController" bundle:[NSBundle bundleForClass:[RoomViewController class]]];
            
            
            
            
            
            if (self.navigationController){
                
                [self.navigationController pushViewController:self->_currentRoomViewController animated:true];
            }else{ //Present Modally
                
                
                [self presentViewController:self->_currentRoomViewController animated:true completion:nil];
            }
            
            
            
            [self.currentRoomViewController displayRoom:roomDataSource];
            
            //[self setupLeftBarButtonItem];
            
            
            if (completion)
            {
                completion();
            }
        }];
    }
    else
    {
        [self releaseSelectedItem];
        if (completion)
        {
            completion();
        }
    }
}




- (void)releaseSelectedItem
{
    _selectedRoomId = nil;
    _selectedEventId = nil;
    _selectedRoomSession = nil;
    _selectedRoomDataSource = nil;
    _selectedRoomPreviewData = nil;
    
    _selectedContact = nil;
    
    
    [self releaseCurrentDetailsViewController];
}


- (NSUInteger)missedDiscussionsCount
{
    NSUInteger roomCount = 0;
    
    NSArray *mxSessionArray = [[LucUtility instance] mxSessions];
    
    // Considering all the current sessions.
    for (MXSession *session in mxSessionArray)
    {
        roomCount += [session riot_missedDiscussionsCount];
    }
    
    return roomCount;
}

- (NSUInteger)missedHighlightDiscussionsCount
{
    NSUInteger roomCount = 0;
    
    NSArray *mxSessionArray = [[LucUtility instance] mxSessions];
    
    for (MXSession *session in mxSessionArray)
    {
        roomCount += [session missedHighlightDiscussionsCount];
    }
    
    return roomCount;
}


/**
 Load the data source of the room to open.

 @param onComplete a block providing the loaded room data source.
 */
- (void)dataSourceOfRoomToDisplay:(void (^)(MXKRoomDataSource *roomDataSource))onComplete
{
    
            // Open the room on the requested event
            [RoomDataSource loadRoomDataSourceWithRoomId:_selectedRoomId initialEventId:_selectedEventId andMatrixSession:_selectedRoomSession onComplete:^(id roomDataSource) {

                ((RoomDataSource*)roomDataSource).markTimelineInitialEvent = YES;

                // Give the data source ownership to the room view controller.
                self.currentRoomViewController.hasRoomDataSourceOwnership = YES;

                onComplete(roomDataSource);
            }];
    
}



- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion
{
    // Keep ref on presented view controller
    [childViewControllers addObject:viewControllerToPresent];
    
    [super presentViewController:viewControllerToPresent animated:flag completion:completion];
}


- (void)releaseCurrentDetailsViewController
{
    // Release the existing details view controller (if any).
    if (_currentRoomViewController)
    {
        // If the displayed data is not a preview, let the manager release the room data source
        // (except if the view controller has the room data source ownership).
        if (!_currentRoomViewController.roomPreviewData && _currentRoomViewController.roomDataSource && !_currentRoomViewController.hasRoomDataSourceOwnership)
        {
            MXSession *mxSession = _currentRoomViewController.roomDataSource.mxSession;
            MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:mxSession];
            
            // Let the manager release live room data sources where the user is in
            [roomDataSourceManager closeRoomDataSourceWithRoomId:_currentRoomViewController.roomDataSource.roomId forceClose:NO];
        }
        
        [_currentRoomViewController destroy];
        _currentRoomViewController = nil;
    }
    
}

- (void)setHidden:(BOOL)hidden
{
    _hidden = hidden;
    
    [self.view superview].backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.view.hidden = hidden;
    self.navigationController.navigationBar.hidden = hidden;
}


//- (void)displayList:(MXKRecentsDataSource *)listDataSource
//{
//    [super displayList:listDataSource];
//
//    // Change the table data source. It must be the home view controller itself.
//    self.recentsTableView.dataSource = self;
//
//    // Keep a ref on the recents data source
//    if ([listDataSource isKindOfClass:RecentsDataSource.class])
//    {
//        recentsDataSource = (RecentsDataSource*)listDataSource;
//    }
//}


//#pragma mark - MXKRecentListViewControllerDelegate
//
//- (void)recentListViewController:(MXKRecentListViewController *)recentListViewController didSelectRoom:(NSString *)roomId inMatrixSession:(MXSession *)matrixSession
//{
//    [self dispayRoomWithRoomId:roomId inMatrixSession:matrixSession];
//}

@end
