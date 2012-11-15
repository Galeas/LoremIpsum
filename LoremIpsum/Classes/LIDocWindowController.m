//
//  TADocWindowController.m
//  TextArtist
//
//  Created by Akki on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LIDocWindowController.h"
#import "LIDocument.h"
#import "LITextView.h"
#import "LISplitView.h"
#import "LITimedWritingController.h"
#import "NSString+Trimming.h"
#import "LIGoToLineController.h"
#import "LITextAttachmentCell.h"
#import "ESSImageCategory.h"
#import "LIWebView.h"
#import "LIBackColoredView.h"
//#import "LIScalingScrollView.h"
#import "LIGradientOverlayVew.h"
#import "LISettingsProxy.h"

#import <QuartzCore/QuartzCore.h>
#import <ORCDiscount/ORCDiscount.h>

static NSString *cssDragType = @"cssDragType";

@interface LIDocWindowController ()
{
    @private
        BOOL isPopoverShown;
        NSRect popoverRelativeRect;
        NSPopover *showedPopover;
    
        CGFloat splitviewSizeBefore, splitviewSizeAfter;
    
        NSTimeInterval whenToUpdate;
    
        LIGoToLineController *gotoSheet;
    
        NSParagraphStyle *paraStyle;
    
        NSString *_cssPath;
        NSString *_cssHTML;
        NSPoint previewPosition;
        CGFloat dividerPosition;
    
        LISettingsProxy *settingsProxy;
}
@end

@implementation LIDocWindowController
@synthesize highlightSegment;
@synthesize listSegment;
@synthesize markdownPreview;
@synthesize markdownViewContainer;
@synthesize editorView;
@synthesize splitContainer;
@synthesize fontStylesControl;
@synthesize aTextView;
@synthesize textPopover;
@synthesize scrollContainer;

@synthesize textContainerWidth;
@synthesize windowContentWidth;

@synthesize infoString, frozenInfoString, frozenSelectedInfoString;

@synthesize wordsCount;
@synthesize charCount;

@synthesize fontSizeDelta, customTextAlignment, customTextStyle, isList;
@synthesize markdownShowed;
@synthesize markdownTimer;

@synthesize masked;

@synthesize mdPreviewPath;
@synthesize cssPath = _cssPath;
@synthesize cssHTML = _cssHTML;

@synthesize iAmBigText, mazochisticMode, bigTextAlertShown;
@synthesize layoutMgr = layoutMgr;

- (id)initWithWindow:(NSWindow *)window
{
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        layoutMgr = [[NSLayoutManager alloc] init];
        [layoutMgr setDelegate:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSettings:) name:@"newSettingsArrived" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorScheme:) name:@"colorScheme" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yarlyTimer:) name:@"yarlyTimer" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timerStopped) name:@"timerStopped" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(buffLayer) name:@"buffLayer" object:nil];
        
        [self setMarkdownShowed:NO];
        [self setMazochisticMode:NO];
        [self setIAmBigText:NO];
        [self setBigTextAlertShown:NO];
        
        whenToUpdate = [[NSDate distantFuture] timeIntervalSinceReferenceDate];
        settingsProxy = [LISettingsProxy proxy];
        
    }
    
    return self;
}

- (void)window:(NSWindow *)window didDecodeRestorableState:(NSCoder *)state
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    if (state)
        [self arrangeTextInView];
}

