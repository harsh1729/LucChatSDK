/*
 

 

 
 */

#import <Foundation/Foundation.h>

#import "DecryptionFailure.h"

@import MatrixSDK;

@protocol MXDecryptionFailureDelegate;

@interface DecryptionFailureTracker : NSObject

/**
 Returns the shared tracker.

 @return the shared tracker.
 */
+ (instancetype)sharedInstance;

/**
 The delegate object to receive analytics events.
 */
@property (nonatomic) id<MXDecryptionFailureDelegate> delegate;

/**
 Report an event unable to decrypt.

 This error can be momentary. The DecryptionFailureTracker will check if it gets
 fixed. Else, it will generate a failure (@see `trackFailures`).

 @param event the event.
 @param roomState the room state when the event was received.
 @param userId my user id.
 */
- (void)reportUnableToDecryptErrorForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState myUser:(NSString*)userId;

/**
 Flush current data.
 */
- (void)dispatch;

@end

/**
 The `MXDecryptionFailureDelegate` protocol receives some stats computed by
 `DecryptionFailureTracker`.
 */
@protocol MXDecryptionFailureDelegate <NSObject>

/**
 Stats for decryption failures.

 @param failuresCounts the number of errors per failure reason.
 */
- (void)trackFailures:(NSDictionary<NSString*, NSNumber*> *)failuresCounts;

@end