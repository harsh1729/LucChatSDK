/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import Foundation

extension OperationQueue {
    
    class func vc_createSerialOperationQueue(name: String? = nil) -> OperationQueue {
        let coordinatorDelegateQueue = OperationQueue()
        coordinatorDelegateQueue.name = name
        coordinatorDelegateQueue.maxConcurrentOperationCount = 1
        return coordinatorDelegateQueue
    }
    
    func vc_pause() {
        self.isSuspended = true
    }
    
    func vc_resume() {
        self.isSuspended = false
    }
}
