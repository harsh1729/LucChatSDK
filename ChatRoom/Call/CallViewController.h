/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import <MatrixKit/MatrixKit.h>

/**
 'CallViewController' instance displays a call. Only one matrix session is supported by this view controller.
 */
@interface CallViewController : MXKCallViewController

@property (weak, nonatomic) IBOutlet UIView *gradientMaskContainerView;
@property (weak, nonatomic) IBOutlet UIButton *chatButton;
@property (weak, nonatomic) IBOutlet UILabel *lblCallState;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewCallState;

@property (unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *callerImageViewWidthConstraint;

@end
