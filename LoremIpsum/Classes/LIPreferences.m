//
//  TAPreferences.m
//  TextArtist
//
//  Created by Akki on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LIPreferences.h"
#import "NSColor+Hex.h"
#import "LIDocWindowController.h"
#import "LISettingsProxy.h"

#define standardDocType @"LISettingsStorage.docType"
#define standardTextFont @"LISettingsStorage.textFont"
#define standardTextWidth @"LISettingsStorage.textWidth"

@interface LIPreferences ()
{
    NSTextField *cssLabel;
    NSButton *cssOpenPanelButton;
    LISettingsProxy *settingsProxy;
}
@end

@implementation LIPreferences
@synthesize customCSSCheck;
@synthesize lightDarkTheme;
@synthesize onLine;
@synthesize onParagraph;
@synthesize bTextWback;
@synthesize wTextBback;

@synthesize textFont;
@synthesize textWidth;
@synthesize docType;
@synthesize controller;
@synthesize fontDescr;
@synthesize hexTextColor, hexBackColor;
@synthesize whiteBlack;
@synthesize autoshowFormatter;
@synthesize previewAutoupdate;

+ (LIPreferences *)preferencesController
{
    static LIPreferences *controller = nil;
    static dispatch_once_t predicate;
    dispatch_once( &predicate, ^{
        controller = [[LIPreferences alloc] initWithWindowNibName:@"LIPreferences"];
        
    } );
    return controller;
}

- (id)init
{
    self = [LIPreferences preferencesController];
    if (self) {
        //Init code
        [self addObserver:self forKeyPath:@"fontDescr" options:0 context:NULL];
        [self addObserver:self forKeyPath:@"docType" options:0 context:NULL];
        settingsProxy = [LISettingsProxy proxy];
        [settingsProxy addObserver:self forKeyPath:@"focusOn" options:NSKeyValueObservingOptionNew context:@"changedFocusType"];
        
        [[NSFontManager sharedFontManager] setAction:@selector(anotherFont:)];
    }
    return self;
}