- (void)windowDidLoad
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    [super windowDidLoad];
    if ([[settingsProxy valueForSetting:@"showCounts"] boolValue])
        [self setInfoString:[self simpleInfoStringWithTimerValue:nil bigText:self.iAmBigText]];
    
    if ([[settingsProxy valueForSetting:@"focusOn"] intValue] > 0)
        [self setMasked:YES];
    else
        [self setMasked:NO];

    [[NSNotificationCenter defaultCenter] addObserverForName:NSTextViewDidChangeSelectionNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note)
     {
         clock_t start = clock();
         BOOL countersShown = [[settingsProxy valueForSetting:@"showCounts"] boolValue];
         
         if (countersShown) {
             [self updateCounters];
         }
         
         if (self.masked)
             [self focusOnText];
    
        whenToUpdate = [NSDate timeIntervalSinceReferenceDate] + 0.5;
         
         clock_t finish = clock(); // на выходе из участка кода
         clock_t duration = finish - start;
         
         if ((duration > 60000) && !self.iAmBigText && !self.bigTextAlertShown) {
             NSString *cmd = [NSString stringWithUTF8String:"\u2318"];
             NSString *ctrl = [NSString stringWithUTF8String:"\u2303"];
             
             NSAlert *alert = [NSAlert alertWithMessageText:@"Seems your text is too large." defaultButton:@"Ok." alternateButton:@"" otherButton:@"" informativeTextWithFormat:@"So we will turn off counter but you still can update them manually using %@+%@+C.", cmd, ctrl];
             [alert setAlertStyle:NSCriticalAlertStyle];
             [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
             
             [self setIAmBigText:YES];
             [self setBigTextAlertShown:YES];
             [aTextView setNeedsDisplay:YES];
             
             return;
         }
     } ];
    
    [scrollContainer.contentView setPostsBoundsChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(performDropFocusWhenScrolled:) name:NSViewBoundsDidChangeNotification object:scrollContainer.contentView];
    
    [self addObserver:self forKeyPath:@"windowContentWidth" options:0 context:@"windowSizeChanged"];
    [self addObserver:self forKeyPath:@"masked" options:0 context:@"removeMask"];
    
    [settingsProxy addObserver:self forKeyPath:@"focusOn" options:0 context:@"focusModeChanged"];
    [settingsProxy addObserver:self forKeyPath:@"useCustomCSS" options:0 context:@"useCSS"];
    [settingsProxy addObserver:self forKeyPath:@"whiteBlack" options:0 context:@"mdPreviewColor"];
    
    [[aTextView textContainer] setWidthTracksTextView:YES];
    [aTextView setUsesFindBar:YES];
    [aTextView setIncrementalSearchingEnabled:YES];
    [aTextView setAllowsUndo:YES];
    
    BOOL whiteBlack = [[settingsProxy valueForSetting:@"whiteBlack"] boolValue];
    NSColor *caretColor, *selectionFore, *selectionBack;
    whiteBlack ? (caretColor = [NSColor colorWithHex:@"#444444"]) : (caretColor = [NSColor colorWithHex:@"#F2F2F2"]);
    whiteBlack ? (selectionFore = [NSColor colorWithHex:[[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.textColor"]]) : (selectionFore = [NSColor colorWithHex:@"#808080"]);
    whiteBlack ? (selectionBack = [NSColor colorWithHex:@"#B4D4FF"]) : (selectionBack = [NSColor colorWithHex:@"#333333"]);
    [aTextView  setInsertionPointColor:caretColor];
    [aTextView setSelectedTextAttributes:@{ NSForegroundColorAttributeName:selectionFore , NSBackgroundColorAttributeName:selectionBack}];
    
    
    if ([editorView bounds].size.width - self.textContainerWidth > 50) {
        [aTextView setTextContainerInset:NSMakeSize(([aTextView bounds].size.width-self.textContainerWidth)/2, 20)];
        [[aTextView textContainer] setContainerSize:NSMakeSize(self.textContainerWidth, [[aTextView textContainer] containerSize].height)];
    } else {
        [aTextView setTextContainerInset:NSMakeSize(20, 20)];
        [[aTextView textContainer] setContainerSize:NSMakeSize(aTextView.bounds.size.width - 40, [[aTextView textContainer] containerSize].height)];
    }
    
    [layoutMgr addTextContainer:[aTextView textContainer]];
    [self updateSettings:nil];
    
    [[layoutMgr firstTextView] setNeedsDisplay:YES];
    [self.window setMinSize:NSMakeSize(400.0f, 300.0f)];
    
    NSColor *backColor = [(LIBackColoredView*)[[self.splitContainer subviews] objectAtIndex:0] background];
    [self.gradientView setGradientColor:backColor];
    
    NSMenu *substMenu = [[[self.aTextView menu] itemWithTitle:@"Substitutions"] submenu];
    BOOL needAddMenuItem = YES;
    NSInteger foundIndex = 0;
    for (NSMenuItem *item in substMenu.itemArray) {
        if ([item.title isEqualToString:@"Smart Pairs"]) {
            needAddMenuItem = NO;
            foundIndex = [substMenu indexOfItem:item];
            break;
        }
    }
    if (needAddMenuItem) {
        NSMenuItem *smartParesItem = [[NSMenuItem alloc] initWithTitle:@"Smart Pares" action:@selector(toggleSmartPares:) keyEquivalent:@""];
        [substMenu insertItem:smartParesItem atIndex:substMenu.itemArray.count-5];
        [smartParesItem setState:[[settingsProxy valueForSetting:@"useSmartPares"] boolValue]];
    }
    else
        [[substMenu itemAtIndex:foundIndex] setState:[[settingsProxy valueForSetting:@"useSmartPares"] boolValue]];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{    //NSLog(@"%s", __PRETTY_FUNCTION__);
    if ([(__bridge_transfer NSString*)context isEqualToString:@"windowSizeChanged"]) {        
        [self arrangeTextInView];
    }
    
    else if ([(__bridge_transfer NSString*)context isEqualToString:@"focusModeChanged"]) {
        NSUInteger focusMode = [[settingsProxy valueForSetting:@"focusOn"] intValue];
        if (focusMode > 0)
            [self setMasked:YES];
        else
            [self setMasked:NO];
    }
    
    else if ([(__bridge_transfer NSString*)context isEqualToString:@"removeMask"]) {
        if (!self.masked)
            [self.gradientView removeFocus];
    }
    
    else if ([(__bridge_transfer NSString*)context isEqualToString:@"useCSS"] || [(__bridge_transfer NSString*)context isEqualToString:@"mdPreviewColor"]) {
        [self updateMarkdownPreviewInstantly:YES];
    }
    
    else 
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)setDocument:(LIDocument *)document
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    if (document) {
        [[document textStorage] addLayoutManager:layoutMgr];
    }
    [super setDocument:document];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    if ([menuItem action] == @selector(showHideCounters:)) {
        if ([[self.gradientView infoLayer]  isHidden]) {
            [menuItem setTitle:@"Show counters"];
            return YES;
        } else {
            [menuItem setTitle:@"Hide counters"];
            return YES;
        }
    }
    
    if ([menuItem action] == @selector(showHTML:)) {
        if ([[self.document docType] isEqualToString:RTF])
            return NO;
        else {
            if (splitContainer.subviews.count == 1 || [(NSView*)[splitContainer.subviews objectAtIndex:1] isHidden])
                [menuItem setState:0];
            else
                [menuItem setState:1];
            return YES;
        }
    }
    
    if ([menuItem action] == @selector(updateCountersManually:)) {
        if (self.iAmBigText)
            return YES;
        return NO;
    }
    
    if ([menuItem action] == @selector(turnOnAutoUpdateCounters:)) {
        if (self.iAmBigText && !self.mazochisticMode) {
            [menuItem setTitle:@"Turn on auto-update"];
            [menuItem setHidden:NO];
            return YES;
        } else if (self.iAmBigText && self.mazochisticMode) {
            [menuItem setTitle:@"Turn off auto-update"];
            [menuItem setHidden:NO];
            return YES;
        } 
        
        else {
            [menuItem setHidden:YES];
            return NO;
        }
    }
    
    if ([menuItem action] == @selector(richTextPlainText:)) {
        if ([[self.document fileType] isEqualToString:(NSString*)kUTTypeRTF] || [[self.document fileType] isEqualToString:(NSString*)kUTTypeRTFD])
            [menuItem setTitle:@"Convert to Markdown (Plain Text)"];
        else
            [menuItem setTitle:@"Convert to Rich Format Text"];
        return  YES;
    }
    
    if ([menuItem action] == @selector(setFontStyle:)) {
        if ([[aTextView string] length] == 0) {
            [menuItem setState:0];
            return YES;
        }
        
        LIFontStyle style = [self fontStyleForFont:[aTextView currentFont] atRange:[aTextView selectedRange]];
        if ([[self.document docType] isEqualToString:RTF]) {
            if ([[menuItem title] isEqualToString:@"Bold"]) {
                if (style == LIBold || style == LIBoldItalic || style == LIBoldUnderline || style == LIBoldItalicUnderline)
                    [menuItem setState:1];
                else
                    [menuItem setState:0];
            }
            else if ([[menuItem title] isEqualToString:@"Italic"]) {
                if (style == LIItalic || style == LIBoldItalic || style == LIItalicUnderline || style == LIBoldItalicUnderline)
                    [menuItem setState:1];
                else
                    [menuItem setState:0];
            }
            else if ([[menuItem title] isEqualToString:@"Underline"]) {
                if (style == LIUnderline || style == LIBoldUnderline || style == LIItalicUnderline || style == LIBoldItalicUnderline)
                    [menuItem setState:1];
                else
                    [menuItem setState:0];
            }
            return YES;
        }
        
        [menuItem setState:0];
        return NO;
    }
    
    if ([menuItem action] == @selector(setTextAlignment:)) {
        
        if ([[self.document docType] isEqualToString:RTF]) {
            
            if (menuItem.isHidden) {
                [[menuItem.menu itemAtIndex:13] setHidden:NO];
                [menuItem setHidden:NO];
            }
            
            if ([[aTextView string] length] == 0) {
                [menuItem setState:0];
                return YES;
            }
            
            NSRange activeRange = [aTextView selectedRange];
            if (activeRange.length == 0)
                activeRange.length = 1;
            
            NSRange paragraphRange = [[[aTextView textStorage] string] paragraphRangeForRange:[aTextView selectedRange]];
            NSParagraphStyle *style = [aTextView styleForParagraphRange:paragraphRange];
            
            switch ([style alignment]) {
                case NSLeftTextAlignment: {
                    [[menuItem title] isEqualToString:@"Align Left"] ? [menuItem setState:1] : [menuItem setState:0];
                    break;
                }
                case NSCenterTextAlignment: {
                    [[menuItem title] isEqualToString:@"Center"] ? [menuItem setState:1] : [menuItem setState:0];
                    break;
                }
                case NSJustifiedTextAlignment: {
                    [[menuItem title] isEqualToString:@"Justify"] ? [menuItem setState:1] : [menuItem setState:0];
                    break;
                }
                case NSRightTextAlignment: {
                    [[menuItem title] isEqualToString:@"Align Right"] ? [menuItem setState:1] : [menuItem setState:0];
                    break;
                }
                default: {
                    [menuItem setState:0];
                    break;
                }
            }
            return YES;
        }
        
        else if (!menuItem.isHidden) {
            [[menuItem.menu itemAtIndex:13] setHidden:YES];
            [menuItem setHidden:YES];
        }
        return NO;
    }
    
    if ([menuItem action] == @selector(showHTML:)) {
        if ([[self.document fileType] compare:(NSString*)kUTTypePlainText]) {
            if ([[splitContainer subviews] count] > 1)
                [menuItem setTitle:@"Hide Markdown Preview"];
            else
                [menuItem setTitle:@"Preview Markdown"];
            return YES;
        }
        else {
            [menuItem setTitle:@"Preview Markdown"];
            return NO;
        }
    }
    
    if ([menuItem action] == @selector(copyHTML:) || [menuItem action] == @selector(setMDSize:)) {
        if ([[self.document docType] isEqualToString:TXT])
            return YES;
        else
            return NO;
    }
    
    if ([menuItem action] == @selector(toggleSmartPares:)) {
        BOOL needState = [[settingsProxy valueForSetting:@"useSmartPares"] boolValue];
        [menuItem setState:needState];
        return YES;
    }
    
    if ([menuItem action] == @selector(toggleSelection:)) {
        if ([[self.document docType] isEqualTo:TXT])
            return NO;
        return YES;
    }
    
    return YES;
    
}

- (void)windowDidExitVersionBrowser:(NSNotification *)notification
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    [[self.document textStorage] addLayoutManager:layoutMgr];
}

#pragma mark
#pragma mark ---- Custom Methods ----

- (void)updateSettings:(NSNotification *)notification
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    NSDictionary *settings;
    NSColor *textColor, *backColor;
    NSFont *aNewFont;
    
    NSTextStorage *activeStorage = [aTextView textStorage];
    
    if (notification == nil) {
        settings = [settingsProxy settings];
        aNewFont = [self.document docFont:[settings valueForKey:@"docFont"]];
        
        switch ([[settings valueForKey:@"whiteBlack"] boolValue]) {
            case YES: {
                textColor = [NSColor colorWithHex:[settings valueForKey:@"textColor"]];
                backColor = [NSColor colorWithHex:[settings valueForKey:@"backgroundColor"]];
            
                break;
            }
            case NO: {
                textColor = [NSColor colorWithHex:[settings valueForKey:@"textColorDark"]];
                backColor = [NSColor colorWithHex:[settings valueForKey:@"backgroundColorDark"]];
                
                break;
            }
        }
        
        [activeStorage beginEditing];
        if (![self.document fileURL])
            [activeStorage setFont:aNewFont];
        [activeStorage endEditing];
        
        [settingsProxy setValue:[backColor hexColor] forSettingName:@"backgroundColor"];
        [settingsProxy setValue:[textColor hexColor] forSettingName:@"textColor"];
        [settingsProxy setValue:[settings valueForKey:@"docFont"] forSettingName:@"docFont"];
        [self.gradientView setGradientColor:backColor];
    }
    else {        
        NSFont *settedFont = [self.document docFont:(NSDictionary*)[[notification userInfo] objectForKey:@"docFont"]];
        aNewFont = settedFont;

        switch ([[[notification userInfo] valueForKey:@"whiteBlack"] boolValue]) {
            case YES: {
                textColor = [NSColor colorWithHex:[[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LIInitSettings.textColor"]];
                backColor = [NSColor colorWithHex:[[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LIInitSettings.backgroundColor"]];
                break;
            }
            case NO: {
                backColor = [NSColor colorWithHex:[[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LIInitSettings.backgroundColorDark"]];
                textColor = [NSColor colorWithHex:[[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LIInitSettings.textColorDark"]];
                break;
            }
        }
    
        LITextWidth txtWidth = [[[notification userInfo] valueForKey:@"textWidth"] intValue];
                
        settings = [[NSDictionary alloc] initWithObjectsAndKeys:[[notification userInfo] valueForKey:@"docFont"], @"docFont", textColor, @"textColor", backColor, @"backgroundColor", [NSNumber numberWithInteger:txtWidth], @"textWidth", [settings valueForKey:@"whiteBlack"], @"whiteBlack", nil];
        
        [activeStorage beginEditing];
        if (![self.document fileURL])
            [activeStorage setFont:aNewFont];
        [activeStorage setForegroundColor:textColor];
        [activeStorage endEditing];
        
        [settingsProxy setValue:[backColor hexColor] forSettingName:@"backgroundColor"];
        [settingsProxy setValue:[textColor hexColor] forSettingName:@"textColor"];
        [settingsProxy setValue:[settings valueForKey:@"docFont"] forSettingName:@"docFont"];
        
        if ([self.document fileURL])
            [[self document] saveDocument:self];
        [self.gradientView setGradientColor:backColor];
    }
    
    [activeStorage addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(0, [aTextView textStorage].length)];
    [(LIBackColoredView*)[[self.splitContainer subviews] objectAtIndex:0] setBackground:backColor];
    [self.gradientView setGradientColor:backColor];
    
    switch ([[settings valueForKey:@"textWidth"] intValue]) {
        case LIStraitText: {
            [self setTextContainerWidth:400.0f];
            [settingsProxy setValue:[NSNumber numberWithInteger:LIStraitText] forSettingName:@"textWidth"];
            break;
        }
            
        case LIMediumText: {
            [self setTextContainerWidth:650.0f];
            [settingsProxy setValue:[NSNumber numberWithInteger:LIMediumText] forSettingName:@"textWidth"];
            break;
        }
            
        case LIWideText: {
            [self setTextContainerWidth:900.0f];
            [settingsProxy setValue:[NSNumber numberWithInteger:LIWideText] forSettingName:@"textWidth"];
            break;
        }
    }
    
    if ([editorView bounds].size.width - self.textContainerWidth > 50) {
        [aTextView setTextContainerInset:NSMakeSize(([aTextView bounds].size.width-self.textContainerWidth)/2, 20)];
        [[aTextView textContainer] setContainerSize:NSMakeSize(self.textContainerWidth, [[aTextView textContainer] containerSize].height)];
    } else {
        [aTextView setTextContainerInset:NSMakeSize(20, 20)];
        [[aTextView textContainer] setContainerSize:NSMakeSize(aTextView.bounds.size.width - 40, [[aTextView textContainer] containerSize].height)];
    }
    
    [aTextView setFont:aNewFont];
    [aTextView setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:aNewFont, NSFontAttributeName, textColor, NSForegroundColorAttributeName, nil]];
}

- (void)colorScheme:(NSNotification *)notification
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    NSColor *backColor = [[notification userInfo] valueForKey:@"backColor"];
    NSColor *textColor = [[notification userInfo] valueForKey:@"textColor"];
    NSInteger txtLength = [[aTextView textStorage] length];
    
    NSArray *selections = [[NSArray alloc] initWithArray:[aTextView selectionFinder]];
    
    [[aTextView textStorage] beginEditing];
    [[aTextView textStorage] addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(0, txtLength)];
    if (![[notification.userInfo valueForKey:@"whiteBlack"] boolValue])
        [aTextView setSelectedTextAttributes:@{ NSForegroundColorAttributeName:[NSColor colorWithHex:@"#808080"] , NSBackgroundColorAttributeName:[NSColor colorWithHex:@"333333"]}];
    else
        [aTextView setSelectedTextAttributes:@{ NSForegroundColorAttributeName:textColor , NSBackgroundColorAttributeName:[NSColor colorWithHex:@"#B4D4FF"]}];
    
    if ([selections count] > 0) {
        
        for (NSValue *rValue in selections) {
            if (![[notification.userInfo valueForKey:@"whiteBlack"] boolValue]) {
                [[aTextView textStorage] addAttribute:NSForegroundColorAttributeName value:backColor range:[rValue rangeValue]];
            }
            else {
                [[aTextView textStorage] addAttribute:NSForegroundColorAttributeName value:textColor range:[rValue rangeValue]];
            }
        }
    }
    
    [[aTextView textStorage] endEditing];
    [(LIBackColoredView*)[[self.splitContainer subviews] objectAtIndex:0] setBackground:backColor];
    [self.aTextView setInsertionPointColor:textColor];
    [self.gradientView setGradientColor:backColor];
    [self.gradientView setNeedsDisplay:YES];
}

- (LIFontStyle)fontStyleForFont:(NSFont *)aFont atRange:(NSRange)aRange
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    NSRange effectiveRange;
    
    if (aRange.location == [[aTextView textStorage] length])
        aRange.location = aRange.location-1;
    
    if ([[[aTextView textStorage] attributesAtIndex:aRange.location effectiveRange:&effectiveRange] valueForKey:NSUnderlineStyleAttributeName]) {
        if ([[NSFontManager sharedFontManager] fontNamed:[aFont fontName] hasTraits:NSBoldFontMask]) {
            if ([[NSFontManager sharedFontManager] fontNamed:[aFont fontName] hasTraits:NSItalicFontMask])
                return LIBoldItalicUnderline;
            else
                return LIBoldUnderline;
        }
        if ([[NSFontManager sharedFontManager] fontNamed:[aFont fontName] hasTraits:NSItalicFontMask])
            return LIItalicUnderline;
        return LIUnderline;
    }
    else {
        if ([[NSFontManager sharedFontManager] fontNamed:[aFont fontName] hasTraits:NSBoldFontMask]) {
            if ([[NSFontManager sharedFontManager] fontNamed:[aFont fontName] hasTraits:NSItalicFontMask])
                return LIBoldItalic;
            else {
                return LIBold;
            }
        }
        
        if ([[NSFontManager sharedFontManager] fontNamed:[aFont fontName] hasTraits:NSItalicFontMask])
            return LIItalic;
    }
    return LINormal;
}

- (void)arrangeTextInView
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    if ([editorView bounds].size.width - self.textContainerWidth > 40) {
        if (aTextView.frame.size.width < editorView.bounds.size.width)
            [aTextView setFrameSize:NSMakeSize(editorView.bounds.size.width, aTextView.frame.size.height)];
        [aTextView setTextContainerInset:NSMakeSize(([aTextView bounds].size.width-self.textContainerWidth)/2, 20)];
    } else {
        if (aTextView.frame.size.width > editorView.bounds.size.width)
            [aTextView setFrameSize:NSMakeSize(editorView.bounds.size.width, aTextView.frame.size.height)];
        [aTextView setTextContainerInset:NSMakeSize(20, 20)];
    }
}

- (NSString *)yarlyTimer:(NSNotification *)notification
{//NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused (notification)
    LITimedWritingController *orlyTimer = [LITimedWritingController timedWritingController];
    NSString *yarlyTimerValue = [orlyTimer showedCountdown];
    NSString *newStatus;
    
    if ([aTextView selectedRange].length != 0) {
        NSUInteger wordsSelected = [NSString countWords:[[[aTextView textStorage] string] substringWithRange:[aTextView selectedRange]]], charsSelected = [aTextView selectedRange].length;
        newStatus = [self infoStringwithDocType:[[self document] docType] wordsSelected:wordsSelected charsSelected:charsSelected timerStringValue:yarlyTimerValue];
    }
    else {
        newStatus = [self simpleInfoStringWithTimerValue:yarlyTimerValue bigText:self.iAmBigText];
    }
    [self setInfoString:newStatus];
    
    return newStatus;
}

- (void)timerStopped
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    [self setInfoString:[self simpleInfoStringWithTimerValue:nil bigText:NO]];
}

- (NSString *)simpleInfoStringWithTimerValue:(NSString *)timerString bigText:(BOOL)bigText
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    NSString *bullet = [NSString stringWithUTF8String:"\u2022"];
    
    if (!bigText) {
        
        NSTextStorage *activeStorage = [aTextView textStorage];
        if (activeStorage.length == 0)
            activeStorage = [self.document textStorage];
        
        wordsCount = activeStorage.words.count;
        charCount = activeStorage.characters.count;
        
        LITimedWritingController *aTimer = [LITimedWritingController timedWritingController];
        
        if ([aTimer showTimer] && [[aTimer cTimer] isValid]) {
            [self setFrozenInfoString:[NSString stringWithFormat:@"%@ %@ %ld words %@ %ld characters %@ %@", [[self document] docType], bullet, wordsCount, bullet, charCount, bullet, timerString]];
        }
        else {
            [self setFrozenInfoString:[NSString stringWithFormat:@"%@ %@ %ld words %@ %ld characters", [[self document] docType], bullet, wordsCount, bullet, charCount]];
        }
    }
    else {
        if (self.frozenInfoString.length == 0 || [self.infoString rangeOfString:@"select"].location != NSNotFound) {
            [self setFrozenInfoString:[self simpleInfoStringWithTimerValue:nil bigText:NO]];
        }
        if (timerString.length != 0)
            [self setFrozenInfoString:[NSString stringWithFormat:@"%@ %@ %ld words %@ %ld characters %@ %@", [[self document] docType], bullet, wordsCount, bullet, charCount, bullet, timerString]];
        if ([self.frozenInfoString hasSuffix:@" 0s."]) {
            [self setFrozenInfoString:[NSString stringWithFormat:@"%@ %@ %ld words %@ %ld characters", [[self document] docType], bullet, wordsCount, bullet, charCount]];
        }
    }
    return self.frozenInfoString;
}

- (NSString *)infoStringwithDocType:(NSString *)doucmentType wordsSelected:(NSUInteger)wSelected charsSelected:(NSUInteger)cSelected timerStringValue:(NSString *)timerString
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    NSString *bullet = [NSString stringWithUTF8String:"\u2022"];
    
    LITimedWritingController *aTimer = [LITimedWritingController timedWritingController];
    
    if ([aTimer showTimer] && [[aTimer cTimer] isValid]) {
        switch (wSelected) {
            case 1: {
                switch (cSelected) {
                    case 1: {
                        return [NSString stringWithFormat:@"%@ %@ 1 word %@ 1 character %@ %@", [[self document] docType], bullet, bullet, bullet, timerString];
                    }
                    default: {
                        return [NSString stringWithFormat:@"%@ %@ 1 word %@ %ld characters %@ %@", [[self document] docType], bullet, bullet, cSelected, bullet, timerString];
                    }
                }
            }
            default: {
                switch (cSelected) {
                    case 1: {
                        return [NSString stringWithFormat:@"%@ %@ %ld words %@ 1 character %@ %@", [[self document] docType], bullet, wSelected, bullet, bullet, timerString];
                    }
                    default: {
                        return [NSString stringWithFormat:@"%@ %@ %ld words %@ %ld characters %@ %@", [[self document] docType], bullet, wSelected, bullet, cSelected, bullet, timerString];
                    }
                }
            }
        }
    }
    
    else {
        switch (wSelected) {
            case 1: {
                switch (cSelected) {
                    case 1: {
                        return [NSString stringWithFormat:@"%@ %@ 1 word selected %@ 1 character selected", [[self document] docType], bullet, bullet];
                    }
                    default: {
                        return [NSString stringWithFormat:@"%@ %@ 1 word selected %@ %ld characters selected", [[self document] docType], bullet, bullet, cSelected];
                    }
                }
            }
            default: {
                switch (cSelected) {
                    case 1: {
                        return [NSString stringWithFormat:@"%@ %@ %ld words selected %@ 1 character selected", [[self document] docType], bullet, wSelected, bullet];
                    }
                    default: {
                        return [NSString stringWithFormat:@"%@ %@ %ld words selected %@ %ld characters selected", [[self document] docType], bullet, wSelected, bullet, cSelected];
                    }
                }
            }
        }
    }
}

- (void)updateMarkdownPreviewInstantly:(BOOL)updateNow
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    NSError *error = nil;
    if ((([NSDate timeIntervalSinceReferenceDate] >= whenToUpdate) || updateNow) && [[aTextView textStorage] length] != 0) {
		whenToUpdate = [[NSDate distantFuture] timeIntervalSinceReferenceDate];
        
        NSString *defaultCSSLight = [NSString stringWithFormat:@"<style>%@</style>", [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"light" ofType:@"css"] encoding:NSUTF8StringEncoding error:&error]];
        NSString *defaultCSSDark = [NSString stringWithFormat:@"<style>%@</style>", [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"dark" ofType:@"css"] encoding:NSUTF8StringEncoding error:&error]];
        
        if ([[settingsProxy valueForSetting:@"useCustomCSS"] boolValue]) {
            NSString *aPath = [settingsProxy valueForSetting:@"customCSS"];
            if (_cssPath.length == 0 || ![_cssPath isEqualToString:aPath] || [_cssHTML isEqualToString:defaultCSSLight] || [_cssHTML isEqualToString:defaultCSSDark]) {
                _cssPath = aPath;
                if ([[NSFileManager defaultManager] fileExistsAtPath:_cssPath]) {
                    NSError *error;
                    _cssHTML = [NSString stringWithFormat:@"<style>%@</style>", [NSString stringWithContentsOfFile:_cssPath encoding:NSUTF8StringEncoding error:&error]];
                }
                else {
                    if ([[settingsProxy valueForSetting:@"whiteBlack"] boolValue])
                        _cssHTML = defaultCSSLight;
                    else
                        _cssHTML = defaultCSSDark;
                }
            }
        }
        else {
            if ([[settingsProxy valueForSetting:@"whiteBlack"] boolValue])
                _cssHTML = defaultCSSLight;
            else
                _cssHTML = defaultCSSDark;
        }
        
        NSMutableAttributedString *aStr = [[NSMutableAttributedString alloc] initWithAttributedString:[aTextView textStorage]];
        
        [aTextView removeAttachmentsInString:aStr];
        NSString *toPreview = [aStr string];
        
        NSString *html = [ORCDiscount HTMLPage:[ORCDiscount markdown2HTML:toPreview] withCSSHTML:_cssHTML];
        
        BOOL isDir;     // Запись ТОЛЬКО в AppSupport юзера!!!
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        
        NSString *mdPreviewDirectory = [paths objectAtIndex:0];
        if (![[NSFileManager defaultManager] fileExistsAtPath:mdPreviewDirectory isDirectory:&isDir])
            [[NSFileManager defaultManager] createDirectoryAtPath:mdPreviewDirectory withIntermediateDirectories:NO attributes:nil error:&error];
        NSString *lastComponent = [NSString stringWithFormat:@"~%@.html", [self.document displayName]];
        NSString *bufferPath = [mdPreviewDirectory stringByAppendingPathComponent:lastComponent];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:bufferPath])
            [[NSFileManager defaultManager] removeItemAtPath:bufferPath error:&error];
        [html writeToFile:bufferPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        
        [self setMdPreviewPath:bufferPath];
        
        NSScrollView *mdScrollView = [[[[markdownPreview mainFrame] frameView] documentView] enclosingScrollView];
        previewPosition = [[mdScrollView contentView] bounds].origin;
    
        [[markdownPreview mainFrame] loadHTMLString:[NSString stringWithContentsOfFile:bufferPath encoding:NSUTF8StringEncoding error:&error] baseURL:[NSURL fileURLWithPath:bufferPath]];
	}
}

- (void)focusOnText
{      //NSLog(@"%s", __PRETTY_FUNCTION__);
    NSInteger caretLocation = [aTextView selectedRange].location;
    NSDictionary *rects = [[NSDictionary alloc] init];
    switch ([[settingsProxy valueForSetting:@"focusOn"] intValue]) {
        case 1: {
            NSRange neededRange;
            if (caretLocation == [aTextView.textStorage length])
                caretLocation--;
            (void)[layoutMgr lineFragmentRectForGlyphAtIndex:caretLocation effectiveRange:&neededRange];
            rects = [aTextView maskForRange:neededRange];
            break;
        }
        case 2: {
            NSRange paragraphRange = [[[aTextView textStorage] string] paragraphRangeForRange:NSMakeRange(caretLocation, 0)];
            rects = [aTextView maskForRange:paragraphRange];
            break;
        }
    }
    [self.gradientView moveFocus:rects];
}

- (void)performDropFocusWhenScrolled:(NSNotification *)notification
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.gradientView removeFocus];
}

