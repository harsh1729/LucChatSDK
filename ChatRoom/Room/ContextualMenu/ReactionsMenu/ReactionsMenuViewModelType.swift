/*
 

 

 
 */

import Foundation

public protocol ReactionsMenuViewModelViewDelegate: class {
    func reactionsMenuViewModel(_ viewModel: ReactionsMenuViewModel, didUpdateViewState viewState: ReactionsMenuViewState)
}

@objc public protocol ReactionsMenuViewModelCoordinatorDelegate: class {
    func reactionsMenuViewModel(_ viewModel: ReactionsMenuViewModel, didAddReaction reaction: String, forEventId eventId: String)
    func reactionsMenuViewModel(_ viewModel: ReactionsMenuViewModel, didRemoveReaction reaction: String, forEventId eventId: String)
    func reactionsMenuViewModelDidTapMoreReactions(_ viewModel: ReactionsMenuViewModel, forEventId eventId: String)
}

public protocol ReactionsMenuViewModelType {
    
    var coordinatorDelegate: ReactionsMenuViewModelCoordinatorDelegate? { get set }
    var viewDelegate: ReactionsMenuViewModelViewDelegate? { get set }
    
    func process(viewAction: ReactionsMenuViewAction)
}
