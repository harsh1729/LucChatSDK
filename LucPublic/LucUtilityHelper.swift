//
//  LucUtility.swift
//  Luc
//
//  Created by HARSH VARDHAN on 02/09/19.
//  Copyright © 2019 Lintel.in. All rights reserved.
//

import Foundation
import MatrixKit
import MatrixSDK


@objcMembers public class LucUtilityHelper: NSObject {
    
    /**
     The matrix REST client used to make matrix API requests.
     */
    var  mxRestClient:MXRestClient?
    var matrixSessionStateObserver: NSObjectProtocol?
    var removedAccountObserver: NSObjectProtocol?
    var addedAccountObserver: NSObjectProtocol?
    
    
    public static func getTopViewController()-> UIViewController?{
        
        var topController : UIViewController?
        
        if let window = UIApplication.shared.keyWindow{
            if var vc = window.rootViewController {
                
                while let presentedViewController = vc.presentedViewController {
                    vc = presentedViewController
                }
                
                topController = vc
                 // topController should now be  topmost view controller
            }
        
        }
        
        return topController
    }
    
    func luc_updateRESTClient(homeServerURL : URL , identityServer : String ){
        
        mxRestClient = MXRestClient.init(homeServer: homeServerURL, unrecognizedCertificateHandler:nil)
        
        if let mxRestClient = mxRestClient{
            
            mxRestClient.identityServer = identityServer//"https://vector.im"
        }
        
    }
    
