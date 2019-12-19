/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import UIKit

extension UISearchBar {
    
    /// Returns internal UITextField
    @objc var vc_searchTextField: UITextField? {
        // TODO: To remove once on XCode11/iOS13
        #if swift(>=5.1)
            if #available(iOS 13.0, *) {
                return self.searchTextField
            } else {
                return self.value(forKey: "searchField") as? UITextField
            }
        #else
            return self.value(forKey: "searchField") as? UITextField
        #endif
    }
}
