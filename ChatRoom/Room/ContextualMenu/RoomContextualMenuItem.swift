/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import Foundation

@objcMembers
public final class RoomContextualMenuItem: NSObject {
    
    // MARK: - Properties
    
    public let title: String
    public let image: UIImage?
    
    public var isEnabled: Bool = true
    public var action: (() -> Void)?
    
    // MARK: - Setup
    
     public init(menuAction: RoomContextualMenuAction) {
        self.title = menuAction.title
        self.image = menuAction.image
        super.init()
    }
}
