/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import UIKit
import Reusable

final class EditHistoryCell: UITableViewCell, NibReusable, Themable {

    // MARK: - Properties
    
    @IBOutlet private weak var timestampLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    
    // MARK: - Public
    
    func fill(with timeString: String, and attributedMessage: NSAttributedString) {
        self.timestampLabel.text = timeString
        self.messageLabel.attributedText = attributedMessage
    }
    
    func update(theme: Theme) {
        self.backgroundColor = theme.backgroundColor
        self.timestampLabel.textColor = theme.textSecondaryColor
    }
}
