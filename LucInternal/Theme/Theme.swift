/*
 

 

 
 */

import UIKit

/// Provide color constant values defined by the designer
/// https://app.zeplin.io/project/5c122fa790c5b4241ffa6be7/screen/5c619592daff2f1241d82e75
@objc public protocol Theme {

    var backgroundColor: UIColor { get }
    var baseColor: UIColor { get }

    var baseTextPrimaryColor: UIColor { get }
    var baseTextSecondaryColor: UIColor { get }

    var searchBackgroundColor: UIColor { get }
    var searchPlaceholderColor: UIColor { get }

    var headerBackgroundColor: UIColor { get }
    var headerBorderColor: UIColor { get }
    var headerTextPrimaryColor: UIColor { get }
    var headerTextSecondaryColor: UIColor { get }

    var textPrimaryColor: UIColor { get }
    var textSecondaryColor: UIColor { get }

    var tintColor: UIColor { get }
    var tintBackgroundColor: UIColor { get }

    var unreadRoomIndentColor: UIColor { get }

    var lineBreakColor: UIColor { get }

    var noticeColor: UIColor { get }
    var noticeSecondaryColor: UIColor { get }

    /// Color for errors or warnings
    var warningColor: UIColor { get }

    var avatarColors: [UIColor] { get }
    
    var userNameColors: [UIColor] { get }

    // MARK: - Appearance and style


    /// Status bar style to use
    var statusBarStyle: UIStatusBarStyle { get }

    var scrollBarStyle: UIScrollView.IndicatorStyle { get }

    var keyboardAppearance: UIKeyboardAppearance { get }


    // MARK: - Colors not defined in the design palette


    /// nil is used to keep the default color
    var placeholderTextColor: UIColor { get }

    /// nil is used to keep the default color
    var selectedBackgroundColor: UIColor? { get }

    /// fading behind dialog modals
    var overlayBackgroundColor: UIColor { get }

    /// Color to tint the search background image
    var matrixSearchBackgroundImageTintColor: UIColor { get }

    // MARK: - Customisation methods

    
    /// Apply the theme on a button.
    ///
    /// - Parameter tabBar: The tabBar to customise.
    func applyStyle(onTabBar tabBar: UITabBar)

    /// Apply the theme on a navigation bar
    ///
    /// - Parameter navigationBar: the navigation bar to customise.
    func applyStyle(onNavigationBar: UINavigationBar)

    ///  Apply the theme on a search bar.
    ///
    /// - Parameter searchBar: the search bar to customise.
    func applyStyle(onSearchBar: UISearchBar)
    
    ///  Apply the theme on a text field.
    ///
    /// - Parameter textField: the text field to customise.
    func applyStyle(onTextField textField: UITextField)
    
    /// Apply the theme on a button.
    ///
    /// - Parameter button: The button to customise.
    func applyStyle(onButton button: UIButton)
}
