//
//  LucUtility.m
//  Luc
//
//  Created by HARSH VARDHAN on 12/09/19.
//  Copyright © 2019 Lintel.in. All rights reserved.
//

#import "LucUtility.h"
#import <PushKit/PushKit.h>
#import <LucChatSDK-Swift.h>
#import "CallViewController.h"

#import "MXSession+Luc.h"
#import "MXRoom+Luc.h"

#import <AudioToolbox/AudioToolbox.h>

#import <Contacts/Contacts.h>

#import "AFNetworkReachabilityManager.h"
#import <Intents/Intents.h>
#import "Tools.h"
#import "EventFormatter.h"
#import "ThemeService.h"
#import "WidgetManager.h"
#import <MatrixSDK/MXJingleCallStack.h>//
#import <MatrixSDK/MXUIKitBackgroundModeHandler.h>
#import "RoomDataSource.h"

/**
 Posted when the user taps the clock status bar.
 */
 NSString * _Nonnull const kAppDelegateDidTapStatusBarNotification = @"kAppDelegateDidTapStatusBarNotification";;

/**
 Posted when the property 'isOffline' has changed. This property is related to the network reachability status.
 */
 NSString * _Nonnull const kAppDelegateNetworkStatusDidChangeNotification = @"kAppDelegateNetworkStatusDidChangeNotification";;


@interface LucUtility() <PKPushRegistryDelegate>{
    
    /**
     The listeners to call events.
     There is one listener per MXSession.
     The key is an identifier of the MXSession. The value, the listener.
     */
    NSMutableDictionary *callEventsListeners;
    
    /**
     Currently displayed "Call not supported" alert.
     */
    UIAlertController *noCallSupportAlert;
    
    /**
     Account picker used in case of multiple account.
     */
    UIAlertController *accountPicker;
    
    /**
     Prompt to ask the user to log in again.
     */
    UIAlertController *cryptoDataCorruptedAlert;
    
    /**
     Prompt to warn the user about a new backup on the homeserver.
     */
    UIAlertController *wrongBackupVersionAlert;
    
    void (^popToHomeViewControllerCompletion)(void);
    
    /**
     Reachability observer
     */
    id reachabilityObserver;
    
    /**
     MatrixKit error observer
     */
    id matrixKitErrorObserver;
    
    /**
     matrix session observer used to detect new opened sessions.
     */
    id matrixSessionStateObserver;
    
    /**
     matrix account observers.
     */
    id addedAccountObserver;
    id removedAccountObserver;
    
    /**
     matrix call observer used to handle incoming/outgoing call.
     */
    id matrixCallObserver;
    
    /**
     The current call view controller (if any).
     */
    CallViewController *currentCallViewController;
    
    /**
     Incoming room key requests observers
     */
    id roomKeyRequestObserver;
    id roomKeyRequestCancellationObserver;
    
    
    
    NSMutableDictionary <NSNumber *, NSMutableArray <NSDictionary *> *> *eventsToNotify;
    
    /**
     The notification listener blocks.
     There is one block per MXSession.
     The key is an identifier of the MXSession. The value, the listener block.
     */
    NSMutableDictionary <NSNumber *, MXOnNotification> *notificationListenerBlocks;
    
    /**
     The launch animation container view
     */
    UIView *launchAnimationContainerView;
    NSDate *launchAnimationStart;
    
    
    /**
     Cache for payloads received with incoming push notifications.
     The key is the event id. The value, the payload.
     */
    NSMutableDictionary <NSString*, NSDictionary*> *incomingPushPayloads;
    
    
    /**
     Suspend the error notifications when the navigation stack of the root view controller is updating.
     */
    BOOL isErrorNotificationSuspended;
    
    
    
    
}



@property (strong, nonatomic) UIAlertController *logoutConfirmation;



@property (weak, nonatomic) UIAlertController *gdprConsentNotGivenAlertController;
@property (weak, nonatomic) UIViewController *gdprConsentController;

@property (strong, nonatomic) UIAlertController *mxInAppNotification;
@property (nonatomic, readonly) SystemSoundID messageSound;

@property (nonatomic, nullable, copy) void (^registrationForRemoteNotificationsCompletion)(NSError *);
@property (nonatomic, strong) PKPushRegistry *pushRegistry;


@end

static LucUtility *objLUC ;

@implementation LucUtility



#pragma mark UIApplicationDelegate lifecycle methods - STARTS

-(void) luc_delegateWillFinishLaunching
{
    // Create message sound
    NSURL *messageSoundURL = [[NSBundle mainBundle] URLForResource:@"message" withExtension:@"mp3"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)messageSoundURL, &_messageSound);
    
}

- (void)luc_delegateDidFinishLaunchingWithOptions:(NSDictionary *)launchOptions andApplication:(UIApplication *)application
{
    NSDate *startDate = [NSDate date];
    
    
    NSLog(@"------------------------------");
    NSLog(@"LUC Library info:");
    NSLog(@"MatrixKit version: %@", MatrixKitVersion);
    NSLog(@"MatrixSDK version: %@", MatrixSDKVersion);
    NSLog(@"------------------------------\n");
    [self setupUserDefaults];
    
    // Set up theme
    ThemeService.shared.themeId = LucSettings.shared.userInterfaceTheme;
    
    // Set up runtime language and fallback by considering the userDefaults object shared within the application group.
    NSUserDefaults *sharedUserDefaults = [MXKAppSettings standardAppSettings].sharedUserDefaults;
    NSString *language = [sharedUserDefaults objectForKey:@"appLanguage"];
    if (!language)
    {
        // Check whether a langage was only defined at the application level.
        language = [[NSUserDefaults standardUserDefaults] objectForKey:@"appLanguage"];
        if (language)
        {
            // Move this setting into the shared userDefaults object to apply it to the extensions.
            [sharedUserDefaults setObject:language forKey:@"appLanguage"];
            
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"appLanguage"];
        }
    }
    [NSBundle mxk_setLanguage:language];
    [NSBundle mxk_setFallbackLanguage:@"en"];
    
    
    // Customize the localized string table
    [NSBundle mxk_customizeLocalizedStringTableName:@"Vector"];
    
    self.mxSessionArray = [NSMutableArray array];
    callEventsListeners = [NSMutableDictionary dictionary];
    notificationListenerBlocks = [NSMutableDictionary dictionary];
    eventsToNotify = [NSMutableDictionary dictionary];
    incomingPushPayloads = [NSMutableDictionary dictionary];
    
    //HARSH: This gets initiated by main project implementing library
    _lucMasterController = nil;// [[LucMasterController alloc] init];
    
    
    _isAppForeground = NO;
    
    
    // Prepare Pushkit handling
    _incomingPushEventIds = [NSMutableDictionary dictionary];
    
    // Add matrix observers, and initialize matrix sessions if the app is not launched in background.
    [self initMatrixSessions];
    
    NSLog(@"[LUC] didFinishLaunchingWithOptions: Done in %.0fms", [[NSDate date] timeIntervalSinceDate:startDate] * 1000);
    
}



- (void)luc_delegateWillResignActive
{
    NSLog(@"[LUC] luc_delegateWillResignActive");
    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    // Release MatrixKit error observer
    if (matrixKitErrorObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:matrixKitErrorObserver];
        matrixKitErrorObserver = nil;
    }
    
    if (self.errorNotification)
    {
        [self.errorNotification dismissViewControllerAnimated:NO completion:nil];
        self.errorNotification = nil;
    }
    
    if (accountPicker)
    {
        [accountPicker dismissViewControllerAnimated:NO completion:nil];
        accountPicker = nil;
    }
    
    if (noCallSupportAlert)
    {
        [noCallSupportAlert dismissViewControllerAnimated:NO completion:nil];
        noCallSupportAlert = nil;
    }
    
    if (cryptoDataCorruptedAlert)
    {
        [cryptoDataCorruptedAlert dismissViewControllerAnimated:NO completion:nil];
        cryptoDataCorruptedAlert = nil;
    }
    
    if (wrongBackupVersionAlert)
    {
        [wrongBackupVersionAlert dismissViewControllerAnimated:NO completion:nil];
        wrongBackupVersionAlert = nil;
    }
}

- (void)luc_delegateDidEnterBackground
{
    NSLog(@"[LUC] luc_delegateDidEnterBackground");
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    // Stop reachability monitoring
    if (reachabilityObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:reachabilityObserver];
        reachabilityObserver = nil;
    }
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:nil];
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
    
    // check if some media must be released to reduce the cache size
    [MXMediaManager reduceCacheSizeToInsert:0];
    
    // Hide potential notification
    if (self.mxInAppNotification)
    {
        [self.mxInAppNotification dismissViewControllerAnimated:NO completion:nil];
        self.mxInAppNotification = nil;
    }
    
    
    // Suspend all running matrix sessions
    NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    for (MXKAccount *account in mxAccounts)
    {
        [account pauseInBackgroundTask];
    }
    
    // Refresh the notifications counter
    [self refreshApplicationIconBadgeNumber];
    
    _isAppForeground = NO;
    
}

- (void)luc_delegateWillEnterForeground
{
    NSLog(@"[LUC] luc_delegateWillEnterForeground");
    
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    // Flush all the pending push notifications.
    for (NSMutableArray *array in self.incomingPushEventIds.allValues)
    {
        [array removeAllObjects];
    }
    [incomingPushPayloads removeAllObjects];
    
    // Force each session to refresh here their publicised groups by user dictionary.
    // When these publicised groups are retrieved for a user, they are cached and reused until the app is backgrounded and enters in the foreground again
    for (MXSession *session in self.mxSessionArray)
    {
        [session markOutdatedPublicisedGroupsByUserData];
    }
    
    _isAppForeground = YES;
}

- (void)luc_delegateDidBecomeActive
{
    NSLog(@"[LUC] luc_delegateDidBecomeActive");
    
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    // Check if an initial sync failure occured while the app was in background
    MXSession *mainSession = self.mxSessions.firstObject;
    if (mainSession.state == MXSessionStateInitialSyncFailed)
    {
        // Inform the end user why the app appears blank
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                             code:NSURLErrorCannotConnectToHost
                                         userInfo:@{NSLocalizedDescriptionKey : NSLocalizedStringFromTableInBundle(@"homeserver_connection_lost", @"Vector",[NSBundle bundleForClass:[self class]], nil)}];
        
        [self showErrorAsAlert:error];
    }
    
    
    // Start monitoring reachability
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        // Check whether monitoring is ready
        if (status != AFNetworkReachabilityStatusUnknown)
        {
            if (status == AFNetworkReachabilityStatusNotReachable)
            {
                
                NSLog(@"%@",NSLocalizedStringFromTableInBundle(@"network_offline_prompt", @"Vector",[NSBundle bundleForClass:[self class]], nil) );
                
                NSLog(@"%@",NSLocalizedStringFromTableInBundle(@"network_offline_prompt", @"Vector",[NSBundle bundleForClass:[self class]], nil) );
                
                // Prompt user
                //Harsh: Don't prompt until we get approval from host app
                //[self showErrorAsAlert:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:@{NSLocalizedDescriptionKey : NSLocalizedStringFromTableInBundle(@"network_offline_prompt", @"Vector",[NSBundle bundleForClass:[self class]], nil)}]];
            }
            else
            {
                self.isOffline = NO;
            }
            
            // Use a dispatch to avoid to kill ourselves
            dispatch_async(dispatch_get_main_queue(), ^{
                [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:nil];
            });
        }
        
    }];
    
    //if ([[AFNetworkReachabilityManager sharedManager] isReachable]){
        
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    //}
    
    
    // Observe matrixKit error to alert user on error
    matrixKitErrorObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKErrorNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        [self showErrorAsAlert:note.object];
        
    }];
    
    // Observe crypto data storage corruption
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSessionCryptoDidCorruptData:) name:kMXSessionCryptoDidCorruptDataNotification object:nil];
    
    // Observe wrong backup version
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBackupStateDidChangeNotification:) name:kMXKeyBackupDidStateChangeNotification object:nil];
    
    // Resume all existing matrix sessions
    NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    for (MXKAccount *account in mxAccounts)
    {
        [account resume];
    }
    
    
    _isAppForeground = YES;
    
    
    [self handleLaunchAnimation];
}



- (BOOL)luc_delegateContinueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler
{
    BOOL continueUserActivity = NO;
    
    if ([userActivity.activityType isEqualToString:INStartAudioCallIntentIdentifier] ||
             [userActivity.activityType isEqualToString:INStartVideoCallIntentIdentifier])
    {
        INInteraction *interaction = userActivity.interaction;
        
        // roomID provided by Siri intent
        NSString *roomID = userActivity.userInfo[@"roomID"];
        
        // We've launched from calls history list
        if (!roomID)
        {
            INPerson *person;
            
            if ([interaction.intent isKindOfClass:INStartAudioCallIntent.class])
            {
                person = [[(INStartAudioCallIntent *)(interaction.intent) contacts] firstObject];
            }
            else if ([interaction.intent isKindOfClass:INStartVideoCallIntent.class])
            {
                person = [[(INStartVideoCallIntent *)(interaction.intent) contacts] firstObject];
            }
            
            roomID = person.personHandle.value;
        }
        
        BOOL isVideoCall = [userActivity.activityType isEqualToString:INStartVideoCallIntentIdentifier];
        
        UIApplication *application = UIApplication.sharedApplication;
        NSNumber *backgroundTaskIdentifier;
        
        // Start background task since we need time for MXSession preparasion because our app can be launched in the background
        if (application.applicationState == UIApplicationStateBackground)
            backgroundTaskIdentifier = @([application beginBackgroundTaskWithExpirationHandler:^{}]);
        
        MXSession *session = self.mxSessionArray.firstObject;
        [session.callManager placeCallInRoom:roomID
                                   withVideo:isVideoCall
                                     success:^(MXCall *call) {
                                         if (application.applicationState == UIApplicationStateBackground)
                                         {
                                             __weak NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
                                             __block id token =
                                             [center addObserverForName:kMXCallStateDidChange
                                                                 object:call
                                                                  queue:nil
                                                             usingBlock:^(NSNotification * _Nonnull note) {
                                                                 if (call.state == MXCallStateEnded)
                                                                 {
                                                                     [application endBackgroundTask:backgroundTaskIdentifier.unsignedIntegerValue];
                                                                     [center removeObserver:token];
                                                                 }
                                                             }];
                                         }
                                     }
                                     failure:^(NSError *error) {
                                         if (backgroundTaskIdentifier)
                                             [application endBackgroundTask:backgroundTaskIdentifier.unsignedIntegerValue];
                                     }];
        
        continueUserActivity = YES;
    }
    
    return continueUserActivity;
}




