// File created from ScreenTemplate
// $ createScreen.sh toto EmojiPicker
/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import Foundation

protocol EmojiPickerViewModelViewDelegate: class {
    func emojiPickerViewModel(_ viewModel: EmojiPickerViewModelType, didUpdateViewState viewSate: EmojiPickerViewState)
}

protocol EmojiPickerViewModelCoordinatorDelegate: class {
    func emojiPickerViewModel(_ viewModel: EmojiPickerViewModelType, didAddEmoji emoji: String, forEventId eventId: String)
    func emojiPickerViewModel(_ viewModel: EmojiPickerViewModelType, didRemoveEmoji emoji: String, forEventId eventId: String)
    func emojiPickerViewModelDidCancel(_ viewModel: EmojiPickerViewModelType)
}

/// Protocol describing the view model used by `EmojiPickerViewController`
protocol EmojiPickerViewModelType {
            
    var viewDelegate: EmojiPickerViewModelViewDelegate? { get set }
    var coordinatorDelegate: EmojiPickerViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: EmojiPickerViewAction)
}
