/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import Foundation

/// Store Riot specific app settings.
@objcMembers
public final class LucSettings: NSObject {
    
    // MARK: - Constants
    
    private enum UserDefaultsKeys {
        static let enableCrashReport = "enableCrashReport"
        static let enableRageShake = "enableRageShake"
        static let createConferenceCallsWithJitsi = "createConferenceCallsWithJitsi"
        static let userInterfaceTheme = "userInterfaceTheme"
        static let notificationsShowDecryptedContent = "showDecryptedContent"
        static let pinRoomsWithMissedNotifications = "pinRoomsWithMissedNotif"
        static let pinRoomsWithUnreadMessages = "pinRoomsWithUnread"
    }

    /// Riot Standard Room Member Power Level
    @objc
    public enum RoomPowerLevel: Int {
        case moderator = 50
        case admin = 100
    }

    public static let shared = LucSettings()
    
    // MARK: - Public
    
    // MARK: Notifications
    
    /// Indicate if `showDecryptedContentInNotifications` settings has been set once.
    public var isShowDecryptedContentInNotificationsHasBeenSetOnce: Bool {
        return UserDefaults.standard.object(forKey: UserDefaultsKeys.notificationsShowDecryptedContent) != nil
    }
    
    /// Indicate if encrypted messages content should be displayed in notifications.
    public var showDecryptedContentInNotifications: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKeys.notificationsShowDecryptedContent)
        } set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.notificationsShowDecryptedContent)
        }
    }
    
    /// Indicate if rooms with missed notifications should be displayed first on home screen.
    public var pinRoomsWithMissedNotificationsOnHome: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKeys.pinRoomsWithMissedNotifications)
        } set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.pinRoomsWithMissedNotifications)
        }
    }
    
    /// Indicate if rooms with unread messages should be displayed first on home screen.
    public var pinRoomsWithUnreadMessagesOnHome: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKeys.pinRoomsWithUnreadMessages)
        } set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.pinRoomsWithUnreadMessages)
        }
    }
    
    // MARK: User interface
    
    public var userInterfaceTheme: String? {
        get {
            return UserDefaults.standard.string(forKey: UserDefaultsKeys.userInterfaceTheme)
        } set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.userInterfaceTheme)
        }
    }
    
    // MARK: Other
    
    /// Indicate if `enableCrashReport` settings has been set once.
    var isEnableCrashReportHasBeenSetOnce: Bool {
        return UserDefaults.standard.object(forKey: UserDefaultsKeys.enableCrashReport) != nil
    }
    
    var enableCrashReport: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKeys.enableCrashReport)
        } set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.enableCrashReport)
        }
    }
    
    var enableRageShake: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKeys.enableRageShake)
        } set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.enableRageShake)
        }
    }
    
    // MARK: Labs
    
    var createConferenceCallsWithJitsi: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKeys.createConferenceCallsWithJitsi)
        } set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.createConferenceCallsWithJitsi)
        }
    }
}