- (void)insertMarkerWithIdentifier:(NSString *)identifier
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    NSRange effectiveRange;
    NSRange activeRange = [aTextView selectedRange];
    
    if (activeRange.location == [[aTextView textStorage] length]) {
        return;
    }
    
    NSTextAttachment *attachment;
    for (int i = -1; i < 1; i++) {
        attachment = [[aTextView textStorage] attribute:NSAttachmentAttributeName atIndex:activeRange.location+i effectiveRange:&effectiveRange];
        if (attachment)
            return;
    }
    
    NSUInteger positionForBookmark = activeRange.location;
        
        // Вставляем фейковую картинку
    NSImage *image = [NSImage imageNamed:@"bookmarkDummy"];
        
    NSTextAttachmentCell *attachmentCell =[[NSTextAttachmentCell alloc] initImageCell:image];
    NSTextAttachment *attachmentFake =[[NSTextAttachment alloc] init];
    [attachmentFake setAttachmentCell: attachmentCell];
    NSMutableAttributedString *attributedString =[[NSAttributedString  attributedStringWithAttachment: attachmentFake] mutableCopy];
    
    NSRange paragraphRange = [[[aTextView textStorage] string] paragraphRangeForRange:activeRange];
    paraStyle = [aTextView styleForParagraphRange:paragraphRange];
    
    [[aTextView textStorage] beginEditing];
    if ([aTextView shouldChangeTextInRange:NSMakeRange(positionForBookmark, 0) replacementString:@""]) {
        [[aTextView textStorage] insertAttributedString:attributedString atIndex:positionForBookmark];
        [aTextView didChangeText];
    }
    [[aTextView textStorage] endEditing];
        
        // Let's animation begin!
    [self.gradientView animateAppearingBookmarkAtPosition:positionForBookmark];
}

