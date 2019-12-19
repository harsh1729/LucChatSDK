/*
 
 Copyright 2018 Lintel 
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import "CallViewController.h"

#import "LucChatSDK-Swift.h"

#import "AvatarGenerator.h"

#import "IncomingCallView.h"
#import "LucUtility.h"
#import "ThemeService.h"

@interface CallViewController ()
{
    // Display a gradient view above the screen
    CAGradientLayer* gradientMaskLayer;
    
    // Current alert (if any).
    UIAlertController *currentAlert;
    
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;
    
    // Observers to manage ongoing conference call banner
    id kMXCallStateDidChangeObserver;
}

@end

@implementation CallViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.backToAppButton setImage:[UIImage imageNamed:@"back_icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [self.backToAppButton setImage:[UIImage imageNamed:@"back_icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forState:UIControlStateHighlighted];
    
    [self.cameraSwitchButton setImage:[UIImage imageNamed:@"camera_switch" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [self.cameraSwitchButton setImage:[UIImage imageNamed:@"camera_switch" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forState:UIControlStateHighlighted];
    
    [self.audioMuteButton setImage:[UIImage imageNamed:@"call_audio_mute_off_icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [self.audioMuteButton setImage:[UIImage imageNamed:@"call_audio_mute_off_icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forState:UIControlStateHighlighted];
    [self.audioMuteButton setImage:[UIImage imageNamed:@"call_audio_mute_on_icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    [self.videoMuteButton setImage:[UIImage imageNamed:@"call_video_mute_off_icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [self.videoMuteButton setImage:[UIImage imageNamed:@"call_video_mute_off_icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forState:UIControlStateHighlighted];
    [self.videoMuteButton setImage:[UIImage imageNamed:@"call_video_mute_on_icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    [self.speakerButton setImage:[UIImage imageNamed:@"call_speaker_off_icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [self.speakerButton setImage:[UIImage imageNamed:@"call_speaker_on_icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    [self.chatButton setImage:[UIImage imageNamed:@"call_chat_icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [self.chatButton setImage:[UIImage imageNamed:@"call_chat_icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forState:UIControlStateHighlighted];
    
    [self.endCallButton setTitle:nil forState:UIControlStateNormal];
    [self.endCallButton setTitle:nil forState:UIControlStateHighlighted];
    [self.endCallButton setImage:[UIImage imageNamed:@"call_hangup_icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [self.endCallButton setImage:[UIImage imageNamed:@"call_hangup_icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forState:UIControlStateHighlighted];
    
    // Define caller image view size
    CGSize size = [[UIScreen mainScreen] bounds].size;
    CGFloat minSize = MIN(size.width, size.height);
    self.callerImageViewWidthConstraint.constant = minSize / 2;
    
    [self updateLocalPreviewLayout];
    
    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    self.barTitleColor = ThemeService.shared.theme.textPrimaryColor;
    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    self.callerNameLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.callStatusLabel.textColor = ThemeService.shared.theme.baseTextSecondaryColor;
    
    self.localPreviewContainerView.layer.borderColor = ThemeService.shared.theme.tintColor.CGColor;
    self.localPreviewContainerView.layer.borderWidth = 2;
    self.localPreviewContainerView.layer.cornerRadius = 5;
    self.localPreviewContainerView.clipsToBounds = YES;
    
    self.remotePreviewContainerView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    if (gradientMaskLayer)
    {
        [gradientMaskLayer removeFromSuperlayer];
    }
    
    // Add a gradient mask programatically at the top of the screen (background of the call information (name, status))
    gradientMaskLayer = [CAGradientLayer layer];
    
    // Consider the grayscale components of the ThemeService.shared.theme.backgroundColor.
    CGFloat white = 1.0;
    [ThemeService.shared.theme.backgroundColor getWhite:&white alpha:nil];
    
    CGColorRef opaqueWhiteColor = [UIColor colorWithWhite:white alpha:1.0].CGColor;
    CGColorRef transparentWhiteColor = [UIColor colorWithWhite:white alpha:0].CGColor;
    
    gradientMaskLayer.colors = @[(__bridge id) opaqueWhiteColor, (__bridge id) transparentWhiteColor];
    
    gradientMaskLayer.bounds = CGRectMake(0, 0, self.callContainerView.frame.size.width, self.callContainerView.frame.size.height + 20);
    gradientMaskLayer.anchorPoint = CGPointZero;
    
    // CAConstraint is not supported on IOS.
    // it seems only being supported on Mac OS.
    // so viewDidLayoutSubviews will refresh the layout bounds.
    [self.gradientMaskContainerView.layer addSublayer:gradientMaskLayer];
}

- (BOOL)prefersStatusBarHidden
{
    // Hide the status bar on the call view controller.
    return YES;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // sanity check
    if (gradientMaskLayer)
    {
        CGRect currentBounds = gradientMaskLayer.bounds;
        CGRect newBounds = CGRectMake(0, 0, self.callContainerView.frame.size.width, self.callContainerView.frame.size.height + 20);
        
        // check if there is an update
        if (!CGSizeEqualToSize(currentBounds.size, newBounds.size))
        {
            newBounds.origin = CGPointZero;
            gradientMaskLayer.bounds = newBounds;
        }
    }
    
    // The caller image view is circular
    self.callerImageView.layer.cornerRadius = self.callerImageViewWidthConstraint.constant / 2;
    self.callerImageView.clipsToBounds = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    [super viewWillDisappear:animated];
    
    [self removeCallNotificationsListeners];
}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    
    [self listenCallNotifications];
}

- (void)dealloc
{
}

#pragma mark - override MXKViewController

- (void)destroy
{
    [super destroy];
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
    
    [gradientMaskLayer removeFromSuperlayer];
    gradientMaskLayer = nil;
    
    [self removeCallNotificationsListeners];
}

- (UIView *)createIncomingCallView
{
    NSString *callInfo;
    if (self.mxCall.isVideoCall)
        callInfo = NSLocalizedStringFromTableInBundle(@"call_incoming_video", @"Vector",[NSBundle bundleForClass:[self class]], nil);
    else
        callInfo = NSLocalizedStringFromTableInBundle(@"call_incoming_voice", @"Vector",[NSBundle bundleForClass:[self class]], nil);
    
    IncomingCallView *incomingCallView = [[IncomingCallView alloc] initWithCallerAvatar:self.peer.avatarUrl
                                                                           mediaManager:self.mainSession.mediaManager
                                                                       placeholderImage:self.picturePlaceholder
                                                                             callerName:self.peer.displayname
                                                                               callInfo:callInfo];
    
    // Incoming call is retained by call vc so use weak to avoid retain cycle
    __weak typeof(self) weakSelf = self;
    
    incomingCallView.onAnswer = ^{
        [weakSelf onButtonPressed:weakSelf.answerCallButton];
    };
    
    incomingCallView.onReject = ^{
        [weakSelf onButtonPressed:weakSelf.rejectCallButton];
    };
    
    return incomingCallView;
}

#pragma mark - MXCallDelegate

- (void)call:(MXCall *)call didEncounterError:(NSError *)error
{
    if ([error.domain isEqualToString:MXEncryptingErrorDomain]
        && error.code == MXEncryptingErrorUnknownDeviceCode)
    {
        // There are unknown devices, check what the user wants to do
        NSLog(@"There are unknown devices");
    }
    else
    {
        [super call:call didEncounterError:error];
    }
}

#pragma mark - Call notifications management

- (void)removeCallNotificationsListeners
{
    if (kMXCallStateDidChangeObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kMXCallStateDidChangeObserver];
        kMXCallStateDidChangeObserver = nil;
    }
    
}

- (void)listenCallNotifications
{
    kMXCallStateDidChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallStateDidChange object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXCall *call = notif.object;
        
        if (call != nil){
            
            MXCallState state = call.state;
            
            if (MXCallStateConnected == state)
            {
                self.imageViewCallState.image = [UIImage imageNamed:@"call_connected" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
                self.lblCallState.text = @"Connected";
            }
            else if (MXCallStateConnecting == state){
                
                self.imageViewCallState.image = [UIImage imageNamed:@"call_connecting" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
                self.lblCallState.text = @"Connecting";
            }
            else if (MXCallStateEnded == state)
            {
                self.imageViewCallState.image = nil;
                self.lblCallState.text = @"Call Ended";
            }
            else if (MXCallStateInviteSent == state){
                
                self.imageViewCallState.image = [UIImage imageNamed:@"call_connecting" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
                self.lblCallState.text = @"Connecting";
            }
        }
        
    }];
    
}


#pragma mark - Properties

- (UIImage*)picturePlaceholder
{
    CGFloat fontSize = floor(self.callerImageViewWidthConstraint.constant * 0.7);
    
    if (self.peer)
    {
        // Use the vector style placeholder
        return [AvatarGenerator generateAvatarForMatrixItem:self.peer.userId withDisplayName:self.peer.displayname size:self.callerImageViewWidthConstraint.constant andFontSize:fontSize];
    }
    else if (self.mxCall.room)
    {
        return [AvatarGenerator generateAvatarForMatrixItem:self.mxCall.room.roomId withDisplayName:self.mxCall.room.summary.displayname size:self.callerImageViewWidthConstraint.constant andFontSize:fontSize];
    }
    
    return [MXKTools paintImage:[UIImage imageNamed:@"placeholder" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil]
                      withColor:ThemeService.shared.theme.tintColor];
}

- (void)setMxCall:(MXCall *)call
{
    [super setMxCall:call];
    
    self.callerImageView.hidden = self.mxCall.isVideoCall;
}

- (void)updatePeerInfoDisplay
{
    NSString *peerDisplayName;
    NSString *peerAvatarURL;
    
    if (self.peer)
    {
        peerDisplayName = [self.peer displayname];
        if (!peerDisplayName.length)
        {
            peerDisplayName = self.peer.userId;
        }
        peerAvatarURL = self.peer.avatarUrl;
    }
    else if (self.mxCall.isConferenceCall)
    {
        peerDisplayName = self.mxCall.room.summary.displayname;
        peerAvatarURL = self.mxCall.room.summary.avatar;
    }
    
    self.callerNameLabel.text = peerDisplayName;
    
    self.callerImageView.contentMode = UIViewContentModeScaleAspectFill;
    if (peerAvatarURL)
    {
        // Retrieve the avatar in full resolution
        [self.callerImageView setImageURI:peerAvatarURL
                                 withType:nil
                      andImageOrientation:UIImageOrientationUp
                             previewImage:self.picturePlaceholder
                             mediaManager:self.mainSession.mediaManager];
    }
    else
    {
        self.callerImageView.image = self.picturePlaceholder;
    }
}

- (void)showOverlayContainer:(BOOL)isShown
{
    [super showOverlayContainer:isShown];
    
    self.gradientMaskContainerView.hidden = self.overlayContainerView.isHidden;
}

#pragma mark - Sounds

- (NSURL*)audioURLWithName:(NSString*)soundName
{
    NSURL *audioUrl;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:soundName ofType:@"mp3"];
    if (path)
    {
        audioUrl = [NSURL fileURLWithPath:path];
    }
    
    // Use by default the matrix kit sounds.
    if (!audioUrl)
    {
        audioUrl = [super audioURLWithName:soundName];
    }
    
    return audioUrl;
}

#pragma mark - Actions

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == _chatButton)
    {
        if (self.delegate)
        {
            // Dismiss the view controller whereas the call is still running
            [self.delegate dismissCallViewController:self completion:^{
                
                if (self.mxCall.room)
                {
                    // Open the room page
                    [[LucUtility instance] showRoom:self.mxCall.room.roomId andEventId:nil withMatrixSession:self.mxCall.room.mxSession];
                }
                
            }];
        }
    }
    else
    {
        [super onButtonPressed:sender];
    }
}

@end
