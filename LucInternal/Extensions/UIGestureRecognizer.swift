/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import UIKit

extension UIGestureRecognizer {
    
    func vc_isTouchingInside(view: UIView? = nil) -> Bool {
        guard let view = view ?? self.view else {
            return false
        }
        let touchedLocation = self.location(in: view)
        return view.bounds.contains(touchedLocation)
    }
}