#pragma mark UIApplicationDelegate lifecycle methods - ENDS
#pragma mark ---------------------------------


#pragma mark Login Methods - STARTS

- (void) luc_updateRESTClient:(NSString*)homeServerURL  { //withServer:(NSString*)identityServer
    
    self.mxRestClient = [[MXRestClient alloc] initWithHomeServer:homeServerURL andOnUnrecognizedCertificateBlock:nil];
    
        
    self.mxRestClient.identityServer = @"";//HARSH: identityServer not needed;//https://vector.im""
    
}

- (void)luc_loginChatServer:(NSString*)username withPassword:(NSString*)password completion:(void (^)(NSError* _Nullable error))completion
{
    // Create param dictionary
    //HARSH: using email for login
    NSMutableDictionary *dictLoginCred = [[NSMutableDictionary alloc] init];
    
    NSMutableDictionary *childDictIdentifier = [[NSMutableDictionary alloc] init];
    
    /* LINTEL SERVER */
//    dictLoginCred[Luc_Constants.LOGIN_KEY_IDENTIFIER_USER] = username;
//    dictLoginCred[Luc_Constants.LOGIN_KEY_PASSWORD] = password;
//    dictLoginCred[Luc_Constants.LOGIN_KEY_TYPE] = @"m.login.password";
//    dictLoginCred[Luc_Constants.LOGIN_KEY_DEVICE] = @"Mobile";
//
//    childDictIdentifier[Luc_Constants.LOGIN_KEY_IDENTIFIER_USER] = username;
//    childDictIdentifier[Luc_Constants.LOGIN_KEY_IDENTIFIER_TYPE] = @"m.id.user";
//    dictLoginCred[Luc_Constants.LOGIN_KEY_IDENTIFIER] = childDictIdentifier;
    
    
    /* NEXT MOTION SERVER */
    dictLoginCred[Luc_Constants.LOGIN_KEY_IDENTIFIER_EMAIL_ADDRESS] = username;
    dictLoginCred[Luc_Constants.LOGIN_KEY_PASSWORD] = password;
    dictLoginCred[Luc_Constants.LOGIN_KEY_TYPE] = @"m.login.password";
    dictLoginCred[Luc_Constants.LOGIN_KEY_IDENTIFIER_MEDIUM] = @"email";
    dictLoginCred[Luc_Constants.LOGIN_KEY_DEVICE] = @"Mobile";
    
    
    childDictIdentifier[Luc_Constants.LOGIN_KEY_IDENTIFIER_TYPE] = @"m.id.thirdparty";
    childDictIdentifier[Luc_Constants.LOGIN_KEY_IDENTIFIER_MEDIUM] = @"email";
    childDictIdentifier[Luc_Constants.LOGIN_KEY_IDENTIFIER_EMAIL_ADDRESS] = username;
    dictLoginCred[Luc_Constants.LOGIN_KEY_IDENTIFIER] = childDictIdentifier;
    
    
    MXHTTPOperation *mxCurrentOperation = [self.mxRestClient login:dictLoginCred success:^(NSDictionary *JSONResponse) {
        
        MXLoginResponse *loginResponse;
        MXJSONModelSetMXJSONModel(loginResponse, MXLoginResponse, JSONResponse);
        
        MXCredentials *credentials = [[MXCredentials alloc] initWithLoginResponse:loginResponse
                                                            andDefaultCredentials:self->_mxRestClient.credentials];
        
        // Sanity check
        if (!credentials.userId || !credentials.accessToken)
        {
           NSLog(@"Credentials Sanity check Login Failed");
            
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"Credentials Sanity check Failed. Login is not successfull" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"LoginFailed" code:333 userInfo:details];
            
            completion(error);
         
        }
        else
        {
            NSLog(@"[LUCUtility] Login process succeeded");
            
            // Report the certificate trusted by user (if any)
            credentials.allowedCertificate = self->_mxRestClient.allowedCertificate;
            
            if ([[MXKAccountManager sharedManager] accountForUserId:credentials.userId])
            {
                //login_error_already_logged_in
                NSLog(@"[LUCUtility] login_error_already_logged_in");
            }
            else
            {
                // Report the new account in account manager
                MXKAccount *account = [[MXKAccount alloc] initWithCredentials:credentials];
                account.identityServerURL = self.mxRestClient.identityServer;
                
                [[MXKAccountManager sharedManager] addAccount:account andOpenSession:YES];
                
            }
            
            
            [[NSNotificationCenter defaultCenter] postNotificationName:Luc_Constants.OBSERVER_EVENT_KEY_LOGIN_SUCCESS object:nil];
            
            completion(nil);
            
        }
        
        
    } failure:^(NSError *error) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:Luc_Constants.OBSERVER_EVENT_KEY_LOGIN_FAILED object:nil];
        NSLog(@"Login Failed");
        
        completion(error);
        
    }];
    
    
}

#pragma mark Login methods - ENDS
#pragma mark ---------------------------------



#pragma mark - General Methods - START


+(LucUtility*) instance
{
    if (! objLUC)
        objLUC = [[LucUtility alloc] init];
    
    return objLUC;
}


-(void)setMasterControllerInstance:(LucMasterController*)masterController{
    
    _lucMasterController = masterController;
}

//HARSH: Not Using below method
- (void)enableCallKit:(BOOL)enable forCallManager:(MXCallManager *)callManager
{

    if (enable)
    {
        // Create adapter
        MXCallKitConfiguration *callKitConfiguration = [[MXCallKitConfiguration alloc] init];
        callKitConfiguration.iconName = @"icon_callkit";

        //NSData *callKitIconData = UIImagePNGRepresentation( [UIImage imageNamed:callKitConfiguration.iconName inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];);

        

        MXCallKitAdapter *callKitAdapter = [[MXCallKitAdapter alloc] initWithConfiguration:callKitConfiguration];

        id<MXCallAudioSessionConfigurator> audioSessionConfigurator;

#ifdef CALL_STACK_JINGLE
        audioSessionConfigurator = [[MXJingleCallAudioSessionConfigurator alloc] init];
#endif

        callKitAdapter.audioSessionConfigurator = audioSessionConfigurator;

        callManager.callKitAdapter = callKitAdapter;
    }
    else
    {
        callManager.callKitAdapter = nil;
    }
}


/**
 Display a "Call not supported" alert when the session receives a call invitation.
 
 @param mxSession the session to spy
 */
- (void)enableNoVoIPOnMatrixSession:(MXSession*)mxSession
{
    // Listen to call events
    callEventsListeners[@(mxSession.hash)] =
    [mxSession listenToEventsOfTypes:@[
                                       kMXEventTypeStringCallInvite,
                                       kMXEventTypeStringCallCandidates,
                                       kMXEventTypeStringCallAnswer,
                                       kMXEventTypeStringCallHangup
                                       ]
                             onEvent:^(MXEvent *event, MXTimelineDirection direction, id customObject) {
                                 
                                 if (MXTimelineDirectionForwards == direction)
                                 {
                                     switch (event.eventType)
                                     {
                                         case MXEventTypeCallInvite:
                                         {
                                             if (self->noCallSupportAlert)
                                             {
                                                 [self->noCallSupportAlert dismissViewControllerAnimated:NO completion:nil];
                                             }
                                             
                                             MXCallInviteEventContent *callInviteEventContent = [MXCallInviteEventContent modelFromJSON:event.content];
                                             
                                             // Sanity and invite expiration checks
                                             if (!callInviteEventContent || event.age >= callInviteEventContent.lifetime)
                                             {
                                                 return;
                                             }
                                             
                                             MXUser *caller = [mxSession userWithUserId:event.sender];
                                             NSString *callerDisplayname = caller.displayname;
                                             if (!callerDisplayname.length)
                                             {
                                                 callerDisplayname = event.sender;
                                             }
                                             
                                             NSString *appDisplayName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
                                             
                                             NSString *message = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"no_voip", @"Vector",[NSBundle bundleForClass:[self class]], nil), callerDisplayname, appDisplayName];
                                             
                                             self->noCallSupportAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"no_voip_title", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                                                                            message:message
                                                                                                     preferredStyle:UIAlertControllerStyleAlert];
                                             
                                             __weak typeof(self) weakSelf = self;
                                             
                                             [self->noCallSupportAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ignore"]
                                                                                                          style:UIAlertActionStyleDefault
                                                                                                        handler:^(UIAlertAction * action) {
                                                                                                            
                                                                                                            if (weakSelf)
                                                                                                            {
                                                                                                                typeof(self) self = weakSelf;
                                                                                                                self->noCallSupportAlert = nil;
                                                                                                            }
                                                                                                            
                                                                                                        }]];
                                             
                                             [self->noCallSupportAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"reject_call"]
                                                                                                          style:UIAlertActionStyleDefault
                                                                                                        handler:^(UIAlertAction * action) {
                                                                                                            
                                                                                                            // Reject the call by sending the hangup event
                                                                                                            NSDictionary *content = @{
                                                                                                                                      @"call_id": callInviteEventContent.callId,
                                                                                                                                      @"version": @(0)
                                                                                                                                      };
                                                                                                            
                                                                                                            [mxSession.matrixRestClient sendEventToRoom:event.roomId eventType:kMXEventTypeStringCallHangup content:content txnId:nil success:nil failure:^(NSError *error) {
                                                                                                                NSLog(@"[LucUtility] enableNoVoIPOnMatrixSession: ERROR: Cannot send m.call.hangup event.");
                                                                                                            }];
                                                                                                            
                                                                                                            if (weakSelf)
                                                                                                            {
                                                                                                                typeof(self) self = weakSelf;
                                                                                                                self->noCallSupportAlert = nil;
                                                                                                            }
                                                                                                            
                                                                                                        }]];
                                             
                                             [self showNotificationAlert:self->noCallSupportAlert];
                                             break;
                                         }
                                             
                                         case MXEventTypeCallAnswer:
                                         case MXEventTypeCallHangup:
                                             // The call has ended. The alert is no more needed.
                                             if (self->noCallSupportAlert)
                                             {
                                                 [self->noCallSupportAlert dismissViewControllerAnimated:YES completion:nil];
                                                 self->noCallSupportAlert = nil;
                                             }
                                             break;
                                             
                                         default:
                                             break;
                                     }
                                 }
                                 
                             }];
    
}

- (void)showNotificationAlert:(UIAlertController*)alert
{
    UIViewController *topVC = [LucUtilityHelper getTopViewController];
    
    if (topVC == nil) {
        
        return;
    }
    
    
    if (topVC.presentedViewController)
    {
        [alert popoverPresentationController].sourceView = topVC.presentedViewController.view;
        [alert popoverPresentationController].sourceRect = topVC.presentedViewController.view.bounds;
        [topVC.presentedViewController presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        [alert popoverPresentationController].sourceView = topVC.view;
        [alert popoverPresentationController].sourceRect = topVC.view.bounds;
        [topVC presentViewController:alert animated:YES completion:nil];
    }
}


- (void)addMatrixCallObserver
{
    if (matrixCallObserver)
    {
        return;
    }
    
    // Register call observer in order to handle incoming calls
    matrixCallObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallManagerNewCall
                                                                           object:nil
                                                                            queue:[NSOperationQueue mainQueue]
                                                                       usingBlock:^(NSNotification *notif)
                          {
                              // Ignore the call if a call is already in progress
                              if (!self->currentCallViewController )
                              {
                                  MXCall *mxCall = (MXCall*)notif.object;
                                  
                                  BOOL isCallKitEnabled = FALSE;//HARSH //[MXCallKitAdapter callKitAvailable] && [MXKAppSettings standardAppSettings].isCallKitEnabled;
                                  
                                  // Prepare the call view controller
                                  self->currentCallViewController = [CallViewController callViewController:nil];
                                  self->currentCallViewController.playRingtone = !isCallKitEnabled;
                                  self->currentCallViewController.mxCall = mxCall;
                                  self->currentCallViewController.delegate = self;
                                  
                                  UIApplicationState applicationState = UIApplication.sharedApplication.applicationState;
                                  
                                  // App has been woken by PushKit notification in the background
                                  if (applicationState == UIApplicationStateBackground && mxCall.isIncoming)
                                  {
                                      // Create backgound task.
                                      // Without CallKit this will allow us to play vibro until the call was ended
                                      // With CallKit we'll inform the system when the call is ended to let the system terminate our app to save resources
                                      id<MXBackgroundModeHandler> handler = [MXSDKOptions sharedInstance].backgroundModeHandler;
                                      
                                      NSUInteger callTaskIdentifier =  [handler startBackgroundTaskWithName:nil completion:^{
                                          
                                      }];
                                      
                                      // Start listening for call state change notifications
                                      __weak NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
                                      __block id token = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallStateDidChange
                                                                                                           object:mxCall
                                                                                                            queue:nil
                                                                                                       usingBlock:^(NSNotification * _Nonnull note) {
                                                                                                           MXCall *call = (MXCall *)note.object;
                                                                                                           
                                                                                                           if (call.state == MXCallStateEnded)
                                                                                                           {
                                                                                                               // Set call vc to nil to let our app handle new incoming calls even it wasn't killed by the system
                                                                                                               self->currentCallViewController = nil;
                                                                                                               [notificationCenter removeObserver:token];
                                                                                                               
                                                                                                               [handler endBackgrounTaskWithIdentifier:callTaskIdentifier];
                                                                                                           }
                                                                                                       }];
                                  }
                                  
                                  if (mxCall.isIncoming && isCallKitEnabled)
                                  {
                                      // Let's CallKit display the system incoming call screen
                                      // Show the callVC only after the user answered the call
                                      __weak NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
                                      __block id token = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallStateDidChange
                                                                                                           object:mxCall
                                                                                                            queue:nil
                                                                                                       usingBlock:^(NSNotification * _Nonnull note) {
                                                                                                           MXCall *call = (MXCall *)note.object;
                                                                                                           
                                                                                                           NSLog(@"[LucUtility] call.state: %@", call);
                                                                                                           
                                                                                                           if (call.state == MXCallStateCreateAnswer)
                                                                                                           {
                                                                                                               [notificationCenter removeObserver:token];
                                                                                                               
                                                                                                               NSLog(@"[LucUtility] presentCallViewController");
                                                                                                               [self presentCallViewController:NO completion:nil];
                                                                                                           }
                                                                                                       }];
                                  }
                                  else
                                  {
                                      [self presentCallViewController:YES completion:nil];
                                  }
                              }
                          }];
}





