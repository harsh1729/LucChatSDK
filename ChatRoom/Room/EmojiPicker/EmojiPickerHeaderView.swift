/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import UIKit
import Reusable

final class EmojiPickerHeaderView: UICollectionReusableView, NibReusable {
    
    // MARK: - Properties
    
    @IBOutlet private weak var titleLabel: UILabel!
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.backgroundColor = theme.backgroundColor
        self.titleLabel.textColor = theme.headerTextPrimaryColor
    }
    
    func fill(with title: String) {
        titleLabel.text = title
    }
}
