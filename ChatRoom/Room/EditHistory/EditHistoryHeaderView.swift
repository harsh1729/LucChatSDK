/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import UIKit
import Reusable

final class EditHistoryHeaderView: UITableViewHeaderFooterView, NibLoadable, Reusable, Themable {
    
    // MARK: - Properties
    
    @IBOutlet private weak var dateLabel: UILabel!
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.contentView.backgroundColor = theme.backgroundColor
        self.dateLabel.textColor = theme.headerTextPrimaryColor
    }
    
    func fill(with dateString: String) {
        self.dateLabel.text = dateString
    }
}