- (void)enableLocalNotificationsFromMatrixSession:(MXSession*)mxSession
{
    // Prepare listener block.
    MXWeakify(self);
    MXOnNotification notificationListenerBlock = ^(MXEvent *event, MXRoomState *roomState, MXPushRule *rule) {
        MXStrongifyAndReturnIfNil(self);
        
        // Ignore this event if the app is not running in background.
        if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground)
        {
            return;
        }
        
        // If the app is doing an initial sync, ignore all events from which we
        // did not receive a notification from APNS/PushKit
        if (!mxSession.isEventStreamInitialised && !self->incomingPushPayloads[event.eventId])
        {
            NSLog(@"[LucUtility][Push] enableLocalNotificationsFromMatrixSession: Initial sync in progress. Ignore event %@", event.eventId);
            return;
        }
        
        // Sanity check
        if (event.eventId && event.roomId && rule)
        {
            NSLog(@"[LucUtility][Push] enableLocalNotificationsFromMatrixSession: got event %@ to notify", event.eventId);
            
            // Check whether this event corresponds to a pending push for this session.
            NSUInteger index = [self.incomingPushEventIds[@(mxSession.hash)] indexOfObject:event.eventId];
            if (index != NSNotFound)
            {
                // Remove it from the pending list.
                [self.incomingPushEventIds[@(mxSession.hash)] removeObjectAtIndex:index];
            }
            
            // Add it to the list of the events to notify.
            [self->eventsToNotify[@(mxSession.hash)] addObject:@{
                                                                 @"event_id": event.eventId,
                                                                 @"room_id": event.roomId,
                                                                 @"push_rule": rule
                                                                 }];
        }
        else
        {
            NSLog(@"[LucUtility][Push] enableLocalNotificationsFromMatrixSession: WARNING: wrong event to notify %@ %@ %@", event, event.roomId, rule);
        }
    };
    
    eventsToNotify[@(mxSession.hash)] = [NSMutableArray array];
    [mxSession.notificationCenter listenToNotifications:notificationListenerBlock];
    notificationListenerBlocks[@(mxSession.hash)] = notificationListenerBlock;
}


- (void)enableInAppNotificationsForAccount:(MXKAccount*)account
{
    if (account.mxSession)
    {
        if (account.enableInAppNotifications)
        {
            // Build MXEvent -> NSString formatter
            EventFormatter *eventFormatter = [[EventFormatter alloc] initWithMatrixSession:account.mxSession];
            eventFormatter.isForSubtitle = YES;
            
            [account listenToNotifications:^(MXEvent *event, MXRoomState *roomState, MXPushRule *rule) {
                
                // Check conditions to display this notification
                if (![self.visibleRoomId isEqualToString:event.roomId])//&& !self.rootViewController.presentedViewController)
                {
                    MXKEventFormatterError error;
                    NSString* messageText = [eventFormatter stringFromEvent:event withRoomState:roomState error:&error];
                    if (messageText.length && (error == MXKEventFormatterErrorNone))
                    {
                        // Removing existing notification (if any)
                        if (self.mxInAppNotification)
                        {
                            [self.mxInAppNotification dismissViewControllerAnimated:NO completion:nil];
                        }
                        
                        // Check whether tweak is required
                        for (MXPushRuleAction *ruleAction in rule.actions)
                        {
                            if (ruleAction.actionType == MXPushRuleActionTypeSetTweak)
                            {
                                if ([[ruleAction.parameters valueForKey:@"set_tweak"] isEqualToString:@"sound"])
                                {
                                    // Play message sound
                                    AudioServicesPlaySystemSound(self->_messageSound);
                                }
                            }
                        }
                        
                        MXRoomSummary *roomSummary = [account.mxSession roomSummaryWithRoomId:event.roomId];
                        
                        __weak typeof(self) weakSelf = self;
                        self.mxInAppNotification = [UIAlertController alertControllerWithTitle:roomSummary.displayname
                                                                                       message:messageText
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        
                        [self.mxInAppNotification addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                                                     style:UIAlertActionStyleCancel
                                                                                   handler:^(UIAlertAction * action) {
                                                                                       
                                                                                       if (weakSelf)
                                                                                       {
                                                                                           typeof(self) self = weakSelf;
                                                                                           self.mxInAppNotification = nil;
                                                                                           [account updateNotificationListenerForRoomId:event.roomId ignore:YES];
                                                                                       }
                                                                                       
                                                                                   }]];
                        
                        [self.mxInAppNotification addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"view", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                                                     style:UIAlertActionStyleDefault
                                                                                   handler:^(UIAlertAction * action) {
                                                                                       
                                                                                       if (weakSelf)
                                                                                       {
                                                                                           typeof(self) self = weakSelf;
                                                                                           self.mxInAppNotification = nil;
                                                                                           // Show the room
                                                                                           [self showRoom:event.roomId andEventId:nil withMatrixSession:account.mxSession];
                                                                                       }
                                                                                       
                                                                                   }]];
                        
                        UIViewController *topVC = [LucUtilityHelper getTopViewController];
                        
                        if (topVC != nil) {
                            
                            [topVC presentViewController:self.mxInAppNotification animated:YES completion:nil];
                        }
                        
                    }
                }
            }];
        }
        else
        {
            [account removeNotificationListener];
        }
    }
    
    if (self.mxInAppNotification)
    {
        [self.mxInAppNotification dismissViewControllerAnimated:NO completion:nil];
        self.mxInAppNotification = nil;
    }
}


- (void)showRoom:(NSString*)roomId andEventId:(NSString*)eventId withMatrixSession:(MXSession*)mxSession
{
    [self showRoom:roomId andEventId:eventId withMatrixSession:mxSession restoreInitialDisplay:YES completion:nil];
}

- (void)createDirectChatWithUserId:(NSString*)userId completion:(void (^)(void))completion
{
    // Handle here potential multiple accounts
    [self selectMatrixAccount:^(MXKAccount *selectedAccount) {
        
        MXSession *mxSession = selectedAccount.mxSession;
        
        if (mxSession)
        {
            // Create a new room by inviting the other user only if it is defined and not oneself
            NSArray *invite = ((userId && ![mxSession.myUser.userId isEqualToString:userId]) ? @[userId] : nil);
            
            [mxSession createRoom:nil
                       visibility:kMXRoomDirectoryVisibilityPrivate
                        roomAlias:nil
                            topic:nil
                           invite:invite
                       invite3PID:nil
                         isDirect:(invite.count != 0)
                           preset:kMXRoomPresetTrustedPrivateChat
                          success:^(MXRoom *room) {
                              
                              // Open created room
                              [self showRoom:room.roomId andEventId:nil withMatrixSession:mxSession];
                              
                              if (completion)
                              {
                                  completion();
                              }
                              
                          }
                          failure:^(NSError *error) {
                              
                              //Alert user
                              [self showErrorAsAlert:error];
                              
                              if (completion)
                              {
                                  completion();
                              }
                              
                          }];
        }
        else if (completion)
        {
            completion();
        }
        
    }];
}

- (void)markAllMessagesAsRead
{
    for (MXSession *session in self.mxSessionArray)
    {
        [session markAllMessagesAsRead];
    }
}

//-(void)showChatView
- (UIAlertController*)showAlertWithTitle:(NSString*)title message:(NSString*)message
{
    [_errorNotification dismissViewControllerAnimated:NO completion:nil];
    
    _errorNotification = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [_errorNotification addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             
                                                             self.errorNotification = nil;
                                                             
                                                         }]];
    // Display the error notification
    if (!isErrorNotificationSuspended)
    {
        [_errorNotification mxk_setAccessibilityIdentifier:@"AppDelegateErrorAlert"];
        [self showNotificationAlert:_errorNotification];
    }
    
    return self.errorNotification;
}

- (UIAlertController*)showErrorAsAlert:(NSError*)error
{
    // Ignore fake error, or connection cancellation error
    if (!error || ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled))
    {
        return nil;
    }
    
    // Ignore network reachability error when the app is already offline
    if (self.isOffline && [error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorNotConnectedToInternet)
    {
        return nil;
    }
    
    // Ignore GDPR Consent not given error. Already caught by kMXHTTPClientUserConsentNotGivenErrorNotification observation
    if ([MXError isMXError:error])
    {
        MXError *mxError = [[MXError alloc] initWithNSError:error];
        if ([mxError.errcode isEqualToString:kMXErrCodeStringConsentNotGiven])
        {
            return nil;
        }
    }
    
    NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
    NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    if (!title)
    {
        if (msg)
        {
            title = msg;
            msg = nil;
        }
        else
        {
            title = [NSBundle mxk_localizedStringForKey:@"error"];
        }
    }
    
    // Switch in offline mode in case of network reachability error
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorNotConnectedToInternet)
    {
        self.isOffline = YES;
    }
    
    return [self showAlertWithTitle:title message:msg];
}



- (void)setupUserDefaults
{
    // Register "LUC-Defaults.plist" default values
    NSString* userDefaults = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UserDefaults"];
    NSString *defaultsPathFromApp = [[NSBundle mainBundle] pathForResource:userDefaults ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPathFromApp];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    
    // Now use LucSettings and NSUserDefaults to store `showDecryptedContentInNotifications` setting option
    // Migrate this information from main MXKAccount to LucSettings, if value is not in UserDefaults
    
    if (!LucSettings.shared.isShowDecryptedContentInNotificationsHasBeenSetOnce)
    {
        MXKAccount *currentAccount = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        LucSettings.shared.showDecryptedContentInNotifications = currentAccount.showDecryptedContentInNotifications;
    }
}

- (void)onSessionCryptoDidCorruptData:(NSNotification *)notification
{
    NSString *userId = notification.object;
    
    MXKAccount *account = [[MXKAccountManager sharedManager] accountForUserId:userId];
    if (account)
    {
        if (cryptoDataCorruptedAlert)
        {
            [cryptoDataCorruptedAlert dismissViewControllerAnimated:NO completion:nil];
        }
        
        cryptoDataCorruptedAlert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:NSLocalizedStringFromTableInBundle(@"e2e_need_log_in_again", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        __weak typeof(self) weakSelf = self;
        
        [cryptoDataCorruptedAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"later"]
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       
                                                                       if (weakSelf)
                                                                       {
                                                                           typeof(self) self = weakSelf;
                                                                           self->cryptoDataCorruptedAlert = nil;
                                                                       }
                                                                       
                                                                   }]];
        
        [cryptoDataCorruptedAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"settings_sign_out"]
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       
                                                                       if (weakSelf)
                                                                       {
                                                                           typeof(self) self = weakSelf;
                                                                           self->cryptoDataCorruptedAlert = nil;
                                                                           
                                                                           [[MXKAccountManager sharedManager] removeAccount:account completion:nil];
                                                                       }
                                                                       
                                                                   }]];
        
        [self showNotificationAlert:cryptoDataCorruptedAlert];
    }
}



- (void)keyBackupStateDidChangeNotification:(NSNotification *)notification
{
    MXKeyBackup *keyBackup = notification.object;
    
    if (keyBackup.state == MXKeyBackupStateWrongBackUpVersion)
    {
        if (wrongBackupVersionAlert)
        {
            [wrongBackupVersionAlert dismissViewControllerAnimated:NO completion:nil];
        }
        
        wrongBackupVersionAlert = [UIAlertController
                                   alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"e2e_key_backup_wrong_version_title", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                   
                                   message:NSLocalizedStringFromTableInBundle(@"e2e_key_backup_wrong_version", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                   
                                   preferredStyle:UIAlertControllerStyleAlert];
        
        MXWeakify(self);
        [wrongBackupVersionAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"e2e_key_backup_wrong_version_button_settings"]
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action)
                                            {
                                                MXStrongifyAndReturnIfNil(self);
                                                self->wrongBackupVersionAlert = nil;
                                                
                                                // TODO: Open settings
                                            }]];
        
        [wrongBackupVersionAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"e2e_key_backup_wrong_version_button_wasme"]
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action)
                                            {
                                                MXStrongifyAndReturnIfNil(self);
                                                self->wrongBackupVersionAlert = nil;
                                            }]];
        
        [self showNotificationAlert:wrongBackupVersionAlert];
    }
}

- (void)setIsOffline:(BOOL)isOffline
{
    if (!reachabilityObserver)
    {
        // Define reachability observer when isOffline property is set for the first time
        reachabilityObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AFNetworkingReachabilityDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            
            NSNumber *statusItem = note.userInfo[AFNetworkingReachabilityNotificationStatusItem];
            if (statusItem)
            {
                AFNetworkReachabilityStatus reachabilityStatus = statusItem.integerValue;
                if (reachabilityStatus == AFNetworkReachabilityStatusNotReachable)
                {
                    self.isOffline = YES;
                }
                else
                {
                    self.isOffline = NO;
                }
            }
            
        }];
    }
    
    if (_isOffline != isOffline)
    {
        _isOffline = isOffline;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kAppDelegateNetworkStatusDidChangeNotification object:nil];
    }
}


