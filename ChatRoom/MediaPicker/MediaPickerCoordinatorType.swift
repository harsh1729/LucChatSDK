// File created from FlowTemplate
// $ createRootCoordinator.sh Test MediaPicker
/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import Foundation

protocol MediaPickerCoordinatorDelegate: class {
    func mediaPickerCoordinator(_ coordinator: MediaPickerCoordinatorType, didSelectImageData imageData: Data, withUTI uti: MXKUTI?)
    func mediaPickerCoordinator(_ coordinator: MediaPickerCoordinatorType, didSelectVideoAt url: URL)
    func mediaPickerCoordinator(_ coordinator: MediaPickerCoordinatorType, didSelectAssets assets: [PHAsset])
    func mediaPickerCoordinatorDidCancel(_ coordinator: MediaPickerCoordinatorType)
}

/// `MediaPickerCoordinatorType` is a protocol describing a Coordinator that handle keybackup setup navigation flow.
protocol MediaPickerCoordinatorType: Coordinator, Presentable {
    var delegate: MediaPickerCoordinatorDelegate? { get }
}
