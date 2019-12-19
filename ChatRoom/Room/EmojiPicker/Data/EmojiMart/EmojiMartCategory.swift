/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import Foundation

struct EmojiMartCategory {
    
    /// Emoji category identifier (e.g. "people")
    let identifier: String
    
    /// Emoji category name in english (e.g. "Smiley & People")
    let name: String
    
    /// List of emoji short names associated to the category (e.g. "people")
    let emojiShortNames: [String]
}

// MARK: - Decodable
extension EmojiMartCategory: Decodable {
    
    /// JSON keys associated to EmojiJSONCategory properties.
    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case name
        case emojiShortNames = "emojis"
    }
}
