/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import UIKit
import Reusable

final class RoomContextualMenuToolbarView: MXKRoomInputToolbarView, NibOwnerLoadable, Themable {
    
    // MARK: - Constants
    
    private enum Constants {        
        static let menuItemMinWidth: CGFloat = 50.0
        static let menuItemMaxWidth: CGFloat = 80.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var menuItemsStackView: UIStackView!
    @IBOutlet private weak var separatorView: UIView!
    
    // MARK: Private
    
    private var theme: Theme?
    private var menuItemViews: [ContextualMenuItemView] = []
    
    // MARK: - Public
    
    @objc func update(theme: Theme) {
        self.theme = theme
        self.backgroundColor = theme.backgroundColor
        self.tintColor = theme.tintColor
        self.separatorView.backgroundColor = theme.lineBreakColor
        
        for menuItemView in self.menuItemViews {
            menuItemView.titleColor = theme.tintColor
            menuItemView.imageColor = theme.tintColor            
        }
    }
    
    @objc func fill(contextualMenuItems: [RoomContextualMenuItem]) {
        self.menuItemsStackView.vc_removeAllSubviews()
        self.menuItemViews.removeAll()
        
        for menuItem in contextualMenuItems {
            let menuItemView = ContextualMenuItemView()
            menuItemView.fill(menuItem: menuItem)
            
            if let theme = theme {
                menuItemView.titleColor = theme.textPrimaryColor
                menuItemView.imageColor = theme.tintColor                                
            }
            
            self.add(menuItemView: menuItemView)
        }
        
        self.layoutIfNeeded()
    }
    
    // MARK: - Setup
    
    private func commonInit() {
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        self.loadNibContent()
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadNibContent()
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
        commonInit()
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    // MARK: - Private
    
    private func add(menuItemView: ContextualMenuItemView) {
        let menuItemContentView = UIView()
        menuItemContentView.backgroundColor = .clear
        
        self.add(menuItemView: menuItemView, on: menuItemContentView)
        
        self.menuItemsStackView.addArrangedSubview(menuItemContentView)
        
        let widthConstraint = menuItemContentView.widthAnchor.constraint(equalTo: self.menuItemsStackView.widthAnchor)
        widthConstraint.priority = .defaultLow
        widthConstraint.isActive = true
        
        self.menuItemViews.append(menuItemView)
    }
    
    private func add(menuItemView: ContextualMenuItemView, on contentView: UIView) {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        menuItemView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(menuItemView)
        
        menuItemView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        menuItemView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true           
        
        let widthConstraint = menuItemView.widthAnchor.constraint(equalToConstant: 0.0)
        widthConstraint.priority = .defaultLow
        widthConstraint.isActive = true
        
        let minWidthConstraint = menuItemView.widthAnchor.constraint(greaterThanOrEqualToConstant: Constants.menuItemMinWidth)
        minWidthConstraint.priority = .required
        minWidthConstraint.isActive = true
        
        let maxWidthConstraint = menuItemView.widthAnchor.constraint(lessThanOrEqualToConstant: Constants.menuItemMaxWidth)
        maxWidthConstraint.priority = .required
        maxWidthConstraint.isActive = true
    }
}
