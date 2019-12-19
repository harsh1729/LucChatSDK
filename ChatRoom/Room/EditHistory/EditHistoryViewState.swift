// File created from ScreenTemplate
// $ createScreen.sh Room/EditHistory EditHistory
/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import Foundation

/// EditHistoryViewController view state
enum EditHistoryViewState {
    case loading
    case loaded(sections: [EditHistorySection], addedCount: Int, allDataLoaded: Bool)
    case error(Error)
}
