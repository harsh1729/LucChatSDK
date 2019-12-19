/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import Foundation

 enum BubbleReactionsViewAction {
    case loadData
    case tapReaction(index: Int)
    case addNewReaction
    case tapShowAction(action: ShowAction)
    case longPress

     enum ShowAction {
        case showAll
        case showLess
    }
}

 enum BubbleReactionsViewState {
    case loaded(reactionsViewData: [BubbleReactionViewData], showAllButtonState: ShowAllButtonState)

     enum ShowAllButtonState {
        case none
        case showAll
        case showLess
    }
}

@objc public protocol BubbleReactionsViewModelDelegate: class {
    
    func bubbleReactionsViewModel(_ viewModel: BubbleReactionsViewModel, didAddReaction reactionCount: MXReactionCount, forEventId eventId: String)
    func bubbleReactionsViewModel(_ viewModel: BubbleReactionsViewModel, didRemoveReaction reactionCount: MXReactionCount, forEventId eventId: String)
    func bubbleReactionsViewModel(_ viewModel: BubbleReactionsViewModel, didShowAllTappedForEventId eventId: String)
    func bubbleReactionsViewModel(_ viewModel: BubbleReactionsViewModel, didShowLessTappedForEventId eventId: String)
    func bubbleReactionsViewModel(_ viewModel: BubbleReactionsViewModel, didLongPressForEventId eventId: String)
}

protocol BubbleReactionsViewModelViewDelegate: class {
    func bubbleReactionsViewModel(_ viewModel: BubbleReactionsViewModel, didUpdateViewState viewState: BubbleReactionsViewState)
}

protocol BubbleReactionsViewModelType {
    var viewModelDelegate: BubbleReactionsViewModelDelegate? { get set }
    var viewDelegate: BubbleReactionsViewModelViewDelegate? { get set }
    
    func process(viewAction: BubbleReactionsViewAction)
}