- (void)gotoLine:(int)lineNumber
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    if (lineNumber == 0)
        return;
    
    NSArray *lines = [[NSArray alloc] initWithArray:[[[aTextView textStorage] string] linesRanges]];
    NSRange neededRange;
    if (lineNumber > [lines count])
        neededRange = [[lines lastObject] rangeValue];
    else
        neededRange = [[lines objectAtIndex:lineNumber-1] rangeValue];
    
    [aTextView scrollRangeToVisible:neededRange];
    [aTextView setSelectedRange:NSMakeRange(neededRange.location, 0)];
}

- (void)updateCounters
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    LITimedWritingController *orlyTimer = [LITimedWritingController timedWritingController];
    NSTextStorage *activeStorage = [aTextView textStorage];
    if ([activeStorage length] == 0) {
        activeStorage = [self.document textStorage];
    }
    
    if ([orlyTimer showTimer] && [[orlyTimer cTimer] isValid]) {
        [self setInfoString:[self yarlyTimer:nil]];
    }
    else {
        if ([aTextView selectedRange].length == 0) {
            if (self.iAmBigText) {
                if (self.mazochisticMode) {
                    [self setInfoString:[self simpleInfoStringWithTimerValue:nil bigText:NO]];
                    return;
                }
                else {
                    [self setInfoString:[self simpleInfoStringWithTimerValue:nil bigText:YES]];
                    return;
                }
            }
            [self setInfoString:[self simpleInfoStringWithTimerValue:nil bigText:NO]];
            return;
        }
        
        else {
            NSUInteger wordsSelected = [NSString countWords:[[activeStorage string] substringWithRange:[aTextView selectedRange]]], charsSelected = [aTextView selectedRange].length;
            if (self.iAmBigText) {
                if (self.mazochisticMode) {
                    [self setInfoString:[self infoStringwithDocType:[[self document] docType] wordsSelected:wordsSelected charsSelected:charsSelected timerStringValue:nil]];
                    return;
                }
                else {
                    [self setInfoString:[self infoStringwithDocType:[[self document] docType] wordsSelected:wordsSelected charsSelected:charsSelected timerStringValue:nil]];
                    return;
                }
            }
            [self setInfoString:[self infoStringwithDocType:[[self document] docType] wordsSelected:wordsSelected charsSelected:charsSelected timerStringValue:nil]];
            return;
        }
    }
}

- (NSFont *)fontWithTrait:(NSString *)trait onStyle:(LIFontStyle)style
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    NSFont *defaultFont = [self.document docFont:[settingsProxy valueForSetting:@"docFont"]];
    NSString *currentFamilyName = [[NSString alloc] initWithString:[defaultFont familyName]];
    CGFloat currentSize = [defaultFont pointSize];
    
    NSRange effectiveRange;
    NSFont *aNewFont;
    
    if ([trait isEqualToString:@"Bold"]) {
        switch (style) {
            case LIBold: {
                aNewFont = [[NSFontManager sharedFontManager] fontWithFamily:currentFamilyName traits:NSUnboldFontMask weight:0 size:currentSize];
                [self setCustomTextStyle:LINormal];
                break;
            }
            case LIBoldItalic: {
                aNewFont = [[NSFontManager sharedFontManager] fontWithFamily:currentFamilyName traits:NSUnboldFontMask|NSItalicFontMask weight:0 size:currentSize];
                [self setCustomTextStyle:LIItalic];
                break;
            }
            case LIBoldUnderline: {
                aNewFont = [[NSFontManager sharedFontManager] fontWithFamily:currentFamilyName traits:NSUnboldFontMask weight:0 size:currentSize];
                [self setCustomTextStyle:LIUnderline];
                break;
            }
            case LIBoldItalicUnderline: {
                aNewFont = [[NSFontManager sharedFontManager] fontWithFamily:currentFamilyName traits:NSUnboldFontMask|NSItalicFontMask weight:0 size:currentSize];
                [self setCustomTextStyle:LIItalicUnderline];
                break;
            }
            case LIItalic: {
                aNewFont = [[NSFontManager sharedFontManager] fontWithFamily:currentFamilyName traits:NSBoldFontMask|NSItalicFontMask weight:0 size:currentSize];
                [self setCustomTextStyle:LIBoldItalic];
                break;
            }
            case LIUnderline: {
                aNewFont = [[NSFontManager sharedFontManager] fontWithFamily:currentFamilyName traits:NSBoldFontMask weight:0 size:currentSize];
                [self setCustomTextStyle:LIBoldUnderline];
                break;
            }
            case LIItalicUnderline: {
                aNewFont = [[NSFontManager sharedFontManager] fontWithFamily:currentFamilyName traits:NSBoldFontMask|NSItalicFontMask weight:0 size:currentSize];
                [self setCustomTextStyle:LIBoldItalicUnderline];
                break;
            }
            case LINormal: {
                aNewFont = [[NSFontManager sharedFontManager] fontWithFamily:currentFamilyName traits:NSBoldFontMask weight:0 size:currentSize];
                [self setCustomTextStyle:LIBold];
                break;
            }
        }
    }
    if ([trait isEqualToString:@"Italic"]) {
            
        switch (style) {
            case LIItalic: {
                aNewFont = [[NSFontManager sharedFontManager] fontWithFamily:currentFamilyName traits:NSUnitalicFontMask weight:0 size:currentSize];
                [self setCustomTextStyle:LINormal];
                break;
            }
            case LIBoldItalic: {
                aNewFont = [[NSFontManager sharedFontManager] fontWithFamily:currentFamilyName traits:NSUnitalicFontMask|NSBoldFontMask weight:0 size:currentSize];
                [self setCustomTextStyle:LIBold];
                break;
            }
            case LIItalicUnderline: {
                aNewFont = [[NSFontManager sharedFontManager] fontWithFamily:currentFamilyName traits:NSUnitalicFontMask weight:0 size:currentSize];
                [self setCustomTextStyle:LIUnderline];
                break;
            }
            case LIBoldItalicUnderline: {
                aNewFont = [[NSFontManager sharedFontManager] fontWithFamily:currentFamilyName traits:NSUnitalicFontMask|NSBoldFontMask weight:0 size:currentSize];
                [self setCustomTextStyle:LIBoldUnderline];
                break;
            }
            case LIBold: {
                aNewFont = [[NSFontManager sharedFontManager] fontWithFamily:currentFamilyName traits:NSItalicFontMask|NSBoldFontMask weight:0 size:currentSize];
                [self setCustomTextStyle:LIBoldItalic];
                break;
            }
            case LIBoldUnderline: {
                aNewFont = [[NSFontManager sharedFontManager] fontWithFamily:currentFamilyName traits:NSItalicFontMask|NSBoldFontMask weight:0 size:currentSize];
                [self setCustomTextStyle:LIBoldItalicUnderline];
                break;
            }
            case LIUnderline: {
                aNewFont = [[NSFontManager sharedFontManager] fontWithFamily:currentFamilyName traits:NSItalicFontMask weight:0 size:currentSize];
                [self setCustomTextStyle:LIItalicUnderline];
                break;
            }
            case LINormal: {
                aNewFont = [[NSFontManager sharedFontManager] fontWithFamily:[defaultFont familyName] traits:NSItalicFontMask weight:0 size:[defaultFont pointSize]];
                [self setCustomTextStyle:LIItalic];
                break;
            }
        }
    }
    if ([trait isEqualToString:@"Underline"]) {
            
        if (![[[aTextView textStorage] attributesAtIndex:[aTextView selectedRange].location effectiveRange:&effectiveRange] valueForKey:NSUnderlineStyleAttributeName]) {
            [[aTextView textStorage] beginEditing];
            [[aTextView textStorage] addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSSingleUnderlineStyle] range:[aTextView selectedRange]];
            [[aTextView textStorage] endEditing];
        }
        else {
            [[aTextView textStorage] beginEditing];
            [[aTextView textStorage] removeAttribute:NSUnderlineStyleAttributeName range:[aTextView selectedRange]];
            [[aTextView textStorage] endEditing];
        }
            
        switch ([self customTextStyle]) {
            case LIBold: {
                [self setCustomTextStyle:LIBoldUnderline];
                break;
            }
            case LIBoldItalic: {
                [self setCustomTextStyle:LIBoldItalicUnderline];
                break;
            }
            case LIItalic: {
                [self setCustomTextStyle:LIItalicUnderline];
                break;
            }
            case LIBoldUnderline: {
                [self setCustomTextStyle:LIBold];
                break;
            }
            case LIItalicUnderline: {
                [self setCustomTextStyle:LIItalic];
                break;
            }
            case LIBoldItalicUnderline: {
                [self setCustomTextStyle:LIBoldItalic];
                break;
            }
            case LIUnderline: {
                [self setCustomTextStyle:LINormal];
                break;
            }
            case LINormal: {
                [self setCustomTextStyle:LIUnderline];
                break;
            }
        }
    }
    return aNewFont;
}

