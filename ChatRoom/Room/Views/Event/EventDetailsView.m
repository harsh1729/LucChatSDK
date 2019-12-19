/*
 Copyright 2018 Lintel 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import "EventDetailsView.h"

#import "ThemeService.h"
#import "LucChatSDK-Swift.h"

@implementation EventDetailsView

-(void)customizeViewRendering
{
    [super customizeViewRendering];
    
    self.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    self.textView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.textView.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.redactButton.tintColor = ThemeService.shared.theme.tintColor;
    self.closeButton.tintColor = ThemeService.shared.theme.tintColor;
}

@end