- (void)logoutWithConfirmation:(BOOL)askConfirmation completion:(void (^)(BOOL isLoggedOut))completion
{
    // Check whether we have to ask confirmation before logging out.
    if (askConfirmation)
    {
        if (self.logoutConfirmation)
        {
            [self.logoutConfirmation dismissViewControllerAnimated:NO completion:nil];
            self.logoutConfirmation = nil;
        }
        
        __weak typeof(self) weakSelf = self;
        
        NSString *message = NSLocalizedStringFromTableInBundle(@"settings_sign_out_confirmation", @"Vector",[NSBundle bundleForClass:[self class]], nil);
        
        // If the user has encrypted rooms, warn he will lose his e2e keys
        MXSession *session = self.mxSessions.firstObject;
        for (MXRoom *room in session.rooms)
        {
            if (room.summary.isEncrypted)
            {
                message = [message stringByAppendingString:[NSString stringWithFormat:@"\n\n%@", NSLocalizedStringFromTableInBundle(@"settings_sign_out_e2e_warn", @"Vector",[NSBundle bundleForClass:[self class]], nil)]];
                break;
            }
        }
        
        // Ask confirmation
        self.logoutConfirmation = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"settings_sign_out", @"Vector",[NSBundle bundleForClass:[self class]], nil) message:message preferredStyle:UIAlertControllerStyleAlert];
        
        [self.logoutConfirmation addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"settings_sign_out", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      
                                                                      if (weakSelf)
                                                                      {
                                                                          typeof(self) self = weakSelf;
                                                                          self.logoutConfirmation = nil;
                                                                          
                                                                          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                                                              
                                                                              [self logoutWithConfirmation:NO completion:completion];
                                                                              
                                                                          });
                                                                      }
                                                                      
                                                                  }]];
        
        [self.logoutConfirmation addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                                    style:UIAlertActionStyleCancel
                                                                  handler:^(UIAlertAction * action) {
                                                                      
                                                                      if (weakSelf)
                                                                      {
                                                                          typeof(self) self = weakSelf;
                                                                          self.logoutConfirmation = nil;
                                                                          
                                                                          if (completion)
                                                                          {
                                                                              completion(NO);
                                                                          }
                                                                      }
                                                                      
                                                                  }]];
        
        [self.logoutConfirmation mxk_setAccessibilityIdentifier: @"AppDelegateLogoutConfirmationAlert"];
        [self showNotificationAlert:self.logoutConfirmation];
        return;
    }
    
    // Display a loading wheel during the logout process
    
//    id topVC;
//    // HARSH no nned to show loading in framework

//        [topVC startActivityIndicator];

    
    [self logoutSendingRequestServer:YES completion:^(BOOL isLoggedOut) {
        if (completion)
        {
            completion (YES);
        }
    }];
}

- (void)logoutSendingRequestServer:(BOOL)sendLogoutServerRequest
                        completion:(void (^)(BOOL isLoggedOut))completion
{
    self.pushRegistry = nil;
    self.isPushRegistered = NO;
    
    // Clear cache
    [MXMediaManager clearCache];
    
    
#ifdef MX_CALL_STACK_ENDPOINT
    // Erase all created certificates and private keys by MXEndpointCallStack
    for (MXKAccount *account in MXKAccountManager.sharedManager.accounts)
    {
        if ([account.mxSession.callManager.callStack isKindOfClass:MXEndpointCallStack.class])
        {
            [(MXEndpointCallStack*)account.mxSession.callManager.callStack deleteData:account.mxSession.myUser.userId];
        }
    }
#endif
    
    // Logout all matrix account
    [[MXKAccountManager sharedManager] logoutWithCompletion:^{
        
        if (completion)
        {
            completion (YES);
        }
        
        // Return to authentication screen
        //HARSH: No auth screen for framework logout
        
        // Note: Keep App settings
        // But enforce usage of member lazy loading
        [MXKAppSettings standardAppSettings].syncWithLazyLoadOfRoomMembers = YES;
        
        // Reset the contact manager
        [[MXKContactManager sharedManager] reset];
        
    }];
}


#pragma mark - General Methods - ENDS
#pragma mark ---------------------------------
#pragma mark ---------------------------------



#pragma mark - Matrix sessions handling - START

- (void)initMatrixSessions
{
    NSLog(@"[LucUtility] initMatrixSessions");
    
    MXSDKOptions *sdkOptions = [MXSDKOptions sharedInstance];
    
    // Define the media cache version
    sdkOptions.mediaCacheAppVersion = 0;
    
    // Enable e2e encryption for newly created MXSession
    sdkOptions.enableCryptoWhenStartingMXSession = YES;
    
    // Disable identicon use
    sdkOptions.disableIdenticonUseForUserAvatar = YES;
    
    // Use UIKit BackgroundTask for handling background tasks in the SDK
    sdkOptions.backgroundModeHandler = [[MXUIKitBackgroundModeHandler alloc] init];
    
    // Get modular widget events in rooms histories
    [[MXKAppSettings standardAppSettings] addSupportedEventTypes:@[kWidgetMatrixEventTypeString, kWidgetModularEventTypeString]];
    
    // Enable long press on event in bubble cells
    [MXKRoomBubbleTableViewCell disableLongPressGestureOnEvent:NO];
    
    // Set first RoomDataSource class used in Vector
    [MXKRoomDataSourceManager registerRoomDataSourceClass:RoomDataSource.class];
    
    // Register matrix session state observer in order to handle multi-sessions.
    matrixSessionStateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        MXSession *mxSession = (MXSession*)notif.object;
        
        // Check whether the concerned session is a new one
        if (mxSession.state == MXSessionStateInitialised)
        {
            // Store this new session
            [self addMatrixSession:mxSession];
            
            // Set the VoIP call stack (if supported).
            id<MXCallStack> callStack;
            
            //callStack = [[MXOpenWebRTCCallStack alloc] init];

            //callStack = [[MXEndpointCallStack alloc] initWithMatrixId:mxSession.myUser.userId];
            //HARSH: using MXJingle for call stack
            callStack = [[MXJingleCallStack alloc] init];

            if (callStack)
            {
                [mxSession enableVoIPWithCallStack:callStack];
                
                // Let's call invite be valid for 1 minute
                mxSession.callManager.inviteLifetime = 60000;
                
                // Setup CallKit
                
                //HARSH : No callkit needed
//                if ([MXCallKitAdapter callKitAvailable])
//                {
//                    BOOL isCallKitEnabled = [MXKAppSettings standardAppSettings].isCallKitEnabled;
//                    [self enableCallKit:isCallKitEnabled forCallManager:mxSession.callManager];
//
//                    // Register for changes performed by the user
//                    [[MXKAppSettings standardAppSettings] addObserver:self
//                                                           forKeyPath:@"enableCallKit"
//                                                              options:NSKeyValueObservingOptionNew
//                                                              context:NULL];
//                }
//                else
                {
                    [self enableCallKit:NO forCallManager:mxSession.callManager];
                }
            }
            else
            {
                // When there is no call stack, display alerts on call invites
                [self enableNoVoIPOnMatrixSession:mxSession];
            }
            
            // Each room member will be considered as a potential contact.
            [MXKContactManager sharedManager].contactManagerMXRoomSource = MXKContactManagerMXRoomSourceAll;
            
            // Send read receipts for widgets events too
            NSMutableArray<MXEventTypeString> *acknowledgableEventTypes = [NSMutableArray arrayWithArray:mxSession.acknowledgableEventTypes];
            [acknowledgableEventTypes addObject:kWidgetMatrixEventTypeString];
            [acknowledgableEventTypes addObject:kWidgetModularEventTypeString];
            mxSession.acknowledgableEventTypes = acknowledgableEventTypes;
        }
        else if (mxSession.state == MXSessionStateStoreDataReady)
        {
            // A new call observer may be added here
            [self addMatrixCallObserver];
            
            // Enable local notifications
            [self enableLocalNotificationsFromMatrixSession:mxSession];
            
            // Look for the account related to this session.
            NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
            for (MXKAccount *account in mxAccounts)
            {
                if (account.mxSession == mxSession)
                {
                    // Enable inApp notifications (if they are allowed for this account).
                    [self enableInAppNotificationsForAccount:account];
                    break;
                }
            }
        }
        else if (mxSession.state == MXSessionStateClosed)
        {
            [self removeMatrixSession:mxSession];
        }
        // Consider here the case where the app is running in background.
        else if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)
        {
            NSLog(@"[LucUtility][Push] MXSession state changed while in background. mxSession.state: %tu - incomingPushEventIds: %@", mxSession.state, self.incomingPushEventIds[@(mxSession.hash)]);
            if (mxSession.state == MXSessionStateRunning)
            {
                // Pause the session in background task
                NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
                for (MXKAccount *account in mxAccounts)
                {
                    if (account.mxSession == mxSession)
                    {
                        [account pauseInBackgroundTask];
                        
                        // Trigger local notifcations (Indeed the app finishs here an initial sync in background, the user has missed some notifcations)
                        [self handleLocalNotificationsForAccount:account];
                        
                        // Update app icon badge number
                        [self refreshApplicationIconBadgeNumber];
                        
                        break;
                    }
                }
            }
            else if (mxSession.state == MXSessionStatePaused)
            {
                // Check whether some push notifications are pending for this session.
                if (self.incomingPushEventIds[@(mxSession.hash)].count)
                {
                    NSLog(@"[LucUtility][Push] relaunch a background sync for %tu kMXSessionStateDidChangeNotification pending incoming pushes", self.incomingPushEventIds[@(mxSession.hash)].count);
                    [self launchBackgroundSync];
                }
            }
            else if (mxSession.state == MXSessionStateInitialSyncFailed)
            {
                // Display failure sync notifications for pending events if any
                if (self.incomingPushEventIds[@(mxSession.hash)].count)
                {
                    NSLog(@"[LucUtility][Push] initial sync failed with %tu pending incoming pushes", self.incomingPushEventIds[@(mxSession.hash)].count);
                    
                    // Trigger limited local notifications when the sync with HS fails
                    [self handleLimitedLocalNotifications:mxSession events:self.incomingPushEventIds[@(mxSession.hash)]];
                    
                    // Update app icon badge number
                    [self refreshApplicationIconBadgeNumber];
                }
            }
        }
        else if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
        {
            if (mxSession.state == MXSessionStateRunning)
            {
                // Check if we need to display a key share dialog
                //[self checkPendingRoomKeyRequests];
            }
        }
        
        [self handleLaunchAnimation];
    }];
    
    // Register an observer in order to handle new account
    addedAccountObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidAddAccountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        // Finalize the initialization of this new account
        MXKAccount *account = notif.object;
        if (account)
        {
            // Replace default room summary updater
            EventFormatter *eventFormatter = [[EventFormatter alloc] initWithMatrixSession:account.mxSession];
            eventFormatter.isForSubtitle = YES;
            account.mxSession.roomSummaryUpdateDelegate = eventFormatter;
            
            // Set the push gateway URL.
            account.pushGatewayURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"pushGatewayURL"];
            
             //HARSH: Push should be already registered with the original app.
            
//            NSLog(@"[LucUtility][Push] didAddAccountNotification: self.isPushRegistered: %@", @(self.isPushRegistered));
//
//            if (self.isPushRegistered)
//            {
//                // Enable push notifications by default on new added account
//                [account enablePushKitNotifications:YES success:nil failure:nil];
//            }
//            else
//            {
//                // Set up push notifications
//                [self registerUserNotificationSettings];
//            }
            
            //HARSH:
            
            // Observe inApp notifications toggle change
            [account addObserver:self forKeyPath:@"enableInAppNotifications" options:0 context:nil];
        }
        
        
    }];
    
    // Add observer to handle removed accounts
    removedAccountObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidRemoveAccountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        // Remove inApp notifications toggle change
        MXKAccount *account = notif.object;
        if (!account.isSoftLogout)
        {
            [account removeObserver:self forKeyPath:@"enableInAppNotifications"];
        }
        
        // Clear Modular data
        [[WidgetManager sharedManager] deleteDataForUser:account.mxCredentials.userId];
        
        // Logout the app when there is no available account
        if (![MXKAccountManager sharedManager].accounts.count)
        {
            [self logoutWithConfirmation:NO completion:nil];
        }
    }];
    
    // Add observer to handle soft logout
    [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidSoftlogoutAccountNotification  object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXKAccount *account = notif.object;
        [self removeMatrixSession:account.mxSession];
        
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionIgnoredUsersDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notif) {
        
        NSLog(@"[LucUtility] kMXSessionIgnoredUsersDidChangeNotification received. Reload the app");
        
        // Reload entirely the app when a user has been ignored or unignored
        [self reloadMatrixSessions:YES];
        
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionDidCorruptDataNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notif) {
        
        NSLog(@"[LucUtility] kMXSessionDidCorruptDataNotification received. Reload the app");
        
        // Reload entirely the app when a session has corrupted its data
        [self reloadMatrixSessions:YES];
        
    }];
    
    // Add observer on settings changes.
    [[MXKAppSettings standardAppSettings] addObserver:self forKeyPath:@"showAllEventsInRoomHistory" options:0 context:nil];
    
    // Prepare account manager
    MXKAccountManager *accountManager = [MXKAccountManager sharedManager];
    
    // Use MXFileStore as MXStore to permanently store events.
    accountManager.storeClass = [MXFileStore class];
    
    // Disable APNS use.
    if (accountManager.apnsDeviceToken)
    {
        // We use now Pushkit, unregister for all remote notifications received via Apple Push Notification service.
        [[UIApplication sharedApplication] unregisterForRemoteNotifications];
        [accountManager setApnsDeviceToken:nil];
    }
    
    // Observers have been defined, we can start a matrix session for each enabled accounts.
    NSLog(@"[LucUtility] initMatrixSessions: prepareSessionForActiveAccounts (app state: %tu)", [[UIApplication sharedApplication] applicationState]);
    [accountManager prepareSessionForActiveAccounts];
    
    // Check whether we're already logged in
    NSArray *mxAccounts = accountManager.activeAccounts;
    if (mxAccounts.count)
    {
        for (MXKAccount *account in mxAccounts)
        {
            // Replace default room summary updater
            EventFormatter *eventFormatter = [[EventFormatter alloc] initWithMatrixSession:account.mxSession];
            eventFormatter.isForSubtitle = YES;
            account.mxSession.roomSummaryUpdateDelegate = eventFormatter;
            
            // The push gateway url is now configurable.
            // Set this url in the existing accounts when it is undefined.
            if (!account.pushGatewayURL)
            {
                account.pushGatewayURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"pushGatewayURL"];
            }
        }
        
        // Set up push notifications
        //HARSH: Push should be already registered with the original app.
        [self registerUserNotificationSettings];
        
        // Observe inApp notifications toggle change for each account
        for (MXKAccount *account in mxAccounts)
        {
            [account addObserver:self forKeyPath:@"enableInAppNotifications" options:0 context:nil];
        }
    }
}


