// File created from ScreenTemplate
// $ createScreen.sh Room/EditHistory EditHistory
/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import Foundation

protocol EditHistoryCoordinatorDelegate: class {
    func editHistoryCoordinatorDidComplete(_ coordinator: EditHistoryCoordinatorType)
}

/// `EditHistoryCoordinatorType` is a protocol describing a Coordinator that handle keybackup setup navigation flow.
protocol EditHistoryCoordinatorType: Coordinator, Presentable {
    var delegate: EditHistoryCoordinatorDelegate? { get }
}
