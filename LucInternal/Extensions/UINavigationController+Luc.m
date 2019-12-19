/*
 
 Copyright 2018 Lintel 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import "UINavigationController+Luc.h"

@implementation UINavigationController (Riot)

- (BOOL)shouldAutorotate
{
    if (self.topViewController)
    {
        return [self.topViewController shouldAutorotate];
    }
    
    return YES;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (self.topViewController)
    {
        return [self.topViewController supportedInterfaceOrientations];
    }
    
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    if (self.topViewController)
    {
        return [self.topViewController preferredInterfaceOrientationForPresentation];
    }
    
    return UIInterfaceOrientationUnknown;
}

@end
