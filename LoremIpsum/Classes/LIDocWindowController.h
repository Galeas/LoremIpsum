//
//  TADocWindowController.h
//  TextArtist
//
//  Created by Akki on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "NSColor+Hex.h"

enum {
    LIMinFontSize = 0,
    LIMidFontSize = 1,
    LIMaxFontSize = 2
};
typedef NSUInteger LIFontSizeMutator;

enum {
    LITextAlignLeft = 0,
    LITextAlignCenter = 1,
    LITextAlignRight = 2,
    LITextAlignNatural = 4
};
typedef NSUInteger LITextAlignment;

enum {
    LIBold = 0,
    LIItalic = 1,
    LIUnderline = 2,
    LIBoldItalic = 3,
    LIBoldUnderline = 4,
    LIItalicUnderline = 5,
    LIBoldItalicUnderline = 6,
    LINormal = 7
};
typedef NSUInteger LIFontStyle;

@class LITextView;
@class LISplitView;
@class LIWebView;
@class LIGradientOverlayVew;

@interface LIDocWindowController : NSWindowController <NSTextViewDelegate, NSLayoutManagerDelegate, NSWindowDelegate, NSPopoverDelegate, NSSplitViewDelegate>
{
    LITextView *aTextView;
    __weak NSTextField *infoStringDisplay;
    
    __weak NSLayoutConstraint *textViewRightSpace;
    __weak NSLayoutConstraint *textViewLeftSpace;
    __weak NSScrollView *scrollContainer;
    __weak LISplitView *splitContainer;
    __weak NSSegmentedControl *fontStylesControl;
    __weak NSView *editorView;
    __strong NSView *markdownViewContainer;
    __strong LIWebView *markdownPreview;
    NSPopover *textPopover;
    NSLayoutManager *layoutMgr;
    __weak NSTimer *markdownTimer;
    
    __weak NSSegmentedControl *listSegment;
    __weak NSSegmentedControl *highlightSegment;
    __weak LIGradientOverlayVew *_gradientView;
    
    NSPopover *_markdownPopover;
    __weak NSSegmentedControl *_mdSize;
    __weak NSSegmentedControl *_mdStyle;
    __weak NSSegmentedControl *_mdList;
    __weak NSSegmentedControl *_mdHyperlink;
}

- (IBAction)showPopover:(id)sender;
- (IBAction)showHTML:(id)sender;
- (IBAction)createBookmark:(id)sender;
- (IBAction)showHideCounters:(id)sender;
- (IBAction)gotoLineOpenSheet:(id)sender;

- (IBAction)exportHTML:(id)sender;
- (IBAction)exportPDF:(id)sender;
- (IBAction)copyHTML:(id)sender;

- (IBAction)updateCountersManually:(id)sender;
- (IBAction)turnOnAutoUpdateCounters:(id)sender;

- (IBAction)richTextPlainText:(id)sender;

#pragma mark RTF formatter
- (IBAction)setFontSize:(id)sender;
- (IBAction)setTextAlignment:(id)sender;
- (IBAction)setFontStyle:(id)sender;
- (IBAction)toggleSelection:(id)sender;
- (IBAction)makeBulletList:(id)sender;

#pragma mark MD formatter
- (IBAction)setMDSize:(id)sender;
- (IBAction)setMDFontStyle:(id)sender;
- (IBAction)makeMDHyperlink:(id)sender;
- (IBAction)makeMDList:(id)sender;

- (NSFont*)fontWithTrait:(NSString*)trait onStyle:(LIFontStyle)style;

- (void)arrangeTextInView;
- (LIFontStyle)fontStyleForFont:(NSFont*)aFont atRange:(NSRange)aRange;
- (void)updateSettings:(NSNotification*)notification;
- (void)colorScheme:(NSNotification*)notification;

- (void)focusOnText;
- (void)performDropFocusWhenScrolled:(NSNotification*)notification;

- (void)updateMarkdownPreviewInstantly:(BOOL)updateNow;
- (NSString*)yarlyTimer:(NSNotification*)notification;
- (void)timerStopped;

- (NSString*)infoStringwithDocType:(NSString*)doucmentType wordsSelected:(NSUInteger)wSelected charsSelected:(NSUInteger)cSelected timerStringValue:(NSString*)timerString;
- (NSString*)simpleInfoStringWithTimerValue:(NSString*)timerString bigText:(BOOL)bigText;

- (void)insertMarkerWithIdentifier:(NSString*)identifier;

- (void)gotoLine:(int)lineNumber;
- (void)updateCounters;

- (IBAction)toggleSmartPares:(id)sender;

@property NSUInteger wordsCount;
@property NSUInteger charCount;

@property NSNumber  *fontSizeDelta;
@property NSNumber  *customTextAlignment;
@property LIFontStyle customTextStyle;
@property BOOL isList;
@property CGFloat textContainerWidth;
@property NSNumber *windowContentWidth;
@property NSString *infoString;
@property NSString *frozenInfoString;
@property NSString *frozenSelectedInfoString;
@property BOOL markdownShowed;
@property BOOL masked;
@property (strong) NSPopover *showedPopover;

@property NSString *mdPreviewPath;
@property NSString *cssPath;
@property NSString *cssHTML;

@property BOOL iAmBigText;
@property BOOL bigTextAlertShown;
@property BOOL mazochisticMode;

@property (weak) IBOutlet NSScrollView *scrollContainer;
@property (strong) IBOutlet NSPopover *textPopover;
@property (strong) IBOutlet LITextView *aTextView;
@property (weak) IBOutlet NSSegmentedControl *fontStylesControl;
@property (weak) IBOutlet LISplitView *splitContainer;
@property (weak) IBOutlet NSView *editorView;
@property (strong) IBOutlet NSView *markdownViewContainer;
@property (strong) IBOutlet LIWebView *markdownPreview;
@property (weak) NSTimer *markdownTimer;
@property (weak) IBOutlet NSSegmentedControl *listSegment;
@property (weak) IBOutlet NSSegmentedControl *highlightSegment;

@property NSLayoutManager *layoutMgr;

@property (weak) IBOutlet LIGradientOverlayVew *gradientView;
@property (strong) IBOutlet NSPopover *markdownPopover;
@property (weak) IBOutlet NSSegmentedControl *mdSize;
@property (weak) IBOutlet NSSegmentedControl *mdStyle;
@property (weak) IBOutlet NSSegmentedControl *mdList;
@property (weak) IBOutlet NSSegmentedControl *mdHyperlink;
@end
