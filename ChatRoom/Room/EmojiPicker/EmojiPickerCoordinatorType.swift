// File created from ScreenTemplate
// $ createScreen.sh toto EmojiPicker
/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import Foundation

protocol EmojiPickerCoordinatorDelegate: class {
    func emojiPickerCoordinator(_ coordinator: EmojiPickerCoordinatorType, didAddEmoji emoji: String, forEventId eventId: String)
    func emojiPickerCoordinator(_ coordinator: EmojiPickerCoordinatorType, didRemoveEmoji emoji: String, forEventId eventId: String)
    func emojiPickerCoordinatorDidCancel(_ coordinator: EmojiPickerCoordinatorType)
}

/// `EmojiPickerCoordinatorType` is a protocol describing a Coordinator that handle emoji picker navigation flow.
protocol EmojiPickerCoordinatorType: Coordinator, Presentable {
    var delegate: EmojiPickerCoordinatorDelegate? { get }
}