- (void)addMatrixSession:(MXSession *)mxSession
{
    if (mxSession)
    {
        // Report this session to contact manager
        // But wait a bit that our launch animation screen is ready to show and
        // displayed if needed. As the processing in MXKContactManager can lock
        // the UI thread for several seconds, it is better to show the animation
        // during this blocking task.
        dispatch_after(dispatch_walltime(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [[MXKContactManager sharedManager] addMatrixSession:mxSession];
        });
        
        // Update home data sources
        if(self.lucMasterController != nil){
            [self.lucMasterController addMatrixSession:mxSession];
        }
        
        // Register the session to the widgets manager
        [[WidgetManager sharedManager] addMatrixSession:mxSession];
        
        [self.mxSessionArray addObject:mxSession];
        
        // Do the one time check on device id
        //HARSH: We don't need this
        //[self checkDeviceId:mxSession];
        
        // Add an array to handle incoming push
        self.incomingPushEventIds[@(mxSession.hash)] = [NSMutableArray array];
        
        // Enable listening of incoming key share requests
        [self enableRoomKeyRequestObserver:mxSession];
        
    }
}


- (void)startDirectChatWithUserId:(NSString*)userId completion:(void (^)(void))completion
{
    // Handle here potential multiple accounts
    [self selectMatrixAccount:^(MXKAccount *selectedAccount) {
        
        MXSession *mxSession = selectedAccount.mxSession;
        
        if (mxSession)
        {
            MXRoom *directRoom = [mxSession directJoinedRoomWithUserId:userId];
            
            // if the room exists
            if (directRoom)
            {
                // open it
                [self showRoom:directRoom.roomId andEventId:nil withMatrixSession:mxSession];
                
                if (completion)
                {
                    completion();
                }
            }
            else
            {
                [self createDirectChatWithUserId:userId completion:completion];
            }
        }
        else if (completion)
        {
            completion();
        }
        
    }];
}


- (void)selectMatrixAccount:(void (^)(MXKAccount *selectedAccount))onSelection
{
    NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    
    if (mxAccounts.count == 1)
    {
        if (onSelection)
        {
            onSelection(mxAccounts.firstObject);
        }
    }
    else if (mxAccounts.count > 1)
    {
        [accountPicker dismissViewControllerAnimated:NO completion:nil];
        
        accountPicker = [UIAlertController alertControllerWithTitle:[NSBundle mxk_localizedStringForKey:@"select_account"] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        __weak typeof(self) weakSelf = self;
        for(MXKAccount *account in mxAccounts)
        {
            [accountPicker addAction:[UIAlertAction actionWithTitle:account.mxCredentials.userId
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
                                                                
                                                                if (weakSelf)
                                                                {
                                                                    typeof(self) self = weakSelf;
                                                                    self->accountPicker = nil;
                                                                    
                                                                    if (onSelection)
                                                                    {
                                                                        onSelection(account);
                                                                    }
                                                                }
                                                                
                                                            }]];
        }
        
        [accountPicker addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                          style:UIAlertActionStyleCancel
                                                        handler:^(UIAlertAction * action) {
                                                            
                                                            if (weakSelf)
                                                            {
                                                                typeof(self) self = weakSelf;
                                                                self->accountPicker = nil;
                                                                
                                                                if (onSelection)
                                                                {
                                                                    onSelection(nil);
                                                                }
                                                            }
                                                            
                                                        }]];
        
        [self showNotificationAlert:accountPicker];
    }
}

- (void)enableRoomKeyRequestObserver:(MXSession*)mxSession
{
    roomKeyRequestObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:kMXCryptoRoomKeyRequestNotification
                                                      object:mxSession.crypto
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *notif)
     {
         //[self checkPendingRoomKeyRequestsInSession:mxSession];
     }];
    
    roomKeyRequestCancellationObserver  =
    [[NSNotificationCenter defaultCenter] addObserverForName:kMXCryptoRoomKeyRequestCancellationNotification
                                                      object:mxSession.crypto
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *notif)
     {
         //[self checkPendingRoomKeyRequestsInSession:mxSession];
     }];
}

/**
 Check the existence of device id.
 */
- (void)checkDeviceId:(MXSession*)mxSession
{
    // In case of the app update for the e2e encryption, the app starts with
    // no device id provided by the homeserver.
    // Ask the user to login again in order to enable e2e. Ask it once
    if (!isErrorNotificationSuspended && ![[NSUserDefaults standardUserDefaults] boolForKey:@"deviceIdAtStartupChecked"])
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"deviceIdAtStartupChecked"];
        
        // Check if there is a device id
        if (!mxSession.matrixRestClient.credentials.deviceId)
        {
            NSLog(@"WARNING: The user has no device. Prompt for login again");
            
            NSString *msg = NSLocalizedStringFromTableInBundle(@"e2e_enabling_on_app_update", @"Vector",[NSBundle bundleForClass:[self class]], nil);
            
            __weak typeof(self) weakSelf = self;
            [_errorNotification dismissViewControllerAnimated:NO completion:nil];
            _errorNotification = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
            
            [_errorNotification addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"later"]
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                     
                                                                     if (weakSelf)
                                                                     {
                                                                         typeof(self) self = weakSelf;
                                                                         self->_errorNotification = nil;
                                                                     }
                                                                     
                                                                 }]];
            
            [_errorNotification addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                     
                                                                     if (weakSelf)
                                                                     {
                                                                         typeof(self) self = weakSelf;
                                                                         self->_errorNotification = nil;
                                                                         
                                                                         [self logoutWithConfirmation:NO completion:nil];
                                                                     }
                                                                     
                                                                 }]];
            
            // Prompt the user
            [_errorNotification mxk_setAccessibilityIdentifier:@"AppDelegateErrorAlert"];
            [self showNotificationAlert:_errorNotification];
        }
    }
}

- (void)removeMatrixSession:(MXSession*)mxSession
{
    [[MXKContactManager sharedManager] removeMatrixSession:mxSession];
    
    // Update home data sources
    if(self.lucMasterController != nil){
        [self.lucMasterController removeMatrixSession:mxSession];
    }
    
    // Update the widgets manager
    [[WidgetManager sharedManager] removeMatrixSession:mxSession];
    
    // If any, disable the no VoIP support workaround
    [self disableNoVoIPOnMatrixSession:mxSession];
    
    // Disable local notifications from this session
    [self disableLocalNotificationsFromMatrixSession:mxSession];
    
    // Disable listening of incoming key share requests
    [self disableRoomKeyRequestObserver:mxSession];
    
    
    [self.mxSessionArray removeObject:mxSession];
    
    if (!self.mxSessionArray.count && matrixCallObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:matrixCallObserver];
        matrixCallObserver = nil;
    }
    
    [self.incomingPushEventIds removeObjectForKey:@(mxSession.hash)];
}


- (void)reloadMatrixSessions:(BOOL)clearCache
{
    // Reload all running matrix sessions
    NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    for (MXKAccount *account in mxAccounts)
    {
        [account reload:clearCache];
        
        // Replace default room summary updater
        EventFormatter *eventFormatter = [[EventFormatter alloc] initWithMatrixSession:account.mxSession];
        eventFormatter.isForSubtitle = YES;
        account.mxSession.roomSummaryUpdateDelegate = eventFormatter;
    }
    
    // Force back to Recents list if room details is displayed (Room details are not available until the end of initial sync)
    //HARSH: No pop for framework
    //[self popToHomeViewControllerAnimated:NO completion:nil];
    
    if (clearCache)
    {
        // clear the media cache
        [MXMediaManager clearCache];
    }
}

- (void)disableRoomKeyRequestObserver:(MXSession*)mxSession
{
    if (roomKeyRequestObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:roomKeyRequestObserver];
        roomKeyRequestObserver = nil;
    }
    
    if (roomKeyRequestCancellationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:roomKeyRequestCancellationObserver];
        roomKeyRequestCancellationObserver = nil;
    }
}

- (void)disableLocalNotificationsFromMatrixSession:(MXSession*)mxSession
{
    // Stop listening to notification of this session
    [mxSession.notificationCenter removeListener:notificationListenerBlocks[@(mxSession.hash)]];
    [notificationListenerBlocks removeObjectForKey:@(mxSession.hash)];
    [eventsToNotify removeObjectForKey:@(mxSession.hash)];
}

- (void)disableNoVoIPOnMatrixSession:(MXSession*)mxSession
{
    // Stop listening to the call events of this session
    [mxSession removeListener:callEventsListeners[@(mxSession.hash)]];
    [callEventsListeners removeObjectForKey:@(mxSession.hash)];
}

#pragma mark - Matrix sessions handling - ENDS
#pragma mark --------------------------------------------
#pragma mark ---------------------------------




#pragma mark - MXKCallViewControllerDelegate

- (void)dismissCallViewController:(MXKCallViewController *)callViewController completion:(void (^)(void))completion
{
    if (currentCallViewController && callViewController == currentCallViewController)
    {
        if (callViewController.isBeingPresented)
        {
            // Here the presentation of the call view controller is in progress
            // Postpone the dismiss
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self dismissCallViewController:callViewController completion:completion];
            });
        }
        // Check whether the call view controller is actually presented
        else if (callViewController.presentingViewController)
        {
            BOOL callIsEnded = (callViewController.mxCall.state == MXCallStateEnded);
            NSLog(@"Call view controller is dismissed (%d)", callIsEnded);
            
            [callViewController dismissViewControllerAnimated:YES completion:^{
                
                if (!callIsEnded)
                {
                    NSString *btnTitle = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"active_call_details", @"Vector",[NSBundle bundleForClass:[self class]], nil), callViewController.callerNameLabel.text];
                    [self addCallStatusBar:btnTitle];
                }
                
                if (completion)
                {
                    completion();
                }
                
            }];
            
            if (callIsEnded)
            {
                [self removeCallStatusBar];
                
                // Release properly
                [currentCallViewController destroy];
                currentCallViewController = nil;
            }
        }
        else if (_callStatusBarWindow)
        {
            // Here the call view controller was not presented.
            NSLog(@"Call view controller was not presented");
            
            // Workaround to manage the "back to call" banner: present temporarily the call screen.
            // This will correctly manage the navigation bar layout.
            [self presentCallViewController:YES completion:^{
                
                [self dismissCallViewController:self->currentCallViewController completion:completion];
                
            }];
        }
    }
}


#pragma mark - Call status handling

- (void)addCallStatusBar:(NSString*)buttonTitle
{
    // Add a call status bar
    CGSize topBarSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width, CALL_STATUS_BAR_HEIGHT);
    
    _callStatusBarWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, topBarSize.width, topBarSize.height)];
    _callStatusBarWindow.windowLevel = UIWindowLevelStatusBar;
    
    // Create statusBarButton
    _callStatusBarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _callStatusBarButton.frame = CGRectMake(0, 0, topBarSize.width, topBarSize.height);
    
    [_callStatusBarButton setTitle:buttonTitle forState:UIControlStateNormal];
    [_callStatusBarButton setTitle:buttonTitle forState:UIControlStateHighlighted];
    _callStatusBarButton.titleLabel.textColor = ThemeService.shared.theme.backgroundColor;
    
    _callStatusBarButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    
    [_callStatusBarButton setBackgroundColor:ThemeService.shared.theme.tintColor];
    [_callStatusBarButton addTarget:self action:@selector(onCallStatusBarButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    // Place button into the new window
    [_callStatusBarButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_callStatusBarWindow addSubview:_callStatusBarButton];
    
    // Force callStatusBarButton to fill the window (to handle auto-layout in case of screen rotation)
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:_callStatusBarButton
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:_callStatusBarWindow
                                                                       attribute:NSLayoutAttributeWidth
                                                                      multiplier:1.0
                                                                        constant:0];
    
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:_callStatusBarButton
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_callStatusBarWindow
                                                                        attribute:NSLayoutAttributeHeight
                                                                       multiplier:1.0
                                                                         constant:0];
    
    [NSLayoutConstraint activateConstraints:@[widthConstraint, heightConstraint]];
    
    _callStatusBarWindow.hidden = NO;
    [self statusBarDidChangeFrame];
    
    // We need to listen to the system status bar size change events to refresh the root controller frame.
    // Else the navigation bar position will be wrong.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusBarDidChangeFrame)
                                                 name:UIApplicationDidChangeStatusBarFrameNotification
                                               object:nil];
}

- (void)removeCallStatusBar
{
    if (_callStatusBarWindow)
    {
        // No more need to listen to system status bar changes
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
        
        // Hide & destroy it
        _callStatusBarWindow.hidden = YES;
        [_callStatusBarButton removeFromSuperview];
        _callStatusBarButton = nil;
        _callStatusBarWindow = nil;
        
        [self statusBarDidChangeFrame];
    }
}

- (void)onCallStatusBarButtonPressed
{
    if (currentCallViewController)
    {
        [self presentCallViewController:YES completion:nil];
    }
    
}

