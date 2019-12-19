/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import Foundation

@objc public enum RoomContextualMenuAction: Int {
    case copy
    case reply
    case edit
    case more
    
    // MARK: - Properties
    
    var title: String {
        let title: String
        
        switch self {
        case .copy:
            title = VectorL10n.roomEventActionCopy
        case .reply:
            title = VectorL10n.roomEventActionReply
        case .edit:
            title = VectorL10n.roomEventActionEdit
        case .more:
            title = VectorL10n.roomEventActionMore
        }
        
        return title
    }
    
    var image: UIImage? {
        let image: UIImage?
        
        switch self {
        case .copy:
            image = Asset.Images.roomContextMenuCopy.image
        case .reply:
            image = Asset.Images.roomContextMenuReply.image
        case .edit:
            image = Asset.Images.roomContextMenuEdit.image
        case .more:
            image = Asset.Images.roomContextMenuMore.image
        default:
            image = nil
        }
        
        return image
    }
}