#pragma mark
#pragma mark ---- Some Animations ----

/*- (void)animatedAppearingBookmark:(NSNumber *)position
{//NSLog(@"%s", __PRETTY_FUNCTION__);

    NSUInteger aPosition = [position intValue];
    NSImage *bookmark = [NSImage imageNamed:@"bookmark"];
    CALayer *bookmarkLayer = [CALayer layer];
    CGImageRef imageRef = nil;
    
    NSData *imageData = [bookmark PNGRepresentation];

    if (imageData) {
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData,  NULL);
        imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
        CFRelease(imageSource);
    }
 
    [bookmarkLayer setContents:(__bridge id)imageRef];
    [bookmarkLayer setBounds:NSRectToCGRect(NSMakeRect(0, 0, bookmark.size.width, bookmark.size.height))];
    CGImageRelease(imageRef);
    
    NSRect rectForImageLayer = [aTextView rectForBookmarkAnimation:NSMakeRange(aPosition, 0)];
    
    [bookmarkLayer setPosition:rectForImageLayer.origin];
    [bookmarkLayer setName:@"bookmarkLayer"];
    
    [[aTextView layer] addSublayer:bookmarkLayer];
    
    NSPoint startPoint = bookmarkLayer.position;
    NSPoint endPoint = NSMakePoint(startPoint.x, startPoint.y - 18);
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
	anim.fromValue = [NSValue valueWithPoint:startPoint];
	anim.toValue = [NSValue valueWithPoint:endPoint];
	anim.repeatCount = 1.0;
    anim.duration = 0.2;
    anim.removedOnCompletion = YES;
    [anim setDelegate:self];
    
    [bookmarkLayer addAnimation:anim forKey:@"position"];
    
    [bookmarkLayer performSelector:@selector(removeFromSuperlayer) withObject:nil afterDelay:anim.duration];
}*/

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{    //NSLog(@"%s", __PRETTY_FUNCTION__);
    NSUInteger positionForBookmark = [aTextView selectedRange].location-1;
    
        // Вставляем настоящий аттачмент
    NSImage *bMark = [NSImage imageNamed:@"bookmark"];
    NSFileWrapper *wrapper = [self.document fileWrapperWithIdentifier:@"bookmark"];
    NSTextAttachment *attachment = [[NSTextAttachment alloc] initWithFileWrapper:wrapper];
    LITextAttachmentCell *cell = [[LITextAttachmentCell alloc] initImageCell:bMark];;
    [cell setIdentifier:@"bookmark"];
    [attachment setAttachmentCell:cell];
    NSMutableAttributedString *attributedString = [[NSAttributedString attributedStringWithAttachment:attachment] mutableCopy];
    
    if ([aTextView shouldChangeTextInRange:NSMakeRange(positionForBookmark, 0) replacementString:@""]) {
        [[aTextView textStorage] beginEditing];
        [[aTextView textStorage] replaceCharactersInRange:NSMakeRange(positionForBookmark, 1) withAttributedString:attributedString];
        [[aTextView textStorage] endEditing];
        
        NSRange paragraphRange = [[[aTextView textStorage] string] paragraphRangeForRange:NSMakeRange(positionForBookmark, 0)];
        [[aTextView textStorage] addAttribute:NSParagraphStyleAttributeName value:paraStyle range:paragraphRange];
        [aTextView didChangeText];
    }   
    
    [aTextView setSelectedRange:NSMakeRange(positionForBookmark+1, 0)];
    
    if ([[self.document fileType] isEqualToString:@"public.rtf"] && [[self.document docType] isEqualToString:RTF])
        [self.document setFileType:@"com.apple.rtfd"];
    else if ([[self.document docType] isEqualToString:TXT]) {
        [self.document setFileType:@"public.plain-text"];
    }
    
}

#pragma mark
#pragma mark ---- Delegates ----
#pragma mark Window Delegate

- (void)windowWillClose:(NSNotification *)notification
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    [self removeObserver:self forKeyPath:@"windowContentWidth"];
    [self removeObserver:self forKeyPath:@"masked"];
    
    [self.document removeObserver:self.document forKeyPath:@"fileType"];
    
    [settingsProxy removeObserver:self forKeyPath:@"focusOn"];
    [settingsProxy removeObserver:self forKeyPath:@"useCustomCSS"];
    [settingsProxy removeObserver:self forKeyPath:@"whiteBlack"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"newSettingsArrived" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"colorScheme" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"yarlyTimer" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"timerStopped" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"buffLayer" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:scrollContainer.contentView];
    
    if ([markdownTimer isValid])
        [markdownTimer invalidate];
    
    BOOL existedFile;
    NSString *bufferPath;
    if ([self.document fileURL])
        existedFile = YES;
    else
        existedFile = NO;
    if (existedFile) {
        NSString *lastComponent = [NSString stringWithFormat:@".%@.html",[[[[self.document fileURL] path] lastPathComponent] stringByDeletingPathExtension]];
        bufferPath = [[[self.document fileURL] path] stringByReplacingOccurrencesOfString:[[[self.document fileURL] path] lastPathComponent] withString:lastComponent];
    }
    else {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES); 
        NSString *mdPreviewDirectory = [(NSString*)[paths objectAtIndex:0] stringByAppendingPathComponent:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]]; // Get documents directory
        NSString *lastComponent = [NSString stringWithFormat:@"%@.html", [self document]];
        bufferPath = [mdPreviewDirectory stringByAppendingPathComponent:lastComponent];
    }
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:bufferPath error:&error];
}

- (void)windowWillStartLiveResize:(NSNotification *)notification
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    if ([textPopover isShown] || [self.markdownPopover isShown]) {
        isPopoverShown = YES;
    }
    if (self.masked)
        [self.gradientView removeFocus];

}

- (void)windowDidEndLiveResize:(NSNotification *)notification
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    if (isPopoverShown) {
        [showedPopover showRelativeToRect:popoverRelativeRect ofView:self.aTextView preferredEdge:NSMaxYEdge];
        isPopoverShown = NO;
    }
}

- (void)windowWillMove:(NSNotification *)notification
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    if ([textPopover isShown] || [self.markdownPopover isShown])
        isPopoverShown = YES;
}

- (void)windowDidMove:(NSNotification *)notification
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    if (isPopoverShown) {
        [showedPopover showRelativeToRect:popoverRelativeRect ofView:self.aTextView preferredEdge:NSMaxYEdge];
        isPopoverShown = NO;
    }
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.window makeFirstResponder:aTextView];
}

#pragma mark TextView Delegate
- (NSRange)textView:(NSTextView *)textView willChangeSelectionFromCharacterRange:(NSRange)oldSelectedCharRange toCharacterRange:(NSRange)newSelectedCharRange
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    NSTextStorage *activeStorage = [aTextView textStorage];
    if ([activeStorage length] == 0) {
        activeStorage = [self.document textStorage];
    }
    NSRange activeRange = [aTextView selectedRange];
    NSLog(@"%@", [aTextView selectedTextAttributes]);
    NSDictionary *isAttachment = [[NSDictionary alloc] initWithDictionary:[aTextView attributesAtRange:NSMakeRange(activeRange.location-1, [aTextView selectedRange].length)]];
    if ([isAttachment valueForKey:NSAttachmentAttributeName] != nil) {
        NSDictionary *trullyAttributes = [NSDictionary dictionaryWithDictionary:[aTextView attributesAtRange:NSMakeRange(activeRange.location, aTextView.selectedRange.length)]];
        [aTextView setTypingAttributes:trullyAttributes];
    }
    else {
        NSDictionary *currentAttrs = [[NSDictionary alloc] initWithDictionary:[aTextView attributesAtRange:NSMakeRange(activeRange.location, [aTextView selectedRange].length)]];
        if ([[currentAttrs allKeys] count] != 0 && ![[aTextView typingAttributes] isEqualToDictionary:currentAttrs])   // текст форматирован?
            [aTextView setTypingAttributes:currentAttrs];
    }
    return newSelectedCharRange;
}

/*#pragma mark Popover Delegate
- (BOOL)popoverShouldClose:(NSPopover *)popover
{
    return YES;
}*/

