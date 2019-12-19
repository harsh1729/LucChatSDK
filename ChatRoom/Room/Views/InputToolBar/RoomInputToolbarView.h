/*
 

 

 
 */

#import <MatrixKit/MatrixKit.h>

#import "MediaPickerViewController.h"

/**
 Destination of the message in the composer
 */
typedef enum : NSUInteger
{
    RoomInputToolbarViewSendModeSend,
    RoomInputToolbarViewSendModeReply,
    RoomInputToolbarViewSendModeEdit
} RoomInputToolbarViewSendMode;


@protocol RoomInputToolbarViewDelegate <MXKRoomInputToolbarViewDelegate>

/**
 Tells the delegate that the user wants to display the sticker picker.

 @param toolbarView the room input toolbar view.
 */
- (void)roomInputToolbarViewPresentStickerPicker:(MXKRoomInputToolbarView*)toolbarView;

/**
 Tells the delegate that the user wants to send external files.
 
 @param toolbarView the room input toolbar view
 */
- (void)roomInputToolbarViewDidTapFileUpload:(MXKRoomInputToolbarView*)toolbarView;

/**
 Tells the delegate that the user wants to take photo or video with camera.
 
 @param toolbarView the room input toolbar view
 */
- (void)roomInputToolbarViewDidTapCamera:(MXKRoomInputToolbarView*)toolbarView;

/**
 Tells the delegate that the user wants to show media library.
 
 @param toolbarView the room input toolbar view
 */
- (void)roomInputToolbarViewDidTapMediaLibrary:(MXKRoomInputToolbarView*)toolbarView;

@end

/**
 `RoomInputToolbarView` instance is a view used to handle all kinds of available inputs
 for a room (message composer, attachments selection...).
 */
@interface RoomInputToolbarView : MXKRoomInputToolbarViewWithHPGrowingText <MediaPickerViewControllerDelegate,HPGrowingTextViewDelegate>

/**
 The delegate notified when inputs are ready.
 */
@property (nonatomic, weak) id<RoomInputToolbarViewDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIView *mainToolbarView;

@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (strong, nonatomic) IBOutlet MXKImageView *pictureView;

@property (strong, nonatomic) IBOutlet UIImageView *encryptedRoomIcon;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainToolbarMinHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainToolbarHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageComposerContainerLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageComposerContainerTrailingConstraint;

@property (weak, nonatomic) IBOutlet UIButton *attachMediaButton;
@property (weak, nonatomic) IBOutlet UIButton *voiceCallButton;
@property (weak, nonatomic) IBOutlet UIButton *hangupCallButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *voiceCallButtonWidthConstraint;

/**
 Tell whether the call option is supported. YES by default.
 */
@property (nonatomic) BOOL supportCallOption;

/**
 Tell whether the filled data will be sent encrypted. NO by default.
 */
@property (nonatomic) BOOL isEncryptionEnabled;

/**
 Destination of the message in the composer.
 */
@property (nonatomic) RoomInputToolbarViewSendMode sendMode;

/**
 Tell whether a call is active.
 */
@property (nonatomic) BOOL activeCall;

@end
