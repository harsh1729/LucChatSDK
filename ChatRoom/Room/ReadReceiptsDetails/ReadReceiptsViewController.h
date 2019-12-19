/*
 Copyright 2017 Aram Sargsyan
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import <UIKit/UIKit.h>
#import <MatrixKit/MatrixKit.h>

@interface ReadReceiptsViewController : MXKViewController

+ (void)openInViewController:(UIViewController *)viewController fromContainer:(MXKReceiptSendersContainer *)receiptSendersContainer withSession:(MXSession *)session;

@end