#pragma mark SplitView Delegate

- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    if ([[sender subviews] count] > 1) {
        NSSize splitViewSize = [sender frame].size;
    
        NSSize left = [editorView frame].size;
        left.height = splitViewSize.height;
    
        NSSize right;
        right.height = splitViewSize.height;
        right.width = splitViewSize.width - [sender dividerThickness] - left.width;
        if (right.width > splitViewSize.width / 2)
            right.width = splitViewSize.width / 2;
    
        [editorView setFrameSize:left];
        for (NSView *aView in [sender subviews]) {
            if (aView != editorView)
                [aView setFrameSize:right];
        }
    
    } else {
        [editorView setFrameSize:splitContainer.bounds.size];
    }
    
    [splitContainer adjustSubviews];
    [self arrangeTextInView];
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    switch (self.markdownShowed) {
        case NO:
            return YES;
        case YES: {
            return NO;
        }
    }
    return NO;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    NSView* rightView = [[splitView subviews] objectAtIndex:1];
    return ([subview isEqual:rightView]);
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    CGFloat result = 0;
    if (splitView == self.splitContainer) {
        result = self.splitContainer.frame.size.width / 2;
    }
    return result;
}
/*- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex;
{
    NSView* rightView = [[splitView subviews] objectAtIndex:1];
    return ([subview isEqual:rightView]);
}*/

#pragma mark WebView Delegate

- (NSArray*)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    return nil;
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    NSScrollView *mdScrollView = [[[[markdownPreview mainFrame] frameView] documentView] enclosingScrollView];
    [[mdScrollView contentView] scrollPoint:previewPosition];
}

#pragma mark Dragging Support
- (NSUInteger)webView:(WebView *)webView dragDestinationActionMaskForDraggingInfo:(id<NSDraggingInfo>)draggingInfo
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    if ([[[draggingInfo draggingPasteboard] types] containsObject:NSURLPboardType]) {
        NSURL *cssURL = [NSURL URLFromPasteboard:[draggingInfo draggingPasteboard]];
        if ([[cssURL pathExtension] isEqualToString:@"css"] || [[cssURL pathExtension] isEqualToString:@"CSS"]) 
            return WebDragDestinationActionLoad;
    }
    return WebDragSourceActionNone;
}

#pragma mark
#pragma mark ---- IBActions ----
#pragma mark Popover Actions

- (IBAction)showPopover:(id)sender
{
    NSRange activeRange = [aTextView selectedRange];
    if (activeRange.location == [[aTextView textStorage] length]) {
        activeRange.location -= 1;
    }
    
    NSPoint mousePoint = [aTextView convertPoint:[self.window mouseLocationOutsideOfEventStream] fromView:nil];
    popoverRelativeRect = [aTextView rectForPopover];
    
    if (popoverRelativeRect.size.width == 0)
        popoverRelativeRect = NSMakeRect(popoverRelativeRect.origin.x, popoverRelativeRect.origin.y, 1, popoverRelativeRect.size.height);
    
    if ([[[self document] docType] isEqualToString:RTF]) {
        NSRange paragraphRange = [[[aTextView textStorage] string] paragraphRangeForRange:[aTextView selectedRange]];
        NSParagraphStyle *style = [aTextView styleForParagraphRange:paragraphRange];
        
            // Определяем текущее выравние текста
        NSTextAlignment textAlign = [style alignment];
    
        switch (textAlign) {
            case NSRightTextAlignment: {
                [self setCustomTextAlignment:[NSNumber numberWithUnsignedInteger:LITextAlignRight]];
                break;
            }
            case NSLeftTextAlignment: {
                [self setCustomTextAlignment:[NSNumber numberWithUnsignedInteger:LITextAlignLeft]];
                break;
            }
            case NSCenterTextAlignment: {
                [self setCustomTextAlignment:[NSNumber numberWithUnsignedInteger:LITextAlignCenter]];
                break;
            }
            default: {
                [self setCustomTextAlignment:[NSNumber numberWithUnsignedInteger:LITextAlignNatural]];
                break;
            }
        }
    
        NSFont *defaultFont = [self.document docFont:[settingsProxy valueForSetting:@"docFont"]];
        NSFont *currentFont = [aTextView currentFont];
        
            // Определяем, подсвечен ли текст
        NSRange effectiveRange;
        NSColor *backHighlight = [[[aTextView textStorage] attributesAtIndex:activeRange.location effectiveRange:&effectiveRange] valueForKey:NSBackgroundColorAttributeName];
        if ([backHighlight isEqualTo:[NSColor clearColor]] || !backHighlight)
            [highlightSegment setSelectedSegment:-1];
        else
            [highlightSegment setSelectedSegment:0];
            
            // Определяем текущий размер текста
        NSInteger delta = [defaultFont pointSize] - [currentFont pointSize];
        switch (delta) {
            case 0: {
                [self setFontSizeDelta:[NSNumber numberWithUnsignedInt:LIMidFontSize]];
                break;
            }
            case -2: {
                [self setFontSizeDelta:[NSNumber numberWithUnsignedInt:LIMaxFontSize]];
                break;
            }
            case 2: {
                [self setFontSizeDelta:[NSNumber numberWithUnsignedInt:LIMinFontSize]];
                break;
            }
            default:
                break;
        }
    
            // Определяем текущее начертание текста
        [self setCustomTextStyle:[self fontStyleForFont:currentFont atRange:activeRange]];
        [fontStylesControl setSelectedSegment:-1];
        
        switch ([self customTextStyle]) {
            case LIBold: {
                [fontStylesControl setSelectedSegment:0];
                break;
            }
            case LIItalic: {
                [fontStylesControl setSelectedSegment:1];
                break;
            }
            case LIUnderline: {
                [fontStylesControl setSelectedSegment:2];
                break;
            }
            case LIBoldItalic: {
                [fontStylesControl setSelectedSegment:0];
                [fontStylesControl setSelectedSegment:1];
                break;
            }
            case LIBoldUnderline: {
                [fontStylesControl setSelectedSegment:0];
                [fontStylesControl setSelectedSegment:2];
                break;
            }
            case LIItalicUnderline: {
                [fontStylesControl setSelectedSegment:1];
                [fontStylesControl setSelectedSegment:2];
                break;
            }
            case LIBoldItalicUnderline: {
                [fontStylesControl setSelectedSegment:0];
                [fontStylesControl setSelectedSegment:1];
                [fontStylesControl setSelectedSegment:2];
                break;
            }
            case LINormal: {
                [fontStylesControl setSelectedSegment:-1];
                break;
            }
        }
        
        NSTextList *list = [[NSTextList alloc] initWithMarkerFormat:@"{disc}" options:0];
        NSString *bullet = [[NSString alloc] initWithFormat:@"\t%@\t", [list markerForItemNumber:1]];
        if ([[[[aTextView textStorage] string] substringWithRange:[[[aTextView textStorage] string] paragraphRangeForRange:activeRange]] hasPrefix:bullet]) {
            [self setIsList:YES];
            [listSegment setSelectedSegment:0];
        }
        else {
            [self setIsList:NO];
            [listSegment setSelectedSegment:-1];
        }
                
        textPopover.appearance = NSPopoverAppearanceMinimal;
        if (mousePoint.y > popoverRelativeRect.origin.y)
            [textPopover showRelativeToRect:popoverRelativeRect ofView:aTextView preferredEdge:NSMaxYEdge];
        else
            [textPopover showRelativeToRect:popoverRelativeRect ofView:aTextView preferredEdge:NSMinYEdge];
        showedPopover = self.textPopover;
    }
    
    else if ([[self.document docType] isEqualToString:TXT]) {        
        
        NSRange paragraphRange = [self.aTextView.textStorage.string paragraphRangeForRange:activeRange];
        NSString *paragraphString = [self.aTextView.textStorage.string substringWithRange:paragraphRange];
        if (activeRange.length == 0) {
            activeRange.length += 1;
        }
        NSString *selectedString = [self.aTextView.textStorage.string substringWithRange:activeRange];
        
        // Определение уровня заголовка
        [self.mdSize setSelectedSegment:-1];
        if ([paragraphString hasPrefix:@"#"]) {
            NSUInteger size = 0;
            for (int i = 0; i < paragraphString.length; i++) {
                unichar ch = [paragraphString characterAtIndex:i];
                NSString *character = [NSString stringWithCharacters:&ch length:1];
                if ([character isEqualToString:@" "])
                    break;
                else
                    size++;
            }
            if (size > 0 && size < 4)
                [self.mdSize setSelectedSegment:size-1];
            else
                [self.mdSize setSelectedSegment:-1];
        }
        
        // Определение начертания
        [self.mdStyle setSelectedSegment:-1];
        NSInteger start = [paragraphString rangeOfString:selectedString].location;
        if (start != NSNotFound) {
            NSUInteger count = 0;
            start -= 1;
            
            for (int i = 0; i < 3; i++) {
                unichar ch = [paragraphString characterAtIndex:start];
                if (activeRange.location - start > paragraphRange.location)
                    start--;
                if (ch == 42)
                    count++;
                else
                    break;
            }
            switch (count) {
                case 1: {
                    [self.mdStyle setSelectedSegment:1];
                    break;
                }
                case 2: {
                    [self.mdStyle setSelectedSegment:0];
                    break;
                }
                case 3: {
                    [self.mdStyle setSelectedSegment:1];
                    [self.mdStyle setSelectedSegment:0];
                    break;
                }
                default:break;
            }
        }
        
        self.markdownPopover.appearance = NSPopoverAppearanceMinimal;
        if (mousePoint.y > popoverRelativeRect.origin.y)
            [self.markdownPopover showRelativeToRect:popoverRelativeRect ofView:self.aTextView preferredEdge:NSMaxYEdge];
        else
            [self.markdownPopover showRelativeToRect:popoverRelativeRect ofView:self.aTextView preferredEdge:NSMinYEdge];
        showedPopover = self.markdownPopover;
    }
}

#pragma mark RTF Popover

- (IBAction)setFontSize:(id)sender
{
    NSFont *defaultFont = [self.document docFont:[settingsProxy valueForSetting:@"docFont"]];
    NSFont *aNewFont;
    
    NSRange activeRange = [[[aTextView selectedRanges] objectAtIndex:0] rangeValue];
    NSMutableDictionary *currentAttrs = [[NSMutableDictionary alloc] initWithDictionary:[aTextView attributesAtRange:activeRange]];
    NSFont *currentFont = [currentAttrs valueForKey:NSFontAttributeName];
    
    switch ([sender selectedSegment]) {
        case 0: {
            aNewFont = [NSFont fontWithName:[currentFont fontName] size:[defaultFont pointSize]-2];
            break;
        }
            
        case 1: {
            aNewFont = [NSFont fontWithName:[currentFont fontName] size:[defaultFont pointSize]];
            break;
        }
            
        case 2: {
            aNewFont = [NSFont fontWithName:[currentFont fontName] size:[defaultFont pointSize]+2];
            break;
        }
    }
    
    if (activeRange.length != 0) {
        [currentAttrs setValue:aNewFont forKey:NSFontAttributeName];
        [[aTextView textStorage] beginEditing];
        [[aTextView textStorage] setAttributes:currentAttrs range:activeRange];
        [[aTextView textStorage] endEditing];
    }
    else {
        [currentAttrs setValue:aNewFont forKey:NSFontAttributeName];
        [aTextView setTypingAttributes:currentAttrs];
    }
}

