/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import Foundation

/// MXKRoomBubbleTableViewCell layout constants
@objcMembers
public final class RoomBubbleCellLayout: NSObject {
    
    // Reactions
    
    public static let reactionsViewTopMargin: CGFloat = 1.0
    public static let reactionsViewLeftMargin: CGFloat = 55.0
    public static let reactionsViewRightMargin: CGFloat = 15.0
    
    // Read receipts
    
    public static let readReceiptsViewTopMargin: CGFloat = 5.0
    public static let readReceiptsViewRightMargin: CGFloat = 6.0
    public static let readReceiptsViewHeight: CGFloat = 12.0
    public static let readReceiptsViewWidth: CGFloat = 150.0
    
    // Read marker
    
    public static let readMarkerViewHeight: CGFloat = 2.0
    
    // Timestamp
    
    public static let timestampLabelHeight: CGFloat = 18.0
    public static let timestampLabelWidth: CGFloat = 39.0
    
    // Others
    
    public static let encryptedContentLeftMargin: CGFloat = 15.0
}
