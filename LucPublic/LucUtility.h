//
//  LucUtility.h
//  Luc
//
//  Created by HARSH VARDHAN on 12/09/19.
//  Copyright © 2019 Lintel.in. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MatrixKit/MatrixKit.h>
#import <UserNotifications/UserNotifications.h>
#import "LucMasterController.h"

#define CALL_STATUS_BAR_HEIGHT 44

extern NSString *const kAppDelegateDidTapStatusBarNotification;
extern NSString *const kAppDelegateNetworkStatusDidChangeNotification;






@interface LucUtility : NSObject<MXKCallViewControllerDelegate, UISplitViewControllerDelegate, UINavigationControllerDelegate, UNUserNotificationCenterDelegate>
{
    
}

@property (nonatomic) BOOL isPushRegistered;
@property (nonatomic) BOOL isAppForeground;
@property (nonatomic) BOOL isOffline;



/**
 Master controller
 */
@property (nonatomic, readonly) LucMasterController * _Nullable lucMasterController;

@property (strong, nonatomic) NSMutableArray * _Nullable mxSessionArray;
@property (nonatomic) NSMutableDictionary <NSNumber *, NSMutableArray <NSString *> *> * _Nullable incomingPushEventIds;

/**
 Call status window displayed when user goes back to app during a call.
 */
@property (nonatomic, readonly) UIWindow* _Nullable callStatusBarWindow;
@property (nonatomic, readonly) UIButton* _Nullable callStatusBarButton;
@property (strong, nonatomic) UIAlertController * _Nullable errorNotification;
//@property (strong, nonatomic) UIViewController * _Nullable rootViewController;

// Current selected room id. nil if no room is presently visible.
@property (strong, nonatomic) NSString * _Nullable visibleRoomId;

@property (strong, nonatomic) MXRestClient* mxRestClient;


/* App Delegate Lifecycle delgation methods */

- (void)luc_delegateWillFinishLaunching;
- (void)luc_delegateDidFinishLaunchingWithOptions:(NSDictionary *)launchOptions andApplication:(UIApplication *)application;
- (void)luc_delegateWillResignActive;
- (void)luc_delegateDidEnterBackground;
- (void)luc_delegateWillEnterForeground;
- (void)luc_delegateDidBecomeActive;
- (BOOL)luc_delegateContinueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler;

+ (LucUtility*_Nullable) instance;
- (void)launchBackgroundSync;

- (void)handleLimitedLocalNotifications:(MXSession*)mxSession events:(NSArray<NSString *> *)events;
//- (void)checkPendingRoomKeyRequests;
- (void)enableCallKit:(BOOL)enable forCallManager:(MXCallManager *)callManager;

- (void)enableNoVoIPOnMatrixSession:(MXSession*)mxSession;

- (void)addMatrixCallObserver;
- (void)enableLocalNotificationsFromMatrixSession:(MXSession*)mxSession;
- (void)enableInAppNotificationsForAccount:(MXKAccount*)account;
- (void)handleLocalNotificationsForAccount:(MXKAccount*)account;
- (void)refreshApplicationIconBadgeNumber;
- (void)handleLaunchAnimation;
- (void)refreshLocalContacts;
- (NSArray*)mxSessions;


/**
 Perform registration for remote notifications.
 
 @param completion the block to be executed when registration finished.
 */
- (void)registerForRemoteNotificationsWithCompletion:(void (^)(NSError *))completion;
// Add a matrix session.
- (void)addMatrixSession:(MXSession*)mxSession;

// Remove a matrix session.
- (void)removeMatrixSession:(MXSession*)mxSession;

// Mark all messages as read in the running matrix sessions.
- (void)markAllMessagesAsRead;

// Reload all running matrix sessions
- (void)reloadMatrixSessions:(BOOL)clearCache;

/**
 Log out all the accounts after asking for a potential confirmation.
 Show the authentication screen on successful logout.
 
 @param askConfirmation tell whether a confirmation is required before logging out.
 @param completion the block to execute at the end of the operation.
 */
- (void)logoutWithConfirmation:(BOOL)askConfirmation completion:(void (^)(BOOL isLoggedOut))completion;

/**
 Log out all the accounts without confirmation.
 Show the authentication screen on successful logout.
 
 @param sendLogoutRequest Indicate whether send logout request to homeserver.
 @param completion the block to execute at the end of the operation.
 */
- (void)logoutSendingRequestServer:(BOOL)sendLogoutServerRequest
                        completion:(void (^)(BOOL isLoggedOut))completion;


#pragma mark - Matrix Accounts handling

- (void)selectMatrixAccount:(void (^)(MXKAccount *selectedAccount))onSelection;

#pragma mark - Push notifications

- (void)registerUserNotificationSettings;


#pragma mark - Matrix Room handling

// Show a room and jump to the given event if event id is not nil otherwise go to last messages.
- (void)showRoom:(NSString*)roomId andEventId:(NSString*)eventId withMatrixSession:(MXSession*)mxSession restoreInitialDisplay:(BOOL)restoreInitialDisplay completion:(void (^)(void))completion;

- (void)showRoom:(NSString*)roomId andEventId:(NSString*)eventId withMatrixSession:(MXSession*)mxSession restoreInitialDisplay:(BOOL)restoreInitialDisplay;

- (void)showRoom:(NSString*)roomId andEventId:(NSString*)eventId withMatrixSession:(MXSession*)mxSession;

// Creates a new direct chat with the provided user id
- (void)createDirectChatWithUserId:(NSString*)userId completion:(void (^)(void))completion;

// Reopen an existing direct room with this userId or creates a new one (if it doesn't exist)
- (void)startDirectChatWithUserId:(NSString*)userId completion:(void (^)(void))completion;



- (UIAlertController*)showErrorAsAlert:(NSError*)error;

- (UIAlertController*)showAlertWithTitle:(NSString*)title message:(NSString*)message;

- (void)restoreInitialDisplay:(void (^)(void))completion;

- (void) luc_updateRESTClient:(NSString*)homeServerURL;

- (void)luc_loginChatServer:(NSString*)username withPassword:(NSString*)password completion:(void (^)(NSError* _Nullable error))completion;

-(void)setMasterControllerInstance:(LucMasterController*)masterController;
@end