- (IBAction)setTextAlignment:(id)sender
{
    NSRange paragraphRange = [[[aTextView textStorage] string] paragraphRangeForRange:[aTextView selectedRange]];
    NSTextAlignment alignment = NSNaturalTextAlignment;
    if ([sender isKindOfClass:[NSSegmentedControl class]]) {
        if ([sender selectedSegment] == 0)
            alignment = NSLeftTextAlignment;
        else if ([sender selectedSegment] == 1)
            alignment = NSCenterTextAlignment;
        else
            alignment = NSRightTextAlignment;
    }
    
    else if ([sender isKindOfClass:[NSMenuItem class]]) {
        if ([[sender title] isEqualToString:@"Align Left"])
            alignment = NSLeftTextAlignment;
        else if ([[sender title] isEqualToString:@"Center"])
            alignment = NSCenterTextAlignment;
        else if ([[sender title] isEqualToString:@"Justify"])
            alignment = NSJustifiedTextAlignment;
        else
            alignment = NSRightTextAlignment;
    }
    
    [[aTextView textStorage] beginEditing];            
    [[aTextView textStorage] setAlignment:alignment range:paragraphRange];
    [[aTextView textStorage] endEditing];
}

- (IBAction)setFontStyle:(id)sender
{
    NSString *traitToAdd;
    
    NSColor *currentColor = [[aTextView textStorage] foregroundColor];
    LIFontStyle style = [self fontStyleForFont:[aTextView currentFont] atRange:[aTextView selectedRange]];
    if ([sender isKindOfClass:[NSSegmentedControl class]]) {
        if ([sender selectedSegment] == 0)
            traitToAdd = @"Bold";
        else if ([sender selectedSegment] == 1)
            traitToAdd = @"Italic";
        else if ([sender selectedSegment] == 2)
            traitToAdd = @"Underline";
    }
    else if ([sender isKindOfClass:[NSMenuItem class]])
        traitToAdd = [sender title];
    
    NSFont *aNewFont = [self fontWithTrait:traitToAdd onStyle:style];
    if (aNewFont) {
        
        NSMutableDictionary *aNewAtrribs = [NSMutableDictionary dictionaryWithObjectsAndKeys:aNewFont, NSFontAttributeName, currentColor, NSForegroundColorAttributeName, nil];
        switch ([self customTextStyle]) {
            case LIUnderline:
            case LIBoldUnderline:
            case LIItalicUnderline:
            case LIBoldItalicUnderline: {
                [aNewAtrribs setValue:[NSNumber numberWithInt:NSSingleUnderlineStyle] forKey:NSUnderlineStyleAttributeName];
                break;
            }
        }
        
        if ([aTextView selectedRange].length != 0) {
            [[aTextView textStorage] beginEditing];
            [[aTextView textStorage] addAttributes:aNewAtrribs range:[aTextView selectedRange]];
            [[aTextView textStorage] endEditing];
        }
        else {
            [aTextView setTypingAttributes:aNewAtrribs];
        }
    }
}

- (IBAction)toggleSelection:(id)sender
{
    NSRange effectiveRange;
    
    NSString *attributeBackColor = [[[[aTextView textStorage] attributesAtIndex:[aTextView selectedRange].location effectiveRange:&effectiveRange] valueForKey:NSBackgroundColorAttributeName] hexColor];
    NSString *txtViewBackColor = [[aTextView backgroundColor] hexColor];
    NSString *defaultBackColor = [settingsProxy valueForSetting:@"backgroundColor"];
    
    if ([attributeBackColor isEqualToString:defaultBackColor] || ([txtViewBackColor isEqualToString:defaultBackColor] && [attributeBackColor isEqualToString:txtViewBackColor]) || attributeBackColor == nil) {
        [[self.aTextView textStorage] beginEditing];
        [[self.aTextView textStorage] addAttribute:NSBackgroundColorAttributeName value:[NSColor colorWithHex:[settingsProxy valueForSetting:@"selectionColor"]] range:[self.aTextView selectedRange]];
        [[self.aTextView textStorage] endEditing];
    }
    else {
        [[self.aTextView textStorage] beginEditing];
        [[self.aTextView textStorage] addAttribute:NSBackgroundColorAttributeName value:[NSColor clearColor] range:[self.aTextView selectedRange]];
        [[self.aTextView textStorage] endEditing];
        [self.highlightSegment setSelectedSegment:-1];
    }
}

- (IBAction)makeBulletList:(id)sender
{
    [aTextView markedListInsertion:[aTextView selectedRange]];
}

#pragma mark MD Popover

- (IBAction)setMDSize:(id)sender
{
    NSRange selectedRange = self.aTextView.selectedRange;
    NSRange paragraphRange = [[self.aTextView.textStorage string] paragraphRangeForRange:selectedRange];
    NSString *paragraphString = [[self.aTextView.textStorage string] substringWithRange:paragraphRange];
    NSMutableString *modifier = [NSMutableString string];
    
    if (![paragraphString hasPrefix:@"#"]) {
        
        NSInteger size = 0;
        if ([sender isKindOfClass:[NSSegmentedControl class]])
            size = [sender selectedSegment];
        else if ([sender isKindOfClass:[NSMenuItem class]])
            size = [sender tag];
    
        for (int i = 0; i < size + 1; i++)
            [modifier appendString:@"#"];
        
        [modifier appendString:@" "];
        selectedRange.location += modifier.length;
        
        [self.aTextView.textStorage beginEditing];
        NSString *replaceString = [modifier stringByAppendingString:paragraphString];
        [self.aTextView.textStorage replaceCharactersInRange:paragraphRange withString:replaceString];
        [self.aTextView.textStorage endEditing];
    }
    
    else {
        for (int i = 0; i < paragraphString.length; i++) {
            unichar ch = [paragraphString characterAtIndex:i];
            NSString *character = [NSString stringWithCharacters:&ch length:1];
            if ([character isEqualToString:@" "])
                break;
            else
                [modifier appendString:character];
        }
        
        NSString *clearParagraphString = [paragraphString stringByReplacingOccurrencesOfString:modifier withString:@""];
        clearParagraphString = [clearParagraphString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        selectedRange.location -= modifier.length+1;
        
        modifier = [NSMutableString string];
        for (int i = 0; i < [sender selectedSegment] + 1; i++)
            [modifier appendString:@"# "];
        selectedRange.location += modifier.length;
        
        [self.aTextView.textStorage beginEditing];
        NSString *replaceString = [modifier stringByAppendingString:clearParagraphString];
        [self.aTextView.textStorage replaceCharactersInRange:paragraphRange withString:replaceString];
        [self.aTextView.textStorage endEditing];
    }
    
    [self.aTextView setSelectedRange:selectedRange];
    [self.markdownPopover close];
}

- (IBAction)setMDFontStyle:(id)sender
{
    NSRange selectedRange = self.aTextView.selectedRange;
    NSString *selectedString = [self.aTextView.textStorage.string substringWithRange:selectedRange];
    NSString *modifier;
    
    switch ([sender selectedSegment]) {
        case 0: {
            modifier = @"**";
            break;
        }
        case 1: {
            modifier = @"*";
            break;
        }
        default:break;
    }
    
    if (![selectedString hasPrefix:modifier] && ![selectedString hasSuffix:modifier]) {
        [self.aTextView.textStorage beginEditing];
        NSMutableString *replaceString = [[modifier stringByAppendingString:selectedString] mutableCopy];
        if ([selectedString hasSuffix:@"\n"] || [selectedString hasSuffix:@"\r"])
            [replaceString insertString:modifier atIndex:replaceString.length-1];
        else
            [replaceString appendString:modifier];
        [self.aTextView.textStorage replaceCharactersInRange:selectedRange withString:replaceString];
        [self.aTextView.textStorage endEditing];
        
        selectedRange.location += modifier.length;
    }
    
    else {
        NSString *replaceString = [selectedString stringByReplacingOccurrencesOfString:modifier withString:@""];
        [self.aTextView.textStorage beginEditing];
        [self.aTextView.textStorage replaceCharactersInRange:selectedRange withString:replaceString];
        [self.aTextView.textStorage endEditing];
        selectedRange.location -= modifier.length;
    }
    
    [self.aTextView setSelectedRange:selectedRange];
}

- (IBAction)makeMDHyperlink:(id)sender
{
    NSRange selectedRange = self.aTextView.selectedRange;
    NSString *selectedString = [[self.aTextView.textStorage string] substringWithRange:selectedRange];
    NSError *error = nil;
    NSRegularExpression *hyperlinkValidator = [NSRegularExpression regularExpressionWithPattern:@"^(?i)(?:(?:https?):\\/\\/)?(?:\\S+(?::\\S*)?@)?(?:(?:[1-9]\\d?|1\\d\\d|2[01]\\d|22[0-3])(?:\\.(?:1?\\d{1,2}|2[0-4]\\d|25[0-5])){2}(?:\\.(?:[1-9]\\d?|1\\d\\d|2[0-4]\\d|25[0-4]))|(?:(?:[a-z\\u00a1-\\uffff0-9]+-?)*[a-z\\u00a1-\\uffff0-9]+)(?:\\.(?:[a-z\\u00a1-\\uffff0-9]+-?)*[a-z\\u00a1-\\uffff0-9]+)*(?:\\.(?:[a-z\\u00a1-\\uffff]{2,})))(?::\\d{2,5})?(?:\\/[^\\s]*)?" options:NSRegularExpressionCaseInsensitive error:&error];
    NSRange hyperlinkRange = [hyperlinkValidator rangeOfFirstMatchInString:selectedString options:NSCaseInsensitiveSearch range:NSMakeRange(0, selectedRange.length)];
    
    if (hyperlinkRange.location != NSNotFound && hyperlinkRange.length != NSNotFound) {
        NSString *hyperlink = [NSString stringWithFormat:@"[%@](%@)", selectedString, selectedString];
        [self.aTextView.textStorage beginEditing];
        [self.aTextView.textStorage replaceCharactersInRange:selectedRange withString:hyperlink];
        [self.aTextView.textStorage endEditing];
        selectedRange.location += 1;
    }
    else {
        NSString *defaultURL = @"http://loremipsumapp.com";
        NSString *hyperlink = [NSString stringWithFormat:@"[%@](%@)", selectedString, defaultURL];
        [self.aTextView.textStorage beginEditing];
        [self.aTextView.textStorage replaceCharactersInRange:selectedRange withString:hyperlink];
        [self.aTextView.textStorage endEditing];
        selectedRange.location += selectedString.length+3;
        selectedRange.length = defaultURL.length;
    }
    [self.aTextView setSelectedRange:selectedRange];
    [self.markdownPopover close];
}

- (IBAction)makeMDList:(id)sender
{
    [self.aTextView convertList:sender];
}

- (IBAction)showHTML:(id)sender
{
    if ([[self.splitContainer subviews] count] == 1 || [self.markdownViewContainer isHidden]) {
        if (!markdownPreview) {
            markdownPreview = [[LIWebView alloc] initWithFrame:NSMakeRect(0, 0, editorView.frame.size.width/3, editorView.frame.size.height)];
            [markdownPreview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
            [markdownPreview setDrawsBackground:NO];
            
            [markdownPreview setEditingDelegate:self];
            [markdownPreview setUIDelegate:self];
            [markdownPreview setFrameLoadDelegate:self];
            
            [markdownPreview registerForDraggedTypes:[NSArray arrayWithObjects:NSURLPboardType, nil]];
        }
        
        if (!markdownViewContainer) {
            markdownViewContainer = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 0, editorView.frame.size.height)];
            [markdownViewContainer addSubview:markdownPreview];
            [markdownViewContainer setHidden:YES];
            [self.splitContainer addSubview:markdownViewContainer];
            
            // Подготовка Invocation
            SEL selector = @selector(updateMarkdownPreviewInstantly:);
            NSMethodSignature *signature = [[self class] instanceMethodSignatureForSelector:selector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            BOOL updateNow = NO;
            
            [invocation setSelector:selector];
            [invocation setTarget:self];
            [invocation setArgument:&updateNow atIndex:2];
            
            [self updateMarkdownPreviewInstantly:YES];
            [self.splitContainer animateSubviewAtIndex:1 collapse:NO];
            
            self.markdownTimer = [NSTimer scheduledTimerWithTimeInterval:[[settingsProxy valueForSetting:@"markdownAutoupdate"] floatValue] invocation:invocation repeats:YES];
        }
        
        else {
            [self.splitContainer animateSubviewAtIndex:1 collapse:NO];
        }
        
    }
    else
        [self.splitContainer animateSubviewAtIndex:1 collapse:YES];
}

#pragma mark Other

- (IBAction)copyHTML:(id)sender
{
    NSString *htmlString = [ORCDiscount markdown2HTML:[[aTextView textStorage] string]];
    
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard declareTypes:[NSArray arrayWithObject:NSPasteboardTypeHTML] owner:nil];
    [pasteboard setString:htmlString forType:NSPasteboardTypeHTML];
}

