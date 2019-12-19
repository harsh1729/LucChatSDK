/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import Foundation

struct EmojiCategory {
    
    /// Emoji category identifier (e.g. "people")
    let identifier: String
    
    /// Emoji list associated to category
    let emojis: [EmojiItem]
    
    /// Emoji category localized name
    var name: String {
        let categoryNameLocalizationKey = "emoji_picker_\(self.identifier)_category"
        return VectorL10n.tr("Vector", categoryNameLocalizationKey)
    }
}
