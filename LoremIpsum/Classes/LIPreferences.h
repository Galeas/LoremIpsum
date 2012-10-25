//
//  TAPreferences.h
//  TextArtist
//
//  Created by Akki on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LIDocument.h"

@interface LIPreferences : NSWindowController <NSWindowDelegate, NSApplicationDelegate>
{
    LITextWidth textWidth;
    NSFont *textFont;
    NSString *docType;
    __weak NSButton *wTextBback;
    __weak NSButton *bTextWback;
    __weak NSMenuItem *onParagraph;
    __weak NSMenuItem *onLine;
    __weak NSSegmentedControl *lightDarkTheme;
    __weak NSButton *customCSSCheck;
}
- (IBAction)updateWithNewSettings:(id)sender;
- (IBAction)switchColorTheme:(id)sender;
- (IBAction)focusOnParagraph:(id)sender;
- (IBAction)focusOnLine:(id)sender;
- (IBAction)useCustomCSS:(id)sender;
- (IBAction)openCssOpenPanel:(id)sender;

- (void)anotherFont:(id)sender;

@property (strong) LIPreferences *controller;

@property LITextWidth textWidth;
@property NSFont *textFont;
@property NSString *docType;
@property NSString *hexTextColor, *hexBackColor;
@property NSString *fontDescr;
@property BOOL autoshowFormatter;
@property NSString *previewAutoupdate;

@property BOOL whiteBlack;

@property (weak) IBOutlet NSButton *wTextBback;
@property (weak) IBOutlet NSButton *bTextWback;
@property (weak) IBOutlet NSMenuItem *onParagraph;
@property (weak) IBOutlet NSMenuItem *onLine;
@property (weak) IBOutlet NSSegmentedControl *lightDarkTheme;
@property (weak) IBOutlet NSButton *customCSSCheck;
@end
