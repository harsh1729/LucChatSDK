/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import Foundation

final class EmojiStore {
    
    static let shared = EmojiStore()
    
    // MARK: - Properties
    
    private var emojiCategories: [EmojiCategory] = []
    
    // MARK: - Public
    
    func getAll() -> [EmojiCategory] {
        return self.emojiCategories
    }
    
    func set(_ emojiCategories: [EmojiCategory]) {
        self.emojiCategories = emojiCategories
    }
    
    func findEmojiItemsSortedByCategory(with searchText: String) -> [EmojiCategory] {
        let initial: [EmojiCategory] = []
        
        let filteredEmojiCategories = emojiCategories.reduce(into: initial) { (filteredEmojiCategories, emojiCategory) in
            
            let filteredEmojiItems = emojiCategory.emojis.filter({ (emojiItem) -> Bool in
                
                // Do not use `String.localizedCaseInsensitiveContains` here as EmojiItem data is not localized for the moment
                
                if emojiItem.name.vc_caseInsensitiveContains(searchText) {
                    return true
                }
                
                if emojiItem.keywords.contains(where: { $0.vc_caseInsensitiveContains(searchText) }) {
                    return true
                }
                
                let shortNamesMatch = emojiItem.shortNames.contains { text -> Bool in
                    return text.vc_caseInsensitiveContains(searchText)
                }
                
                return shortNamesMatch
            })
            
            if filteredEmojiItems.isEmpty == false {
                let filteredEmojiCategory = EmojiCategory(identifier: emojiCategory.identifier, emojis: filteredEmojiItems)
                filteredEmojiCategories.append(filteredEmojiCategory)
            }
        }
        
        return filteredEmojiCategories
    }
}
