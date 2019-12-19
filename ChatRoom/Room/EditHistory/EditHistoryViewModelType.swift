// File created from ScreenTemplate
// $ createScreen.sh Room/EditHistory EditHistory
/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import Foundation

protocol EditHistoryViewModelViewDelegate: class {
    func editHistoryViewModel(_ viewModel: EditHistoryViewModelType, didUpdateViewState viewSate: EditHistoryViewState)
}

protocol EditHistoryViewModelCoordinatorDelegate: class {
    func editHistoryViewModelDidClose(_ viewModel: EditHistoryViewModelType)
}

/// Protocol describing the view model used by `EditHistoryViewController`
protocol EditHistoryViewModelType {
        
    var viewDelegate: EditHistoryViewModelViewDelegate? { get set }
    var coordinatorDelegate: EditHistoryViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: EditHistoryViewAction)
}