- (void)presentCallViewController:(BOOL)animated completion:(void (^)(void))completion
{
    
    UIViewController *topVC = [LucUtilityHelper getTopViewController];
    
    if (topVC == nil) {
        
        return;
    }
    
    [self removeCallStatusBar];
    
    if (currentCallViewController)
    {
        if (topVC.presentedViewController)
        {
            [topVC.presentedViewController presentViewController:currentCallViewController animated:animated completion:completion];
        }
        else
        {
            [topVC presentViewController:currentCallViewController animated:animated completion:completion];
        }
    }
}

- (void)statusBarDidChangeFrame
{
    UIViewController *topVC = [LucUtilityHelper getTopViewController];
    
    if (topVC == nil) {
        
        return;
    }
    
    // Refresh the root view controller frame
    CGRect rootControllerFrame = [[UIScreen mainScreen] bounds];
    
    if (_callStatusBarWindow)
    {
        UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
        
        switch (statusBarOrientation)
        {
            case UIInterfaceOrientationLandscapeLeft:
            {
                _callStatusBarWindow.frame = CGRectMake(-rootControllerFrame.size.width / 2, -CALL_STATUS_BAR_HEIGHT / 2, rootControllerFrame.size.width, CALL_STATUS_BAR_HEIGHT);
                _callStatusBarWindow.transform = CGAffineTransformMake(0, -1, 1, 0, CALL_STATUS_BAR_HEIGHT / 2, rootControllerFrame.size.width / 2);
                break;
            }
            case UIInterfaceOrientationLandscapeRight:
            {
                _callStatusBarWindow.frame = CGRectMake(-rootControllerFrame.size.width / 2, -CALL_STATUS_BAR_HEIGHT / 2, rootControllerFrame.size.width, CALL_STATUS_BAR_HEIGHT);
                _callStatusBarWindow.transform = CGAffineTransformMake(0, 1, -1, 0, rootControllerFrame.size.height - CALL_STATUS_BAR_HEIGHT / 2, rootControllerFrame.size.width / 2);
                break;
            }
            default:
            {
                _callStatusBarWindow.transform = CGAffineTransformIdentity;
                _callStatusBarWindow.frame = CGRectMake(0, 0, rootControllerFrame.size.width, CALL_STATUS_BAR_HEIGHT);
                break;
            }
        }
        
        // Apply the vertical offset due to call status bar
        rootControllerFrame.origin.y = CALL_STATUS_BAR_HEIGHT;
        rootControllerFrame.size.height -= CALL_STATUS_BAR_HEIGHT;
    }
    
    topVC.view.frame = rootControllerFrame;
    if (topVC.presentedViewController)
    {
        topVC.presentedViewController.view.frame = rootControllerFrame;
    }
    [topVC.view setNeedsLayout];
}

#pragma mark - Matrix Rooms handling

- (void)showRoom:(NSString*)roomId andEventId:(NSString*)eventId withMatrixSession:(MXSession*)mxSession restoreInitialDisplay:(BOOL)restoreInitialDisplay completion:(void (^)(void))completion
{
    if(self.lucMasterController == nil){
        
        return;
    }
    
    void (^selectRoom)(void) = ^() {
         //Select room to display its details
        
        [self.lucMasterController selectRoomWithId:roomId andEventId:eventId inMatrixSession:mxSession completion:^{

            // Remove delivered notifications for this room
            [self removeDeliveredNotificationsWithRoomId:roomId completion:nil];

            if (completion)
            {
                completion();
            }
        }];
    };
    
    if (restoreInitialDisplay)
    {
        //HARSH
        //[self restoreInitialDisplay:^{
            selectRoom();
        //}];
    }
    else
    {
        selectRoom();
    }
}


- (void)showRoom:(NSString*)roomId andEventId:(NSString*)eventId withMatrixSession:(MXSession*)mxSession restoreInitialDisplay:(BOOL)restoreInitialDisplay
{
    [self showRoom:roomId andEventId:eventId withMatrixSession:mxSession restoreInitialDisplay:restoreInitialDisplay completion:nil];
}

- (NSArray*)mxSessions
{
    return [NSArray arrayWithArray:self.mxSessionArray];
}

- (void)handleLaunchAnimation
{
    MXSession *mainSession = self.mxSessions.firstObject;
    
    if (mainSession)
    {
        BOOL isLaunching = NO;
        
        switch (mainSession.state)
        {
            case MXSessionStateClosed:
            case MXSessionStateInitialised:
                isLaunching = YES;
                break;
            case MXSessionStateStoreDataReady:
            case MXSessionStateSyncInProgress:
                // Stay in launching during the first server sync if the store is empty.
                isLaunching = (mainSession.rooms.count == 0 && launchAnimationContainerView);
            default:
                break;
        }
        
        if (isLaunching)
        {
            UIWindow *window = [[UIApplication sharedApplication] keyWindow];
            
            if (!launchAnimationContainerView && window)
            {
                launchAnimationContainerView = [[UIView alloc] initWithFrame:window.bounds];
                launchAnimationContainerView.backgroundColor = ThemeService.shared.theme.backgroundColor;
                launchAnimationContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                [window addSubview:launchAnimationContainerView];
                
                // Add animation view
                UIImageView *animationView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 170, 170)];
                animationView.image = [UIImage animatedImageNamed:@"animatedLogo-" duration:2];
                
                animationView.center = CGPointMake(launchAnimationContainerView.center.x, 3 * launchAnimationContainerView.center.y / 4);
                
                animationView.translatesAutoresizingMaskIntoConstraints = NO;
                [launchAnimationContainerView addSubview:animationView];
                
                NSLayoutConstraint* widthConstraint = [NSLayoutConstraint constraintWithItem:animationView
                                                                                   attribute:NSLayoutAttributeWidth
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:nil
                                                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                                                  multiplier:1
                                                                                    constant:170];
                
                NSLayoutConstraint* heightConstraint = [NSLayoutConstraint constraintWithItem:animationView
                                                                                    attribute:NSLayoutAttributeHeight
                                                                                    relatedBy:NSLayoutRelationEqual
                                                                                       toItem:nil
                                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                                   multiplier:1
                                                                                     constant:170];
                
                NSLayoutConstraint* centerXConstraint = [NSLayoutConstraint constraintWithItem:animationView
                                                                                     attribute:NSLayoutAttributeCenterX
                                                                                     relatedBy:NSLayoutRelationEqual
                                                                                        toItem:launchAnimationContainerView
                                                                                     attribute:NSLayoutAttributeCenterX
                                                                                    multiplier:1
                                                                                      constant:0];
                
                NSLayoutConstraint* centerYConstraint = [NSLayoutConstraint constraintWithItem:animationView
                                                                                     attribute:NSLayoutAttributeCenterY
                                                                                     relatedBy:NSLayoutRelationEqual
                                                                                        toItem:launchAnimationContainerView
                                                                                     attribute:NSLayoutAttributeCenterY
                                                                                    multiplier:3.0/4.0
                                                                                      constant:0];
                
                [NSLayoutConstraint activateConstraints:@[widthConstraint, heightConstraint, centerXConstraint, centerYConstraint]];
                
                launchAnimationStart = [NSDate date];
            }
            
            return;
        }
    }
    
    if (launchAnimationContainerView)
    {
        NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:launchAnimationStart];
        NSLog(@"[LucUtility] LaunchAnimation was shown for %.3fms", duration * 1000);
        
        // TODO: Send duration to Piwik
        // Such information should be the same on all platforms
        
        [launchAnimationContainerView removeFromSuperview];
        launchAnimationContainerView = nil;
    }
}

#pragma mark - Push notifications

- (void)registerUserNotificationSettings
{
    NSLog(@"[LucUtility][Push] registerUserNotificationSettings: self.isPushRegistered: %@", @(self.isPushRegistered));
    
    if (!self.isPushRegistered)
    {
        UNTextInputNotificationAction *quickReply = [UNTextInputNotificationAction
                                                     actionWithIdentifier:@"inline-reply"
                                                     title:NSLocalizedStringFromTableInBundle(@"room_message_short_placeholder", @"Vector",[NSBundle bundleForClass:[self class]], nil)
                                                     options:UNNotificationActionOptionAuthenticationRequired
                                                     ];
        
        UNNotificationCategory *quickReplyCategory = [UNNotificationCategory
                                                      categoryWithIdentifier:@"QUICK_REPLY"
                                                      actions:@[quickReply]
                                                      intentIdentifiers:@[]
                                                      options:UNNotificationCategoryOptionNone];
        
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center setNotificationCategories:[[NSSet alloc] initWithArray:@[quickReplyCategory]]];
        [center setDelegate:self]; // commenting this out will fall back to using the same AppDelegate methods as the iOS 9 way of doing this
        
        UNAuthorizationOptions authorizationOptions = (UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge);
        
        [center requestAuthorizationWithOptions:authorizationOptions
                              completionHandler:^(BOOL granted, NSError *error)
         { // code here is equivalent to self:application:didRegisterUserNotificationSettings:
             if (granted) {
                 [self registerForRemoteNotificationsWithCompletion:nil];
             }
             else
             {
                 // Clear existing token
                 [self clearPushNotificationToken];
             }
         }];
    }
}

