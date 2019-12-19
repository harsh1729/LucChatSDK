/*
 
 Copyright 2018 Lintel 
 

 

 
 */

#import "ThemeService.h"

#import "LucChatSDK-Swift.h"


NSString *const kThemeServiceDidChangeThemeNotification = @"kThemeServiceDidChangeThemeNotification";

@implementation ThemeService
@synthesize themeId = _themeId;

+ (ThemeService *)shared
{
    static ThemeService *sharedOnceInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedOnceInstance = [ThemeService new];
    });
    
    return sharedOnceInstance;
}

- (void)setThemeId:(NSString *)theThemeId
{
    // Update the current theme
    _themeId = theThemeId;
    self.theme = [self themeWithThemeId:self.themeId];
}

- (void)setTheme:(id<Theme> _Nonnull)theme
{
    _theme = theme;
    
    [self updateAppearance];

    [[NSNotificationCenter defaultCenter] postNotificationName:kThemeServiceDidChangeThemeNotification object:nil];
}

- (id<Theme>)themeWithThemeId:(NSString*)themeId
{
    id<Theme> theme;

    if ([themeId isEqualToString:@"auto"])
    {
        // Translate "auto" into a theme
        themeId = UIAccessibilityIsInvertColorsEnabled() ? @"dark" : @"light";
    }

    if ([themeId isEqualToString:@"dark"])
    {
        theme = [DarkTheme new];
    }
    else if ([themeId isEqualToString:@"black"])
    {
        theme = [BlackTheme new];
    }
    else
    {
        // Use light theme by default
        theme = [DefaultTheme new];
    }

    return theme;
}

#pragma mark - Private methods

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        // Riot Colors not yet themeable
        _riotColorBlue = [[UIColor alloc] initWithRgb:0x81BDDB];
        _riotColorCuriousBlue = [[UIColor alloc] initWithRgb:0x2A9EDB];
        _riotColorIndigo = [[UIColor alloc] initWithRgb:0xBD79CC];
        _riotColorOrange = [[UIColor alloc] initWithRgb:0xF8A15F];

        // Observe "Invert Colours" settings changes (available since iOS 11)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessibilityInvertColorsStatusDidChange) name:UIAccessibilityInvertColorsStatusDidChangeNotification object:nil];
    }
    return self;
}

- (void)accessibilityInvertColorsStatusDidChange
{
    // Refresh the theme only for "auto"
    if ([self.themeId isEqualToString:@"auto"])
    {
         self.theme = [self themeWithThemeId:self.themeId];
    }
}

- (void)updateAppearance
{
    [UIScrollView appearance].indicatorStyle = self.theme.scrollBarStyle;
    
    // Define the navigation bar text color
    [[UINavigationBar appearance] setTintColor:self.theme.tintColor];
    
    // Define the UISearchBar cancel button color
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTitleTextAttributes:@{ NSForegroundColorAttributeName : self.theme.searchPlaceholderColor }                                                                                                        forState: UIControlStateNormal];
}

@end
