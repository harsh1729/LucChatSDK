/*
 
 Copyright 2018 Lintel 
 

 

 
 */

#import <MatrixKit/MatrixKit.h>



@protocol Theme;

NS_ASSUME_NONNULL_BEGIN

/**
 Posted when the user interface theme has been changed.
 */
extern NSString *const kThemeServiceDidChangeThemeNotification;



/**
 `ThemeService` class manages the application design values.
 */
@interface ThemeService : NSObject

/**
 Returns the shared instance.

 @return the shared instance.
 */
+ (instancetype)shared;

/**
 The id of the theme being used.
 */
@property (nonatomic, nullable) NSString *themeId;

/**
 The current theme.
 Default value is the Default theme.
 */
@property (nonatomic, readonly) id<Theme> theme;

/**
 Get the theme with the given id.

 @param themeId the theme id.
 @return the theme.
 */
- (id<Theme>)themeWithThemeId:(NSString*)themeId;

#pragma mark - Riot Colors not yet themeable

@property (nonatomic, readonly) UIColor *riotColorBlue;
@property (nonatomic, readonly) UIColor *riotColorCuriousBlue;
@property (nonatomic, readonly) UIColor *riotColorIndigo;
@property (nonatomic, readonly) UIColor *riotColorOrange;

@end

NS_ASSUME_NONNULL_END