- (void)registerForRemoteNotificationsWithCompletion:(nullable void (^)(NSError *))completion
{
    NSLog(@"[LucUtility][Push] registerForRemoteNotificationsWithCompletion");
    
    self.registrationForRemoteNotificationsCompletion = completion;
    
    self.pushRegistry = [[PKPushRegistry alloc] initWithQueue:nil];
    self.pushRegistry.delegate = self;
    self.pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

// iOS 10+, see application:handleActionWithIdentifier:forLocalNotification:withResponseInfo:completionHandler:
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler
{
    UNNotification *notification = response.notification;
    UNNotificationContent *content = notification.request.content;
    NSString *actionIdentifier = [response actionIdentifier];
    NSString *roomId = content.userInfo[@"room_id"];
    
    if ([actionIdentifier isEqualToString:@"inline-reply"])
    {
        if ([response isKindOfClass:[UNTextInputNotificationResponse class]])
        {
            UNTextInputNotificationResponse *textInputNotificationResponse = (UNTextInputNotificationResponse *)response;
            NSString *responseText = [textInputNotificationResponse userText];
            
            [self handleNotificationInlineReplyForRoomId:roomId withResponseText:responseText success:^(NSString *eventId) {
                completionHandler();
            } failure:^(NSError *error) {
                
                UNMutableNotificationContent *failureNotificationContent = [[UNMutableNotificationContent alloc] init];
                failureNotificationContent.userInfo = content.userInfo;
                failureNotificationContent.body = NSLocalizedStringFromTableInBundle(@"room_event_failed_to_send", @"Vector",[NSBundle bundleForClass:[self class]], nil);
                failureNotificationContent.threadIdentifier = roomId;
                
                NSString *uuid = [[NSUUID UUID] UUIDString];
                UNNotificationRequest *failureNotificationRequest = [UNNotificationRequest requestWithIdentifier:uuid
                                                                                                         content:failureNotificationContent
                                                                                                         trigger:nil];
                
                [center addNotificationRequest:failureNotificationRequest withCompletionHandler:nil];
                NSLog(@"[LucUtility][Push] didReceiveNotificationResponse: error sending text message: %@", error);
                
                completionHandler();
            }];
        }
        else
        {
            NSLog(@"[LucUtility][Push] didReceiveNotificationResponse: error, expect a response of type UNTextInputNotificationResponse");
            completionHandler();
        }
    }
    else if ([actionIdentifier isEqualToString:UNNotificationDefaultActionIdentifier])
    {
        [self navigateToRoomById:roomId];
        completionHandler();
    }
    else
    {
        NSLog(@"[LucUtility][Push] didReceiveNotificationResponse: unhandled identifier %@", actionIdentifier);
        completionHandler();
    }
}

// iOS 10+, this is called when a notification is about to display in foreground.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler
{
    NSLog(@"[LucUtility][Push] willPresentNotification: applicationState: %@", @([UIApplication sharedApplication].applicationState));
    
    completionHandler(UNNotificationPresentationOptionNone);
}

- (void)navigateToRoomById:(NSString *)roomId
{
    if (roomId.length)
    {
        // TODO retrieve the right matrix session
        // We can use the "user_id" value in notification.userInfo
        
        //**************
        // Patch consider the first session which knows the room id
        MXKAccount *dedicatedAccount = nil;
        
        NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
        
        if (mxAccounts.count == 1)
        {
            dedicatedAccount = mxAccounts.firstObject;
        }
        else
        {
            for (MXKAccount *account in mxAccounts)
            {
                if ([account.mxSession roomWithRoomId:roomId])
                {
                    dedicatedAccount = account;
                    break;
                }
            }
        }
        
        // sanity checks
        if (dedicatedAccount && dedicatedAccount.mxSession)
        {
            NSLog(@"[LucUtility][Push] navigateToRoomById: open the roomViewController %@", roomId);
            
            [self showRoom:roomId andEventId:nil withMatrixSession:dedicatedAccount.mxSession];
        }
        else
        {
            NSLog(@"[LucUtility][Push] navigateToRoomById : no linked session / account has been found.");
        }
    }
}

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(PKPushType)type
{
    NSData *token = credentials.token;
    
    NSLog(@"[LucUtility][Push] didUpdatePushCredentials: Got Push token: %@. Type: %@", [MXKTools logForPushToken:token], type);
    
    MXKAccountManager* accountManager = [MXKAccountManager sharedManager];
    [accountManager setPushDeviceToken:token withPushOptions:@{@"format": @"event_id_only"}];
    
    self.isPushRegistered = YES;
    
    if (self.registrationForRemoteNotificationsCompletion)
    {
        self.registrationForRemoteNotificationsCompletion(nil);
        self.registrationForRemoteNotificationsCompletion = nil;
    }
}

- (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(PKPushType)type
{
    NSLog(@"[LucUtility][Push] didInvalidatePushTokenForType: Type: %@", type);
    
    [self clearPushNotificationToken];
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type
{
    NSLog(@"[LucUtility][Push] didReceiveIncomingPushWithPayload: applicationState: %tu - type: %@ - payload: %@", [UIApplication sharedApplication].applicationState, payload.type, payload.dictionaryPayload);
    
    // Display local notifications only when the app is running in background.
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
        NSLog(@"[LucUtility][Push] didReceiveIncomingPushWithPayload while app is in background");
        
        // Check whether an event id is provided.
        NSString *eventId = payload.dictionaryPayload[@"event_id"];
        if (eventId)
        {
            // Add this event identifier in the pending push array for each session.
            for (NSMutableArray *array in self.incomingPushEventIds.allValues)
            {
                [array addObject:eventId];
            }
            
            // Cache payload for further usage
            incomingPushPayloads[eventId] = payload.dictionaryPayload;
        }
        else
        {
            NSLog(@"[LucUtility][Push] didReceiveIncomingPushWithPayload - Unexpected payload %@", payload.dictionaryPayload);
        }
        
        // Trigger a background sync to handle notifications.
        [self launchBackgroundSync];
    }
}

- (void)launchBackgroundSync
{
    // Launch a background sync for all existing matrix sessions
    NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    for (MXKAccount *account in mxAccounts)
    {
        // Check the current session state
        if (account.mxSession.state == MXSessionStatePaused)
        {
            NSLog(@"[LucUtility][Push] launchBackgroundSync");
            __weak typeof(self) weakSelf = self;
            
            NSMutableArray<NSString *> *incomingPushEventIds = self.incomingPushEventIds[@(account.mxSession.hash)];
            NSMutableArray<NSString *> *incomingPushEventIdsCopy = [incomingPushEventIds copy];
            
            // Flush all the pending push notifications for this session.
            [incomingPushEventIds removeAllObjects];
            
            [account backgroundSync:20000 success:^{
                
                // Sanity check
                if (!weakSelf)
                {
                    return;
                }
                typeof(self) self = weakSelf;
                
                NSLog(@"[LucUtility][Push] launchBackgroundSync: the background sync succeeds");
                
                // Trigger local notifcations
                [self handleLocalNotificationsForAccount:account];
                
                // Update app icon badge number
                [self refreshApplicationIconBadgeNumber];
                
            } failure:^(NSError *error) {
                
                NSLog(@"[LucUtility][Push] launchBackgroundSync: the background sync failed. Error: %@ (%@). incomingPushEventIdsCopy: %@ - self.incomingPushEventIds: %@", error.domain, @(error.code), incomingPushEventIdsCopy, incomingPushEventIds);
                
                // Trigger limited local notifications when the sync with HS fails
                [self handleLimitedLocalNotifications:account.mxSession events:incomingPushEventIdsCopy];
                
                // Update app icon badge number
                [self refreshApplicationIconBadgeNumber];
                
            }];
        }
    }
}

- (void)handleLocalNotificationsForAccount:(MXKAccount*)account
{
    NSString *userId = account.mxCredentials.userId;
    
    NSLog(@"[LucUtility][Push] handleLocalNotificationsForAccount: %@", userId);
    NSLog(@"[LucUtility][Push] handleLocalNotificationsForAccount: eventsToNotify: %@", eventsToNotify[@(account.mxSession.hash)]);
    NSLog(@"[LucUtility][Push] handleLocalNotificationsForAccount: incomingPushEventIds: %@", self.incomingPushEventIds[@(account.mxSession.hash)]);
    
    __block NSUInteger scheduledNotifications = 0;
    
    // The call invite are handled here only when the callkit is not active.
    BOOL isCallKitActive = FALSE;//HARSH No callkit needed//[MXCallKitAdapter callKitAvailable] && [MXKAppSettings standardAppSettings].isCallKitEnabled;
    
    NSMutableArray *eventsArray = eventsToNotify[@(account.mxSession.hash)];
    
    NSMutableArray<NSString*> *redactedEventIds = [NSMutableArray array];
    
    // Display a local notification for each event retrieved by the bg sync.
    for (NSUInteger index = 0; index < eventsArray.count; index++)
    {
        NSDictionary *eventDict = eventsArray[index];
        NSString *eventId = eventDict[@"event_id"];
        NSString *roomId = eventDict[@"room_id"];
        BOOL checkReadEvent = YES;
        MXEvent *event;
        
        if (eventId && roomId)
        {
            event = [account.mxSession.store eventWithEventId:eventId inRoom:roomId];
        }
        
        if (event)
        {
            if (event.isRedactedEvent)
            {
                // Collect redacted event ids to remove possible delivered redacted notifications
                [redactedEventIds addObject:eventId];
                continue;
            }
            
            // Consider here the call invites
            if (event.eventType == MXEventTypeCallInvite)
            {
                // Ignore call invite when callkit is active.
                if (isCallKitActive)
                {
                    NSLog(@"[LucUtility][Push] handleLocalNotificationsForAccount: Skip call event. Event id: %@", eventId);
                    continue;
                }
                else
                {
                    // Retrieve the current call state from the call manager
                    MXCallInviteEventContent *callInviteEventContent = [MXCallInviteEventContent modelFromJSON:event.content];
                    MXCall *call = [account.mxSession.callManager callWithCallId:callInviteEventContent.callId];
                    
                    if (call.state <= MXCallStateRinging)
                    {
                        // Keep display a local notification even if the event has been read on another device.
                        checkReadEvent = NO;
                    }
                }
            }
            
            if (checkReadEvent)
            {
                // Ignore event which has been read on another device.
                MXReceiptData *readReceipt = [account.mxSession.store getReceiptInRoom:roomId forUserId:userId];
                if (readReceipt)
                {
                    MXEvent *readReceiptEvent = [account.mxSession.store eventWithEventId:readReceipt.eventId inRoom:roomId];
                    if (event.originServerTs <= readReceiptEvent.originServerTs)
                    {
                        NSLog(@"[LucUtility][Push] handleLocalNotificationsForAccount: Skip already read event. Event id: %@", eventId);
                        continue;
                    }
                }
            }
            
            // Prepare the local notification
            MXPushRule *rule = eventDict[@"push_rule"];
            
            [self notificationContentForEvent:event pushRule:rule inAccount:account onComplete:^(UNNotificationContent * _Nullable notificationContent) {
                
                if (notificationContent)
                {
                    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:eventId
                                                                                          content:notificationContent
                                                                                          trigger:nil];
                    
                    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                        
                        if (error)
                        {
                            NSLog(@"[LucUtility][Push] handleLocalNotificationsForAccount: Fail to display notification for event %@ with error: %@", eventId, error);
                        }
                        else
                        {
                            NSLog(@"[LucUtility][Push] handleLocalNotificationsForAccount: Display notification for event %@", eventId);
                        }
                    }];
                    
                    scheduledNotifications++;
                }
                else
                {
                    NSLog(@"[LucUtility][Push] handleLocalNotificationsForAccount: Skip event with empty generated content. Event id: %@", eventId);
                }
            }];
        }
    }
    
    // Remove possible pending and delivered notifications having a redacted event id
    if (redactedEventIds.count)
    {
        NSLog(@"[LucUtility][Push] handleLocalNotificationsForAccount: Remove possible notification with redacted event ids: %@", redactedEventIds);
        
        [[UNUserNotificationCenter currentNotificationCenter] removePendingNotificationRequestsWithIdentifiers:redactedEventIds];
        [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:redactedEventIds];
    }
    
    NSLog(@"[LucUtility][Push] handleLocalNotificationsForAccount: Sent %tu local notifications for %tu events", scheduledNotifications, eventsArray.count);
    
    [eventsArray removeAllObjects];
}

- (NSString*)notificationSoundNameFromPushRule:(MXPushRule*)pushRule
{
    NSString *soundName;
    
    // Set sound name based on the value provided in action of MXPushRule
    for (MXPushRuleAction *action in pushRule.actions)
    {
        if (action.actionType == MXPushRuleActionTypeSetTweak)
        {
            if ([action.parameters[@"set_tweak"] isEqualToString:@"sound"])
            {
                soundName = action.parameters[@"value"];
                if ([soundName isEqualToString:@"default"])
                {
                    soundName = @"message.mp3";
                }
            }
        }
    }
    
    return soundName;
}

- (NSString*)notificationCategoryIdentifierForEvent:(MXEvent*)event
{
    BOOL isNotificationContentShown = !event.isEncrypted || LucSettings.shared.showDecryptedContentInNotifications;
    
    NSString *categoryIdentifier;
    
    if ((event.eventType == MXEventTypeRoomMessage || event.eventType == MXEventTypeRoomEncrypted) && isNotificationContentShown)
    {
        categoryIdentifier = @"QUICK_REPLY";
    }
    
    return categoryIdentifier;
}

- (NSDictionary*)notificationUserInfoForEvent:(MXEvent*)event andUserId:(NSString*)userId
{
    NSDictionary *notificationUserInfo = @{
                                           @"type": @"full",
                                           @"room_id": event.roomId,
                                           @"event_id": event.eventId,
                                           @"user_id": userId
                                           };
    return notificationUserInfo;
}

- (void)notificationBodyForEvent:(MXEvent *)event pushRule:(MXPushRule*)rule inAccount:(MXKAccount*)account onComplete:(void (^)(NSString * _Nullable notificationBody))onComplete;
{
    if (!event.content || !event.content.count)
    {
        NSLog(@"[LucUtility][Push] notificationBodyForEvent: empty event content");
        onComplete (nil);
        return;
    }
    
    MXRoom *room = [account.mxSession roomWithRoomId:event.roomId];
    if (!room)
    {
        NSLog(@"[LucUtility][Push] notificationBodyForEvent: Unknown room");
        onComplete (nil);
        return;
    }
    
    [room state:^(MXRoomState *roomState) {
        
        NSString *notificationBody;
        NSString *eventSenderName = [roomState.members memberName:event.sender];
        
        if (event.eventType == MXEventTypeRoomMessage || event.eventType == MXEventTypeRoomEncrypted)
        {
            if (room.isMentionsOnly)
            {
                // A local notification will be displayed only for highlighted notification.
                BOOL isHighlighted = NO;
                
                // Check whether is there an highlight tweak on it
                for (MXPushRuleAction *ruleAction in rule.actions)
                {
                    if (ruleAction.actionType == MXPushRuleActionTypeSetTweak)
                    {
                        if ([ruleAction.parameters[@"set_tweak"] isEqualToString:@"highlight"])
                        {
                            // Check the highlight tweak "value"
                            // If not present, highlight. Else check its value before highlighting
                            if (nil == ruleAction.parameters[@"value"] || YES == [ruleAction.parameters[@"value"] boolValue])
                            {
                                isHighlighted = YES;
                                break;
                            }
                        }
                    }
                }
                
                if (!isHighlighted)
                {
                    // Ignore this notif.
                    NSLog(@"[LucUtility][Push] notificationBodyForEvent: Ignore non highlighted notif in mentions only room");
                    onComplete(nil);
                    return;
                }
            }
            
            NSString *msgType = event.content[@"msgtype"];
            NSString *content = event.content[@"body"];
            
            if (event.isEncrypted && !LucSettings.shared.showDecryptedContentInNotifications)
            {
                // Hide the content
                msgType = nil;
            }
            
            NSString *roomDisplayName = room.summary.displayname;
            
            // Display the room name only if it is different than the sender name
            if (roomDisplayName.length && ![roomDisplayName isEqualToString:eventSenderName])
            {
                if ([msgType isEqualToString:@"m.text"])
                    notificationBody = [NSString stringWithFormat:NSLocalizedString(@"MSG_FROM_USER_IN_ROOM_WITH_CONTENT", nil), eventSenderName,roomDisplayName, content];
                else if ([msgType isEqualToString:@"m.emote"])
                    notificationBody = [NSString stringWithFormat:NSLocalizedString(@"ACTION_FROM_USER_IN_ROOM", nil), roomDisplayName, eventSenderName, content];
                else if ([msgType isEqualToString:@"m.image"])
                    notificationBody = [NSString stringWithFormat:NSLocalizedString(@"IMAGE_FROM_USER_IN_ROOM", nil), eventSenderName, content, roomDisplayName];
                else
                    // Encrypted messages falls here
                    notificationBody = [NSString stringWithFormat:NSLocalizedString(@"MSG_FROM_USER_IN_ROOM", nil), eventSenderName, roomDisplayName];
            }
            else
            {
                if ([msgType isEqualToString:@"m.text"])
                    notificationBody = [NSString stringWithFormat:NSLocalizedString(@"MSG_FROM_USER_WITH_CONTENT", nil), eventSenderName, content];
                else if ([msgType isEqualToString:@"m.emote"])
                    notificationBody = [NSString stringWithFormat:NSLocalizedString(@"ACTION_FROM_USER", nil), eventSenderName, content];
                else if ([msgType isEqualToString:@"m.image"])
                    notificationBody = [NSString stringWithFormat:NSLocalizedString(@"IMAGE_FROM_USER", nil), eventSenderName, content];
                else
                    // Encrypted messages falls here
                    notificationBody = [NSString stringWithFormat:NSLocalizedString(@"MSG_FROM_USER", nil), eventSenderName];
            }
        }
        else if (event.eventType == MXEventTypeCallInvite)
        {
            NSString *sdp = event.content[@"offer"][@"sdp"];
            BOOL isVideoCall = [sdp rangeOfString:@"m=video"].location != NSNotFound;
            
            if (!isVideoCall)
                notificationBody = [NSString stringWithFormat:NSLocalizedString(@"VOICE_CALL_FROM_USER", nil), eventSenderName];
            else
                notificationBody = [NSString stringWithFormat:NSLocalizedString(@"VIDEO_CALL_FROM_USER", nil), eventSenderName];
        }
        else if (event.eventType == MXEventTypeRoomMember)
        {
            NSString *roomDisplayName = room.summary.displayname;
            
            if (roomDisplayName.length && ![roomDisplayName isEqualToString:eventSenderName])
                notificationBody = [NSString stringWithFormat:NSLocalizedString(@"USER_INVITE_TO_NAMED_ROOM", nil), eventSenderName, roomDisplayName];
            else
                notificationBody = [NSString stringWithFormat:NSLocalizedString(@"USER_INVITE_TO_CHAT", nil), eventSenderName];
        }
        else if (event.eventType == MXEventTypeSticker)
        {
            NSString *roomDisplayName = room.summary.displayname;
            
            if (roomDisplayName.length && ![roomDisplayName isEqualToString:eventSenderName])
                notificationBody = [NSString stringWithFormat:NSLocalizedString(@"MSG_FROM_USER_IN_ROOM", nil), eventSenderName, roomDisplayName];
            else
                notificationBody = [NSString stringWithFormat:NSLocalizedString(@"MSG_FROM_USER", nil), eventSenderName];
        }
        
        onComplete(notificationBody);
    }];
}

