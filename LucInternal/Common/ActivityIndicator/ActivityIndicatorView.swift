/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import UIKit
import Reusable

final class ActivityIndicatorView: UIView, NibOwnerLoadable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let cornerRadius: CGFloat = 5.0
        static let activityIndicatorMargin = CGSize(width: 30.0, height: 30.0)
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var activityIndicatorBackgroundView: UIView!
    
    // MARK: Public
    
    var color: UIColor? {
        get {
            return activityIndicatorView.color
        }
        set {            
            activityIndicatorView.color = newValue
        }
    }
    
    // MARK: - Setup
    
    private func commonInit() {        
        self.activityIndicatorBackgroundView.layer.masksToBounds = true
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadNibContent()
        self.commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
        self.commonInit()
    }
    
    // MARK: - Overrides
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: self.activityIndicatorView.intrinsicContentSize.width + Constants.activityIndicatorMargin.width,
                      height: self.activityIndicatorView.intrinsicContentSize.height + Constants.activityIndicatorMargin.height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.activityIndicatorBackgroundView.layer.cornerRadius = Constants.cornerRadius
    }
    
    // MARK: - Public
    
    func startAnimating() {
        self.activityIndicatorView.startAnimating()
    }
    
    func stopAnimating() {
        self.activityIndicatorView.stopAnimating()
    }
}