- (IBAction)createBookmark:(id)sender
{
    [self insertMarkerWithIdentifier:@"bookmark"];
}

- (IBAction)showHideCounters:(id)sender
{
    if ([[self.gradientView infoLayer] isHidden]) {
        [[self.gradientView infoLayer] setHidden:NO];
        [settingsProxy setValue:[NSNumber numberWithBool:YES] forSettingName:@"showCounts"];
    }
    else {
        [[self.gradientView infoLayer] setHidden:YES];
        [settingsProxy setValue:[NSNumber numberWithBool:NO] forSettingName:@"showCounts"];
    }
    
    NSMutableDictionary *buffer = [[[NSUserDefaults standardUserDefaults] objectForKey:@"LIInitSettings"] mutableCopy];
    [buffer setValue:[settingsProxy valueForSetting:@"showCounts"] forKey:@"showCounts"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LIInitSettings"];
    [[NSUserDefaults standardUserDefaults] setObject:buffer forKey:@"LIInitSettings"];
}

- (IBAction)gotoLineOpenSheet:(id)sender
{
    if (!gotoSheet) {
        gotoSheet = [[LIGoToLineController alloc] initWithWindowNibName:@"LIGoToLineController"];
    }
    
    NSArray *arr = [[self.aTextView.textStorage string] linesRanges];
    NSRange currRange = [self.aTextView selectedRange];
    [NSApp beginSheet:gotoSheet.window modalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
    for (NSValue* value in arr) {
        if (![value isEqualToValue:[arr lastObject]]) {
            NSRange range = [value rangeValue];
            NSUInteger index = [arr indexOfObject:value];
            NSRange nextRange = [[arr objectAtIndex:index+1] rangeValue];
            if ((currRange.location >= range.location) && (currRange.location < nextRange.location)) {
                [gotoSheet.lineNumber setStringValue:[NSString stringWithFormat:@"%ld", index+1]];
                break;
            }
        }
    }
}

- (IBAction)exportHTML:(id)sender
{    
    NSString *htmlString = [ORCDiscount markdown2HTML:[[aTextView textStorage] string]];
    
    NSSavePanel *panel = [NSSavePanel savePanel];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents directory
    [panel setDirectoryURL:[NSURL fileURLWithPath:documentsDirectory]];
    [panel setAllowedFileTypes:[NSArray arrayWithObject:@"html"]];
    [panel setExtensionHidden:NO];
    [panel setNameFieldStringValue:[NSString stringWithFormat:@"%@", [self.document displayName]]];
    
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger returnCode) {
        NSError *error;
        if (![htmlString writeToURL:panel.URL atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Can't save HTML here." defaultButton:@"Ok." alternateButton:@"" otherButton:@"" informativeTextWithFormat:@"Check saving directory."];
            [alert setAlertStyle:NSCriticalAlertStyle];
            [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
            return;
        }
    }];
}

- (IBAction)exportPDF:(id)sender
{   
    NSSavePanel *panel = [NSSavePanel savePanel];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents directory
    [panel setDirectoryURL:[NSURL fileURLWithPath:documentsDirectory]];
    [panel setAllowedFileTypes:[NSArray arrayWithObject:@"pdf"]];
    [panel setExtensionHidden:NO];
    [panel setNameFieldStringValue:[NSString stringWithFormat:@"%@", [self.document displayName]]];
    
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger returnCode) {
        
        if (returnCode == 1) {
            NSMutableDictionary *prInfoDictionary = [[[self.document printInfo] dictionary] mutableCopy];
            [prInfoDictionary setObject:[panel URL] forKey:NSPrintJobSavingURL];
            
            NSPrintInfo *prInfo = [[NSPrintInfo alloc] initWithDictionary:prInfoDictionary];
            [prInfo setJobDisposition:NSPrintSaveJob];
            NSPrintOperation *prOPeration = [NSPrintOperation printOperationWithView:[self.document printableView] printInfo:prInfo];
            [prOPeration setShowsPrintPanel:NO];
            [prOPeration setShowsProgressPanel:NO];
            [prOPeration runOperation];
        }
    }];
}

- (IBAction)updateCountersManually:(id)sender
{
    [self setInfoString:[self simpleInfoStringWithTimerValue:nil bigText:NO]];
}

- (IBAction)turnOnAutoUpdateCounters:(id)sender
{
    if (!self.mazochisticMode && self.iAmBigText) {
        [self setMazochisticMode:YES];
    }
    else {
        [self setMazochisticMode:NO];
    }
}

- (IBAction)richTextPlainText:(id)sender
{
    NSError *error;
    NSString *proposedFileType;
    if ([[self.document fileType] compare:(NSString*)kUTTypeRTF] == NSOrderedSame || [[self.document fileType] compare:(NSString*)kUTTypeRTFD] == NSOrderedSame) {
        proposedFileType = (NSString*)kUTTypePlainText;
        if ([textPopover isShown])
            [textPopover close];
    }
    else {
        if ([self.markdownPopover isShown])
            [self.markdownPopover close];
        if ([[aTextView textStorage] containsAttachments])
            proposedFileType = (NSString*)kUTTypeRTFD;
        else proposedFileType = (NSString*)kUTTypeRTF;
    }
    
    LIDocument *docForReplace = [[LIDocument alloc] initWithType:proposedFileType error:&error];
    
    NSAttributedString *stringToInsert = [[NSAttributedString alloc] initWithAttributedString:[aTextView textStorage]];
    [docForReplace.textStorage insertAttributedString:stringToInsert atIndex:0];
    
    [self.document removeObserver:self.document forKeyPath:@"fileType"];
    [[NSDocumentController sharedDocumentController] removeDocument:self.document];
    [self setDocument:nil];
    
    [[NSDocumentController sharedDocumentController] addDocument:docForReplace];
    [docForReplace makeWindowControllersManual:YES];
    [docForReplace setFileURL:nil];
        
    if ([proposedFileType compare:(NSString*)kUTTypePlainText] == NSOrderedSame) {
        if ([[aTextView textStorage] length]) {
            [[aTextView textStorage] enumerateAttributesInRange:NSMakeRange(0, [[aTextView textStorage] length]) options:NSAttributedStringEnumerationReverse usingBlock:^(NSDictionary *attributes, NSRange range, BOOL *stop) {
                NSMutableDictionary *mutableAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
                if (![mutableAttributes valueForKey:NSAttachmentAttributeName]) {
                    [[aTextView textStorage] setAttributes:mutableAttributes range:range];
                    if (!(NSParagraphStyle*)[mutableAttributes valueForKey:NSParagraphStyleAttributeName] || [(NSParagraphStyle*)[mutableAttributes valueForKey:NSParagraphStyleAttributeName] alignment] != NSLeftTextAlignment) {
                        NSMutableParagraphStyle *leftAlignmentStyle = [[NSMutableParagraphStyle alloc] init];
                        [leftAlignmentStyle setAlignment:NSLeftTextAlignment];
                        [[aTextView textStorage] addAttribute:NSParagraphStyleAttributeName value:leftAlignmentStyle range:range];
                    }
                }
            }];
        }
    }
    else {
        if ([[splitContainer subviews] count] == 2) {
            [splitContainer animateSubviewAtIndex:1 collapse:YES];
            [[[splitContainer subviews] objectAtIndex:1] removeFromSuperview];
            markdownViewContainer = nil;
            markdownPreview = nil;
            if ([markdownTimer isValid])
                [markdownTimer invalidate];
        }
    }
    
    [self updateCountersManually:self];
}

- (IBAction)toggleSmartPares:(id)sender
{
    [settingsProxy setValue:[NSNumber numberWithBool:![sender state]] forSettingName:@"useSmartPares"];
}

@end