- (void)windowDidLoad
{
    [super windowDidLoad];
    [self.window setMaxSize:NSMakeSize(320, 254)];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    NSString *fontName = [[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LISettingsStorage.docFont.fontName"];
    
    if ([fontName isEqualToString:@"HelveticaNeue"])
        fontName = @"Helvetica Neue";
    if ([fontName isEqualToString:@"CourierNewPSMT"])
        fontName = @"Courier New";
    
    NSString *fontSize = [NSString stringWithFormat:@"%1.0f", [[[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LISettingsStorage.docFont.fontSize"] floatValue]];
    
    [self setFontDescr:[fontName stringByAppendingString:[NSString stringWithFormat:@" %@pt", fontSize]]];
    [self setDocType:[[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LISettingsStorage.docType"]];
    [self setHexBackColor:[[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LISettingsStorage.backgroundColor"]];
    [self setHexTextColor:[[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LISettingsStorage.textColor"]];
    [self setWhiteBlack:[[[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LISettingsStorage.whiteBlack"] boolValue]];
    
    if ([[[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LISettingsStorage.markdownAutoupdate"] intValue] == 1)
        [self setPreviewAutoupdate:[NSString stringWithFormat:@"%@ second", [[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LISettingsStorage.markdownAutoupdate"]]];
    else
        [self setPreviewAutoupdate:[NSString stringWithFormat:@"%@ seconds", [[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LISettingsStorage.markdownAutoupdate"]]];
    
    switch (self.whiteBlack) {
        case YES: {
            [lightDarkTheme setSelectedSegment:0];
            break;
        }
        case NO: {
            [lightDarkTheme setSelectedSegment:1];
        }
    }
    
    //if ([[NSUserDeSharedDefaultsControllerrKeyPath:@"values.useCustomCSS"] boolValue] && ![(NSString*)[settingsProxy valueForSetting:@"customCSS"] isEqualToString:@""]) {
    if ([[settingsProxy valueForSetting:@"useCustomCSS"] boolValue] && ![(NSString*)[settingsProxy valueForSetting:@"customCSS"] isEqualToString:@""]) {
        [self useCustomCSS:customCSSCheck];
        NSString *path = [settingsProxy valueForSetting:@"customCSS"];
        [cssLabel setStringValue:[path lastPathComponent]];
    }
    else {
        [settingsProxy setValue:[NSNumber numberWithBool:NO] forSettingName:@"useCustomCSS"];
        [settingsProxy setValue:@"" forSettingName:@"customCSS"];
        if (cssLabel && cssOpenPanelButton)
            [self useCustomCSS:customCSSCheck];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"fontDescr"]) {
        
        NSArray *fComponents = [[NSArray alloc] initWithArray:[self.fontDescr componentsSeparatedByString:@" "]];
        NSString *fontName = [[NSString alloc] initWithFormat:@"%@", [fComponents objectAtIndex:0]];
        CGFloat fontSize = [[[fComponents objectAtIndex:1] stringByReplacingOccurrencesOfString:@"pt" withString:@""] floatValue];
        
        [self setTextFont:[NSFont fontWithName:fontName size:fontSize]];
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self removeObserver:self forKeyPath:@"fontDescr"];
    [self removeObserver:self forKeyPath:@"docType"];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([menuItem action] == @selector(focusOnParagraph:)) {
        switch ([[settingsProxy valueForSetting:@"focusOn"] intValue]) {
            case 1:
            case 0: {
                [menuItem setState:0];
                return YES;
            }
            case 2: {
                [menuItem setState:1];
                return YES;
            }
        }
    }
    
    if ([menuItem action] == @selector(focusOnLine:)) {
        switch ([[settingsProxy valueForSetting:@"focusOn"] intValue]) {
            case 2:
            case 0: {
                [menuItem setState:0];
                return YES;
            }
            case 1: {
                [menuItem setState:1];
                return YES;
            }
        }
    }
    
    return YES;
}

- (void)anotherFont:(id)sender
{
    NSFont *otherFont = [sender convertFont:[sender selectedFont]];
    [self setFontDescr:[[NSString stringWithFormat:@"%@", [otherFont fontName]] stringByAppendingString:[NSString stringWithFormat:@" %1.0fpt", [otherFont pointSize]]]];
    [self updateWithNewSettings:self];
}

#pragma mark
#pragma IBActions

- (IBAction)updateWithNewSettings:(id)sender
{
    NSArray *arr = [self.previewAutoupdate componentsSeparatedByString:@" "];
    NSInteger updateDelay = [[arr objectAtIndex:0] intValue];
    
    NSDictionary *fontDict = [[NSDictionary alloc] initWithObjectsAndKeys:[self.textFont fontName], @"fontName", [NSNumber numberWithFloat:[self.textFont pointSize]], @"fontSize", nil];
    NSDictionary *settingsDict = @{ @"docType":self.docType , @"docFont":fontDict , @"textColor":self.hexTextColor , @"backgroundColor":self.hexBackColor , @"textWidth":[settingsProxy valueForSetting:@"textWidth"] , @"whiteBlack":[NSNumber numberWithBool:self.whiteBlack] , @"markdownAutoupdate":[NSNumber numberWithInteger:updateDelay] };
    
    NSMutableDictionary *usDef = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"LISettingsStorage"]];
    for (NSString *key in settingsDict) {
        [usDef setValue:[settingsDict valueForKey:key] forKey:key];
    }
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LISettingsStorage"];
    [[NSUserDefaults standardUserDefaults] setObject:usDef forKey:@"LISettingsStorage"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"newSettingsArrived" object:nil userInfo:settingsDict];
}

- (IBAction)switchColorTheme:(id)sender
{    
    switch ([sender selectedSegment]) {
        case 0: {
            NSColor *aColorBack = [NSColor colorWithHex:[[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LISettingsStorage.backgroundColor"]];
            NSColor *aColorText = [NSColor colorWithHex:[[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LISettingsStorage.textColor"]];
            
            [self setWhiteBlack:YES];
            
            NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:aColorBack, @"backColor", aColorText, @"textColor", [NSNumber numberWithBool:self.whiteBlack], @"whiteBlack", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"colorScheme" object:nil userInfo:dict];
            [settingsProxy setValue:[NSNumber numberWithBool:YES] forSettingName:@"whiteBlack"];
                      
            break;
        }
        case 1: {
            NSColor *invBack = [NSColor colorWithHex:[[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LISettingsStorage.backgroundColorDark"]];
            NSColor *invText = [NSColor colorWithHex:[[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LISettingsStorage.textColorDark"]];
            [self setWhiteBlack:NO];
            
            NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:invBack, @"backColor", invText, @"textColor", self.textFont, @"textFont", [NSNumber numberWithBool:self.whiteBlack], @"whiteBlack", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"colorScheme" object:nil userInfo:dict];
            [settingsProxy setValue:[NSNumber numberWithBool:NO] forSettingName:@"whiteBlack"];    
        }
    }
    
    NSMutableDictionary *usDef = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] valueForKey:@"LISettingsStorage"]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LISettingsStorage"];
    [usDef setValue:[NSNumber numberWithBool:self.whiteBlack] forKey:@"whiteBlack"];
    [[NSUserDefaults standardUserDefaults] setObject:usDef forKey:@"LISettingsStorage"];
}

- (IBAction)focusOnParagraph:(id)sender
{
    if ([sender state] == 0)
        [settingsProxy setValue:[NSNumber numberWithInt:2] forSettingName:@"focusOn"];
    else
        [settingsProxy setValue:[NSNumber numberWithInt:0] forSettingName:@"focusOn"];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextViewDidChangeSelectionNotification object:nil];
}

- (IBAction)focusOnLine:(id)sender
{
    if ([sender state] == 0)
        [settingsProxy setValue:[NSNumber numberWithInt:1] forSettingName:@"focusOn"];
    else
        [settingsProxy setValue:[NSNumber numberWithInt:0] forSettingName:@"focusOn"];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextViewDidChangeSelectionNotification object:nil];
}

- (IBAction)useCustomCSS:(id)sender
{
    BOOL useCustomCSS = [sender state];
    
    if (useCustomCSS) {
        if (self.window.frame.size.height < self.window.maxSize.height)
            [self.window setFrame:NSMakeRect(self.window.frame.origin.x, self.window.frame.origin.y - 30, self.window.frame.size.width, self.window.frame.size.height + 30) display:YES animate:YES];
        
        if (!cssLabel) {
            cssLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(128, 24, 175, 17)];
            [cssLabel setBezeled:NO];
            [cssLabel setDrawsBackground:NO];
            [cssLabel setEditable:NO];
            [cssLabel setSelectable:NO];
            [cssLabel setFocusRingType:NSFocusRingTypeNone];
            [self.window.contentView addSubview:cssLabel];
        }
        
        if (!cssOpenPanelButton) {
            cssOpenPanelButton = [[NSButton alloc] initWithFrame:NSMakeRect(14, 14, 97, 32)];
            [cssOpenPanelButton setButtonType:NSMomentaryPushInButton];
            [cssOpenPanelButton setBezelStyle:NSRoundedBezelStyle];
            [cssOpenPanelButton setTitle:@"Browse..."];
            [cssOpenPanelButton setTarget:self];
            [cssOpenPanelButton setAction:@selector(openCssOpenPanel:)];
            [self.window.contentView addSubview:cssOpenPanelButton];
        }
    }
    
    else {
        [cssLabel removeFromSuperview];
        cssLabel = nil;
        
        [cssOpenPanelButton removeFromSuperview];
        cssOpenPanelButton = nil;
        
        [self.window setFrame:NSMakeRect(self.window.frame.origin.x, self.window.frame.origin.y + 30, self.window.frame.size.width, self.window.frame.size.height - 30) display:YES animate:YES];
        [settingsProxy setValue:@"" forSettingName:@"customCSS"];
    }
}

- (IBAction)openCssOpenPanel:(id)sender {
    
    NSOpenPanel *cssOpenPanel = [NSOpenPanel openPanel];
    
    [cssOpenPanel setAllowsMultipleSelection:NO];
    [cssOpenPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"css", @"CSS", nil]];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents directory
    [cssOpenPanel setDirectoryURL:[NSURL fileURLWithPath:documentsDirectory]];
    
    [cssOpenPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger returnCode) {
        if (returnCode == 1) {
            
            NSString *path = [[cssOpenPanel URL] path];
            [settingsProxy setValue:path forSettingName:@"customCSS"];
                        
            if ([(NSString*)[[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LISettingsStorage.customCSS"] isEqualToString:path] || [(NSString*)[[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LISettingsStorage.customCSS"] isEqualToString:@""]) {
                NSDictionary *settingsDict = [[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LISettingsStorage"];
                NSMutableDictionary *usDef = [[NSMutableDictionary alloc] initWithDictionary:settingsDict];
                for (NSString *key in settingsDict) {
                    [usDef setValue:[settingsDict valueForKey:key] forKey:key];
                }
                [usDef setValue:path forKey:@"customCSS"];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LISettingsStorage"];
                [[NSUserDefaults standardUserDefaults] setObject:usDef forKey:@"LISettingsStorage"];
                                
                [cssLabel setStringValue:[path lastPathComponent]];
            }
                
        }
    }];
}
@end
