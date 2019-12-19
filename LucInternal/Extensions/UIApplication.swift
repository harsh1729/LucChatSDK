/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import Foundation

extension UIApplication {
    @objc func vc_open(_ url: URL, completionHandler completion: ((_ success: Bool) -> Void)? = nil) {
        
        let application = UIApplication.shared
        
        guard application.canOpenURL(url) else {
            completion?(false)
            return
        }
        
        if #available(iOS 10.0, *) {
            application.open(url, options: [:], completionHandler: { success in
                completion?(success)
            })
        } else {
            let success = application.openURL(url)
            completion?(success)
        }
    }
}
