/*
 Copyright 2018 Lintel 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import "LucNavigationController.h"

@implementation LucNavigationController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (self.topViewController)
    {
        // Return the preferred style of the top view controller.
        return [self.topViewController preferredStatusBarStyle];
    }
    
    // Keep the default UINavigationController style.
    return [super preferredStatusBarStyle];
}

- (BOOL)prefersStatusBarHidden
{
    if (self.topViewController)
    {
        // Retrieve this information from the top view controller.
        return [self.topViewController prefersStatusBarHidden];
    }
    
    // Keep the default UINavigationController mode.
    return [super prefersStatusBarHidden];
}

@end
