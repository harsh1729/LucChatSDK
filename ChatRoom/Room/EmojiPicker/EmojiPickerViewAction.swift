// File created from ScreenTemplate
// $ createScreen.sh toto EmojiPicker
/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import Foundation

/// EmojiPickerViewController view actions exposed to view model
enum EmojiPickerViewAction {
    case loadData
    case cancel
    case tap(emojiItemViewData: EmojiPickerItemViewData)
    case search(text: String?)
}