    @objc func luc_loginChatServer(username : String, password : String){

        // Create param dictionary
        var dictLoginCred : [String : Any] = [:]
        var childDictIden : [String : Any] = [:]
        
        dictLoginCred[Luc_Constants.LOGIN_KEY_USER] = username
        dictLoginCred[Luc_Constants.LOGIN_KEY_PASSWORD] = password
        dictLoginCred[Luc_Constants.LOGIN_KEY_TYPE] = "m.login.password"
        dictLoginCred[Luc_Constants.LOGIN_KEY_DEVICE] = "Mobile"
        
        childDictIden[Luc_Constants.LOGIN_KEY_IDENTIFIER_TYPE] = "m.id.user"
        childDictIden[Luc_Constants.LOGIN_KEY_IDENTIFIER_USER] = username
        dictLoginCred[Luc_Constants.LOGIN_KEY_IDENTIFIER] = childDictIden
        
        if let mxRestClient = mxRestClient{
            
            var mxCurrentOperation =  mxRestClient.login(parameters: dictLoginCred) { (responce : MXResponse <[String : Any]>) in
        
                if responce.isSuccess{
                    
                    print(mxRestClient.credentials as Any)
                    print(responce.value as Any)
                    //var  loginResponse :MXLoginResponse?
                    
                    //MXJSONModelSetMXJSONModel(loginResponse, MXLoginResponse, responce.value)
                    
                    
                    
                    // Hydrate the account with the new access token for softlogout
                    //MXKAccount *account = [[MXKAccountManager sharedManager] accountForUserId:self.softLogoutCredentials.userId];
                    //[[MXKAccountManager sharedManager] hydrateAccount:account withCredentials:credentials];
                    //var credentials : MXCredentials = MXCredentials.init(loginResponse: MXLoginResponse, andDefaultCredentials: mxRestClient.credentials)
                    
                    
                    //Check if account already exists
                    
                    if((MXKAccountManager.shared()?.account(forUserId: mxRestClient.credentials.userId)) == nil){
                        
                        // Report the new account in account manager
                        let account : MXKAccount = MXKAccount.init(credentials: mxRestClient.credentials)
                        account.identityServerURL = mxRestClient.identityServer
                        
                        MXKAccountManager.shared()?.addAccount(account, andOpenSession: true)
                    }
                    
                    
                }else{
                    
                    //Handle Login Failure
                    
                }
        
        
            }
        }
        
    }
    
    
    func luc_initChatServerSessions(){
        
        let sdkOptions : MXSDKOptions = MXSDKOptions.sharedInstance()
        
        // Define the media cache version
        sdkOptions.mediaCacheAppVersion = 0;
        
        // Enable e2e encryption for newly created MXSession
        sdkOptions.enableCryptoWhenStartingMXSession = true;
        
        // Disable identicon use
        sdkOptions.disableIdenticonUseForUserAvatar = true;
        
        // Use UIKit BackgroundTask for handling background tasks in the SDK
        sdkOptions.backgroundModeHandler = MXUIKitBackgroundModeHandler()
        
        guard let appDelegate = LucUtility.instance() else {
            return
        }
        // Get modular widget events in rooms histories
        if let _ = MXKAppSettings.standard(){
            
             MXKAppSettings.standard()?.addSupportedEventTypes([kWidgetMatrixEventTypeString,kWidgetModularEventTypeString])
        }
        
        // Enable long press on event in bubble cells
        MXKRoomBubbleTableViewCell.disableLongPressGesture(onEvent: false)
        
        // Set first RoomDataSource class used in Vector
        //MXKRoomDataSourceManager.registerRoomDataSourceClass(RoomDataSource.self);
        
        matrixSessionStateObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.mxSessionStateDidChange, object: nil, queue: OperationQueue.main, using: { (notif : Notification) in
            
            if let mxSession = notif.object as? MXSession{
                
                if (mxSession.state == MXSessionStateInitialised)
                {
                    self.addMatrixSession(mxSession: mxSession)
                    
                    let callStack: MXCallStack? = MXJingleCallStack()
                    
                    if let callStack = callStack{
                        
                        mxSession.enableVoIP(with:callStack)
                        
                        // Let's call invite be valid for 1 minute
                        mxSession.callManager.inviteLifetime = 60000;
                        
                        if MXCallKitAdapter.callKitAvailable() {
                            let isCallKitEnabled = MXKAppSettings.standard().isCallKitEnabled
                            appDelegate.enableCallKit(isCallKitEnabled, for: mxSession.callManager)
                            
                            // Register for changes performed by the user
                            MXKAppSettings.standard().addObserver(self, forKeyPath: "enableCallKit", options: .new, context: nil)
                            
                        } else {
                            
                            appDelegate.enableCallKit(false, for: mxSession.callManager)
                        }
                    }else{
                        
                        appDelegate.enableNoVoIP(onMatrixSession: mxSession)
                    }
                    
                    // Each room member will be considered as a potential contact.
                    MXKContactManager.shared().contactManagerMXRoomSource = MXKContactManagerMXRoomSource.all;
                    
                    // Send read receipts for widgets events too
                    if  var acknowledgableEventTypes =  mxSession.acknowledgableEventTypes{
                        
                        acknowledgableEventTypes.append(kWidgetMatrixEventTypeString)
                        acknowledgableEventTypes.append(kWidgetModularEventTypeString)
                        
                        mxSession.acknowledgableEventTypes = acknowledgableEventTypes;
                    }
                    
                    
                    
                }else if mxSession.state == MXSessionStateStoreDataReady{
                    
                        // A new call observer may be added here
                        appDelegate.addMatrixCallObserver()
                        // Enable local notifications
                        appDelegate.enableLocalNotifications(fromMatrixSession: mxSession)
                        
                        if let accManager = MXKAccountManager.shared(){
                            
                            // Look for the account related to this session.
                            if let mxAccounts = accManager.activeAccounts{
                                
                                for account in mxAccounts{
                                    if account.mxSession == mxSession{
                                        
                                        appDelegate.enableInAppNotifications(for: account)
                                        break
                                    }
                                }
                            }
                            
                        }
                    
                }else if mxSession.state == MXSessionStateClosed{
                    
                    self.removeMatrixSession(mxSession: mxSession)
                }// Consider here the case where the app is running in background.
                else if UIApplication.shared.applicationState == .background{
                    
                    if mxSession.state == MXSessionStateRunning
                    {
                        // Pause the session in background task
                        if let mxAccounts = MXKAccountManager.shared().activeAccounts{
                            
                            for account in mxAccounts{
                                if account.mxSession == mxSession{
                                    
                                    account.pauseInBackgroundTask()
                                        
                                    // Trigger local notifcations (Indeed the app finishs here an initial sync in background, the user has missed some notifcations)
                                    appDelegate.handleLocalNotifications(for: account)
                                        
                                    // Update app icon badge number
                                    appDelegate.refreshApplicationIconBadgeNumber()
                                    
                                    break
                                }
                            }
                            
                        }
                    }else if mxSession.state == MXSessionStatePaused
                    {
                        if let incomingPushEventIds = appDelegate.incomingPushEventIds{
                            
                            // Check whether some push notifications are pending for this session.
                            if let array = incomingPushEventIds[mxSession.hash] as? [ String]
                            {
                                if array.count > 0{
                                    
                                    appDelegate.launchBackgroundSync()
                                }
                                
                            }
                        }
                        
                        
                    }else if mxSession.state == MXSessionStateInitialSyncFailed
                    {
                         if let incomingPushEventIds = appDelegate.incomingPushEventIds{
                            
                            if let arrayEvents = incomingPushEventIds[mxSession.hash] as? [ String]
                            {
                                if arrayEvents.count > 0{
                                    
                                    appDelegate.handleLimitedLocalNotifications(mxSession, events: arrayEvents)
                                    
                                    appDelegate.refreshApplicationIconBadgeNumber()
                                }
                            }
                        }
                        
                        
                    }
                    
                }else if  UIApplication.shared.applicationState == .active
                {
                    if mxSession.state == MXSessionStateRunning
                    {
                        // Check if we need to display a key share dialog
                        //appDelegate.checkPendingRoomKeyRequests()
                        
                    }

                }
                
                appDelegate.handleLaunchAnimation()
                
            } //if let mxSession ends
        })
        
        
        // Register an observer in order to handle new account
        addedAccountObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.mxkAccountManagerDidAddAccount, object: nil, queue: OperationQueue.main, using: { (notif : Notification) in
            
            
            if let mxAccount = notif.object as? MXKAccount{
                
                if var eventFormatter = EventFormatter.init(matrixSession: mxAccount.mxSession){
                    
                    eventFormatter.isForSubtitle = true;
                    mxAccount.mxSession.roomSummaryUpdateDelegate = eventFormatter;
                }
                
                // Set the push gateway URL.
                if let url =  UserDefaults.standard.object(forKey: "pushGatewayURL") as? String{
                    
                    mxAccount.pushGatewayURL = url
                }
                
                
                if (appDelegate.isPushRegistered)
                {
                    // Enable push notifications by default on new added account
                    mxAccount.enablePushNotifications(true, success: nil, failure: nil)
                }
                else
                {
                    // Set up push notifications
                    appDelegate.registerUserNotificationSettings()
                }
                
                // Observe inApp notifications toggle change
                mxAccount.addObserver(self, forKeyPath: "enableInAppNotifications", options: [], context: nil)
                
                
            }
            
            // Load the local contacts on first account creation.
            if let mxkMan = MXKAccountManager.shared(){
                
                if mxkMan.accounts.count == 1{
                    
                    DispatchQueue.main.async {
                        appDelegate.refreshLocalContacts()
                    }
                }
            }
            
        })
        
        
        // Register an observer in order to handle new account
        removedAccountObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.mxkAccountManagerDidRemoveAccount, object: nil, queue: OperationQueue.main, using: { (notif : Notification) in
            
             if let mxAccount = notif.object as? MXKAccount{
                
                if !mxAccount.isSoftLogout
                {
                    mxAccount.removeObserver(self, forKeyPath: "enableInAppNotifications")
                }
                
                // Clear Modular data
                if let widgetMan =  WidgetManager.shared(){
                    
                    widgetMan.deleteData(forUser: mxAccount.mxCredentials.userId)
                }
                
                // Logout the app when there is no available account
                if let mxkMan = MXKAccountManager.shared(){
                    
                     if mxkMan.accounts.count > 0{
                        
                        appDelegate.logout(withConfirmation: false, completion: nil)
                    }
                }
                
            }
        })
            
    }
            
        
    
    
    
    func addMatrixSession(mxSession : MXSession)
    {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .microseconds(300)) {
                // Code
            MXKContactManager.shared().addMatrixSession(mxSession)
        }
        
        if let instance = LucUtility.instance(){
            
            if let masterTabBarController =  instance.lucMasterController{
                
                //HARSH : TODO
                //masterTabBarController.addMatrixSession(mxSession)
                
                if let widgetManager = WidgetManager.shared(){
                    
                    widgetManager.addMatrixSession(mxSession)
                }
                
                if let _ = instance.mxSessionArray{
                    
                     instance.mxSessionArray?.add(mxSession)
                }
               
                if let _ = instance.incomingPushEventIds{
                    instance.incomingPushEventIds?[mxSession.hash] = []
                }
                
                
                
                //appDelegate.enableRoomKeyRequestObserver(mxSession)
                //appDelegate.enableIncomingDeviceVerificationObserver(mxSession)
            }
            
            
        }
        
    }
    
    func removeMatrixSession(mxSession : MXSession)
    {
        //MXKContactManager.shared().removeMatrixSession(mxSession)
        if let instance = LucUtility.instance(){
            //appDelegate.masterTabBarController.removeMatrixSession(mxSession)
            
            // Update the widgets manager
//            if let wManager = WidgetManager.shared(){
//                wManager.removeMatrixSession(mxSession)
//            }
            
            instance.removeMatrixSession(mxSession)//TODO : implement this method here
            
        }
    }

    
}
