/*
 

 

 
 */

import Foundation
import UIKit

/// Color constants for the default theme
@objcMembers
 public class  DefaultTheme: NSObject, Theme {

    public var backgroundColor: UIColor = UIColor(rgb: 0xFFFFFF)

    public var baseColor: UIColor = UIColor(rgb: 0x56a8e2);//27303A)
    public var baseTextPrimaryColor: UIColor = UIColor(rgb: 0xFFFFFF)
    public var baseTextSecondaryColor: UIColor = UIColor(rgb: 0xFFFFFF)

    public var searchBackgroundColor: UIColor = UIColor(rgb: 0xFFFFFF)
    public var searchPlaceholderColor: UIColor = UIColor(rgb: 0x61708B)

    public var headerBackgroundColor: UIColor = UIColor(rgb: 0xF3F8FD)
    public var headerBorderColor: UIColor  = UIColor(rgb: 0xE9EDF1)
    public var headerTextPrimaryColor: UIColor = UIColor(rgb: 0x61708B)
    public var headerTextSecondaryColor: UIColor = UIColor(rgb: 0xC8C8CD)

    public var textPrimaryColor: UIColor = UIColor(rgb: 0x2E2F32)
    public var textSecondaryColor: UIColor = UIColor(rgb: 0x9E9E9E)

    public var tintColor: UIColor = UIColor(rgb: 0x56a8e2)//03B381
    public var tintBackgroundColor: UIColor = UIColor(rgb: 0xe9fff9)
    public var unreadRoomIndentColor: UIColor = UIColor(rgb: 0x2E3648)
    public var lineBreakColor: UIColor = UIColor(rgb: 0xEEEFEF)
    
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
    public var scrollBarStyle: UIScrollView.IndicatorStyle = .default
    public var keyboardAppearance: UIKeyboardAppearance = .light

    public var placeholderTextColor: UIColor = UIColor(white: 0.7, alpha: 1.0) // Use default 70% gray color
    public var selectedBackgroundColor: UIColor?  // Use the default selection color
    public var overlayBackgroundColor: UIColor = UIColor(white: 0.7, alpha: 0.5)
    public var matrixSearchBackgroundImageTintColor: UIColor = UIColor(rgb: 0xE7E7E7)
    
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
        searchBar.barStyle = .default
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
