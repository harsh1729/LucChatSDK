/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import Foundation

/// Protocol used to present activity indicator on a view
protocol ActivityIndicatorPresenterType {
    func presentActivityIndicator(on view: UIView, animated: Bool, completion: (() -> Void)?)
    func removeCurrentActivityIndicator(animated: Bool, completion: (() -> Void)?)
}

// `ActivityIndicatorPresenterType` default implementation
extension ActivityIndicatorPresenterType {
    func presentActivityIndicator(on view: UIView, animated: Bool) {
        self.presentActivityIndicator(on: view, animated: animated, completion: nil)
    }
    
    func removeCurrentActivityIndicator(animated: Bool) {
        self.removeCurrentActivityIndicator(animated: animated, completion: nil)
    }
}