// iOS 10+, does the same thing as notificationBodyForEvent:pushRule:inAccount:onComplete:, except with more features
- (void)notificationContentForEvent:(MXEvent *)event pushRule:(MXPushRule *)rule inAccount:(MXKAccount *)account onComplete:(void (^)(UNNotificationContent * _Nullable notificationContent))onComplete;
{
    if (!event.content || !event.content.count)
    {
        NSLog(@"[LucUtility][Push] notificationContentForEvent: empty event content");
        onComplete (nil);
        return;
    }
    
    MXRoom *room = [account.mxSession roomWithRoomId:event.roomId];
    if (!room)
    {
        NSLog(@"[LucUtility][Push] notificationBodyForEvent: Unknown room");
        onComplete (nil);
        return;
    }
    
    [room state:^(MXRoomState *roomState) {
        
        NSString *notificationTitle;
        NSString *notificationBody;
        
        NSString *threadIdentifier = room.roomId;
        NSString *eventSenderName = [roomState.members memberName:event.sender];
        
        if (event.eventType == MXEventTypeRoomMessage || event.eventType == MXEventTypeRoomEncrypted)
        {
            if (room.isMentionsOnly)
            {
                // A local notification will be displayed only for highlighted notification.
                BOOL isHighlighted = NO;
                
                // Check whether is there an highlight tweak on it
                for (MXPushRuleAction *ruleAction in rule.actions)
                {
                    if (ruleAction.actionType == MXPushRuleActionTypeSetTweak)
                    {
                        if ([ruleAction.parameters[@"set_tweak"] isEqualToString:@"highlight"])
                        {
                            // Check the highlight tweak "value"
                            // If not present, highlight. Else check its value before highlighting
                            if (nil == ruleAction.parameters[@"value"] || YES == [ruleAction.parameters[@"value"] boolValue])
                            {
                                isHighlighted = YES;
                                break;
                            }
                        }
                    }
                }
                
                if (!isHighlighted)
                {
                    // Ignore this notif.
                    NSLog(@"[LucUtility][Push] notificationBodyForEvent: Ignore non highlighted notif in mentions only room");
                    onComplete(nil);
                    return;
                }
            }
            
            NSString *msgType = event.content[@"msgtype"];
            NSString *messageContent = event.content[@"body"];
            
            if (event.isEncrypted && !LucSettings.shared.showDecryptedContentInNotifications)
            {
                // Hide the content
                msgType = nil;
            }
            
            NSString *roomDisplayName = room.summary.displayname;
            
            // Display the room name only if it is different than the sender name
            if (roomDisplayName.length && ![roomDisplayName isEqualToString:eventSenderName])
            {
                notificationTitle = [NSString localizedUserNotificationStringForKey:@"MSG_FROM_USER_IN_ROOM_TITLE" arguments:@[eventSenderName, roomDisplayName]];
                
                if ([msgType isEqualToString:@"m.text"])
                {
                    notificationBody = messageContent;
                }
                else if ([msgType isEqualToString:@"m.emote"])
                {
                    notificationBody = [NSString localizedUserNotificationStringForKey:@"ACTION_FROM_USER" arguments:@[eventSenderName, messageContent]];
                }
                else if ([msgType isEqualToString:@"m.image"])
                {
                    notificationBody = [NSString localizedUserNotificationStringForKey:@"IMAGE_FROM_USER" arguments:@[eventSenderName, messageContent]];
                }
                else
                {
                    // Encrypted messages falls here
                    notificationBody = [NSString localizedUserNotificationStringForKey:@"MSG_FROM_USER" arguments:@[eventSenderName]];
                }
            }
            else
            {
                notificationTitle = eventSenderName;
                
                if ([msgType isEqualToString:@"m.text"])
                {
                    notificationBody = messageContent;
                }
                else if ([msgType isEqualToString:@"m.emote"])
                {
                    notificationBody = [NSString localizedUserNotificationStringForKey:@"ACTION_FROM_USER" arguments:@[eventSenderName, messageContent]];
                }
                else if ([msgType isEqualToString:@"m.image"])
                {
                    notificationBody = [NSString localizedUserNotificationStringForKey:@"IMAGE_FROM_USER" arguments:@[eventSenderName, messageContent]];
                }
                else
                {
                    // Encrypted messages falls here
                    notificationBody = [NSString localizedUserNotificationStringForKey:@"MSG_FROM_USER" arguments:@[eventSenderName]];
                }
            }
        }
        else if (event.eventType == MXEventTypeCallInvite)
        {
            NSString *sdp = event.content[@"offer"][@"sdp"];
            BOOL isVideoCall = [sdp rangeOfString:@"m=video"].location != NSNotFound;
            
            if (!isVideoCall)
            {
                notificationBody = [NSString localizedUserNotificationStringForKey:@"VOICE_CALL_FROM_USER" arguments:@[eventSenderName]];
            }
            else
            {
                notificationBody = [NSString localizedUserNotificationStringForKey:@"VIDEO_CALL_FROM_USER" arguments:@[eventSenderName]];
            }
            
            // call notifications should stand out from normal messages, so we don't stack them
            threadIdentifier = nil;
        }
        else if (event.eventType == MXEventTypeRoomMember)
        {
            NSString *roomDisplayName = room.summary.displayname;
            
            if (roomDisplayName.length && ![roomDisplayName isEqualToString:eventSenderName])
            {
                notificationBody = [NSString localizedUserNotificationStringForKey:@"USER_INVITE_TO_NAMED_ROOM" arguments:@[eventSenderName, roomDisplayName]];
            }
            else
            {
                notificationBody = [NSString localizedUserNotificationStringForKey:@"USER_INVITE_TO_CHAT" arguments:@[eventSenderName]];
            }
        }
        else if (event.eventType == MXEventTypeSticker)
        {
            NSString *roomDisplayName = room.summary.displayname;
            
            if (roomDisplayName.length && ![roomDisplayName isEqualToString:eventSenderName])
            {
                notificationTitle = [NSString localizedUserNotificationStringForKey:@"MSG_FROM_USER_IN_ROOM_TITLE" arguments:@[eventSenderName, roomDisplayName]];
            }
            else
            {
                notificationTitle = eventSenderName;
            }
            
            notificationBody = [NSString localizedUserNotificationStringForKey:@"STICKER_FROM_USER" arguments:@[eventSenderName]];
        }
        
        UNMutableNotificationContent *notificationContent = [[UNMutableNotificationContent alloc] init];
        
        NSDictionary *notificationUserInfo = [self notificationUserInfoForEvent:event andUserId:account.mxCredentials.userId];
        NSString *notificationSoundName = [self notificationSoundNameFromPushRule:rule];
        NSString *categoryIdentifier = [self notificationCategoryIdentifierForEvent:event];
        
        notificationContent.title = notificationTitle;
        notificationContent.body = notificationBody;
        notificationContent.threadIdentifier = threadIdentifier;
        notificationContent.userInfo = notificationUserInfo;
        notificationContent.categoryIdentifier = categoryIdentifier;
        
        if (notificationSoundName)
        {
            notificationContent.sound = [UNNotificationSound soundNamed:notificationSoundName];
        }
        
        onComplete([notificationContent copy]);
    }];
}

/**
 Display "limited" notifications for events the app was not able to get data
 (because of /sync failure).
 
 In this situation, we are only able to display "You received a message in %@".
 
 @param mxSession the matrix session where the /sync failed.
 @param events the list of events id we did not get data.
 */
- (void)handleLimitedLocalNotifications:(MXSession*)mxSession events:(NSArray<NSString *> *)events
{
    NSString *userId = mxSession.matrixRestClient.credentials.userId;
    
    NSLog(@"[LucUtility][Push] handleLocalNotificationsForFailedSync: %@", userId);
    NSLog(@"[LucUtility][Push] handleLocalNotificationsForFailedSync: eventsToNotify: %@", eventsToNotify[@(mxSession.hash)]);
    NSLog(@"[LucUtility][Push] handleLocalNotificationsForFailedSync: incomingPushEventIds: %@", self.incomingPushEventIds[@(mxSession.hash)]);
    NSLog(@"[LucUtility][Push] handleLocalNotificationsForFailedSync: events: %@", events);
    
    if (!events.count)
    {
        return;
    }
    
    for (NSString *eventId in events)
    {
        // Build notification user info
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                        @"type": @"limited",
                                                                                        @"event_id": eventId,
                                                                                        @"user_id": userId
                                                                                        }];
        
        // Add the room_id so that user will open the room when tapping on the notif
        NSDictionary *payload = incomingPushPayloads[eventId];
        NSString *roomId = payload[@"room_id"];
        if (roomId)
        {
            userInfo[@"room_id"] = roomId;
        }
        else
        {
            NSLog(@"[LucUtility][Push] handleLocalNotificationsForFailedSync: room_id is missing for event %@ in payload %@", eventId, payload);
        }
        
        UNMutableNotificationContent *localNotificationContentForFailedSync = [[UNMutableNotificationContent alloc] init];
        localNotificationContentForFailedSync.userInfo = userInfo;
        localNotificationContentForFailedSync.body = [self limitedNotificationBodyForEvent:eventId inMatrixSession:mxSession];
        localNotificationContentForFailedSync.threadIdentifier = roomId;
        
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:eventId content:localNotificationContentForFailedSync trigger:nil];
        
        NSLog(@"[LucUtility][Push] handleLocalNotificationsForFailedSync: Display notification for event %@", eventId);
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:nil];
    }
}

/**
 Build the body for the "limited" notification to display to the user.
 
 @param eventId the id of the event the app failed to get data.
 @param mxSession the matrix session where the /sync failed.
 @return the string to display in the local notification.
 */
- (nullable NSString *)limitedNotificationBodyForEvent:(NSString *)eventId inMatrixSession:(MXSession*)mxSession
{
    NSString *notificationBody;
    
    NSString *roomDisplayName;
    
    NSDictionary *payload = incomingPushPayloads[eventId];
    NSString *roomId = payload[@"room_id"];
    if (roomId)
    {
        MXRoomSummary *roomSummary = [mxSession roomSummaryWithRoomId:roomId];
        if (roomSummary)
        {
            roomDisplayName = roomSummary.displayname;
        }
    }
    
    if (roomDisplayName.length)
    {
        notificationBody = [NSString stringWithFormat:NSLocalizedString(@"SINGLE_UNREAD_IN_ROOM", nil), roomDisplayName];
    }
    else
    {
        notificationBody = NSLocalizedString(@"SINGLE_UNREAD", nil);
    }
    
    return notificationBody;
}

- (void)refreshApplicationIconBadgeNumber
{
    if(self.lucMasterController == nil){
        
        return;
    }
    
    // Consider the total number of missed discussions including the invites.
    NSUInteger count = [self.lucMasterController missedDiscussionsCount];
    
    NSLog(@"[LucUtility] refreshApplicationIconBadgeNumber: %tu", count);
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = count;
}

- (void)handleNotificationInlineReplyForRoomId:(NSString*)roomId
                              withResponseText:(NSString*)responseText
                                       success:(void(^)(NSString *eventId))success
                                       failure:(void(^)(NSError *error))failure
{
    if (!roomId.length)
    {
        failure(nil);
        return;
    }
    
    NSArray* mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    
    MXKRoomDataSourceManager* manager;
    
    for (MXKAccount* account in mxAccounts)
    {
        MXRoom* room = [account.mxSession roomWithRoomId:roomId];
        if (room)
        {
            manager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:account.mxSession];
            if (manager)
            {
                break;
            }
        }
    }
    
    if (manager == nil)
    {
        NSLog(@"[LucUtility][Push] didReceiveNotificationResponse: room with id %@ not found", roomId);
        failure(nil);
    }
    else
    {
        [manager roomDataSourceForRoom:roomId create:YES onComplete:^(MXKRoomDataSource *roomDataSource) {
            if (responseText != nil && responseText.length != 0)
            {
                NSLog(@"[LucUtility][Push] didReceiveNotificationResponse: sending message to room: %@", roomId);
                [roomDataSource sendTextMessage:responseText success:^(NSString* eventId) {
                    success(eventId);
                } failure:^(NSError* error) {
                    failure(error);
                }];
            }
            else
            {
                failure(nil);
            }
        }];
    }
}

- (void)clearPushNotificationToken
{
    NSLog(@"[LucUtility][Push] clearPushNotificationToken: Clear existing token");
    
    // Clear existing token
    MXKAccountManager* accountManager = [MXKAccountManager sharedManager];
    [accountManager setPushDeviceToken:nil withPushOptions:nil];
}

// Remove delivred notifications for a given room id except call notifications
- (void)removeDeliveredNotificationsWithRoomId:(NSString*)roomId completion:(dispatch_block_t)completion
{
    NSLog(@"[LucUtility][Push] removeDeliveredNotificationsWithRoomId: Remove potential delivered notifications for room id: %@", roomId);
    
    NSMutableArray<NSString*> *notificationRequestIdentifiersToRemove = [NSMutableArray new];
    
    UNUserNotificationCenter *notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
    
    [notificationCenter getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> * _Nonnull notifications) {
        
        for (UNNotification *notification in notifications)
        {
            NSString *threadIdentifier = notification.request.content.threadIdentifier;
            
            if ([threadIdentifier isEqualToString:roomId])
            {
                [notificationRequestIdentifiersToRemove addObject:notification.request.identifier];
            }
        }
        
        [notificationCenter removeDeliveredNotificationsWithIdentifiers:notificationRequestIdentifiersToRemove];
        
        if (completion)
        {
            completion();
        }
    }];
}

@end
