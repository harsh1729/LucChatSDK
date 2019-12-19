/*
 

 

 
 */

import Foundation
import UIKit

/// Color constants for the dark theme
@objcMembers
 public class  DarkTheme: NSObject, Theme {

    public var backgroundColor: UIColor = UIColor(rgb: 0x181B21)

    public var baseColor: UIColor = UIColor(rgb: 0x15171B)
    public var baseTextPrimaryColor: UIColor = UIColor(rgb: 0xEDF3FF)
    public var baseTextSecondaryColor: UIColor = UIColor(rgb: 0xEDF3FF)

    public var searchBackgroundColor: UIColor = UIColor(rgb: 0x181B21)
    public var searchPlaceholderColor: UIColor = UIColor(rgb: 0x61708B)

    public var headerBackgroundColor: UIColor = UIColor(rgb: 0x22262E)
    public var headerBorderColor: UIColor  = UIColor(rgb: 0x181B21)
    public var headerTextPrimaryColor: UIColor = UIColor(rgb: 0xA1B2D1)
    public var headerTextSecondaryColor: UIColor = UIColor(rgb: 0xC8C8CD)

    public var textPrimaryColor: UIColor = UIColor(rgb: 0xEDF3FF)
    public var textSecondaryColor: UIColor = UIColor(rgb: 0xA1B2D1)

    public var tintColor: UIColor = UIColor(rgb: 0x03B381)
    public var tintBackgroundColor: UIColor = UIColor(rgb: 0x1F6954)
    public var unreadRoomIndentColor: UIColor = UIColor(rgb: 0x2E3648)
    public var lineBreakColor: UIColor = UIColor(rgb: 0x61708B)
    
    public var noticeColor: UIColor = UIColor(rgb: 0xFF4B55)
    public var noticeSecondaryColor: UIColor = UIColor(rgb: 0x61708B)

    public var warningColor: UIColor = UIColor(rgb: 0xFF4B55)

    public var avatarColors: [UIColor] = [
        UIColor(rgb: 0x03B381),
        UIColor(rgb: 0x368BD6),
        UIColor(rgb: 0xAC3BA8)]
    
    public var userNameColors: [UIColor] = [
        UIColor(rgb: 0x368BD6),
        UIColor(rgb: 0xAC3BA8),
        UIColor(rgb: 0x03B381),
        UIColor(rgb: 0xE64F7A),
        UIColor(rgb: 0xFF812D),
        UIColor(rgb: 0x2DC2C5),
        UIColor(rgb: 0x5C56F5),
        UIColor(rgb: 0x74D12C)
    ]

    public var statusBarStyle: UIStatusBarStyle = .lightContent
    public var scrollBarStyle: UIScrollView.IndicatorStyle = .white
    public var keyboardAppearance: UIKeyboardAppearance = .dark

    public var placeholderTextColor: UIColor = UIColor(white: 1.0, alpha: 0.3)
    public var selectedBackgroundColor: UIColor? = UIColor.black
    public var overlayBackgroundColor: UIColor = UIColor(white: 0.7, alpha: 0.5)
    public var matrixSearchBackgroundImageTintColor: UIColor = UIColor(rgb: 0x7E7E7E)
    
    public func applyStyle(onTabBar tabBar: UITabBar) {
        tabBar.tintColor = self.tintColor
        tabBar.barTintColor = self.headerBackgroundColor
        tabBar.isTranslucent = false
    }

    public func applyStyle(onNavigationBar navigationBar: UINavigationBar) {
        navigationBar.tintColor = self.baseTextPrimaryColor
        navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: self.baseTextPrimaryColor
        ]
        navigationBar.barTintColor = self.baseColor

        // The navigation bar needs to be opaque so that its background color is the expected one
        navigationBar.isTranslucent = false
    }

    public func applyStyle(onSearchBar searchBar: UISearchBar) {
        searchBar.barStyle = .black
        searchBar.tintColor = self.searchPlaceholderColor
        searchBar.barTintColor = self.headerBackgroundColor
        
        if let searchBarTextField = searchBar.vc_searchTextField {
            searchBarTextField.textColor = searchBar.tintColor            
        }
    }
    
    public func applyStyle(onTextField texField: UITextField) {
        texField.textColor = self.textPrimaryColor
        texField.tintColor = self.tintColor
    }
    
    public func applyStyle(onButton button: UIButton) {
        // NOTE: Tint color does nothing by default on button type `UIButtonType.custom`
        button.tintColor = self.tintColor
    }
}
