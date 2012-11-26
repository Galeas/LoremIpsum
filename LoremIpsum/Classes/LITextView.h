//
//  TATextView.h
//  TextArtist
//
//  Created by Akki on 22.05.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface LITextView : NSTextView

#pragma mark List Handling
- (IBAction)markedListInsertion:(id)sender;
- (IBAction)numberedListInsertion:(id)sender;
- (IBAction)listConversion:(id)sender;

#pragma mark Indentation
- (IBAction)listLevelIncreasing:(id)sender;
- (IBAction)listLevelDecreasing:(id)sender;
- (IBAction)increaseQuoteLevel:(id)sender;
- (IBAction)decreaseQuoteLevel:(id)sender;

#pragma mark Coordinates & rects handling
- (NSRect)rectForPopover;
- (NSRect)rectForBookmarkAnimation:(NSRange)aRange;
- (NSDictionary *)maskForRange:(NSRange)aRange;

#pragma mark Style & Attributes Handling
- (NSParagraphStyle *)styleForParagraphRange:(NSRange)pRange;
- (NSDictionary *)attributesAtRange:(NSRange)aRange;
- (NSArray*)selectionFinder;
- (NSUInteger)indexOfBeginningOfWordAtrange:(NSRange)range;

#pragma mark Font Handling
- (NSFont *)currentFont;

#pragma mark Attachments Handling
- (void)removeAttachmentsInString:(NSMutableAttributedString *)attrStr;
- (void)removeAttachmentAtPosition:(NSUInteger)position;
- (NSArray *)bookmarks;

/*{
    NSMutableArray *_markedListRanges_insert;
    NSMutableArray *_markedListRanges_delete;
    
    NSMutableArray *_numberedListRanges_insert;
    NSMutableArray *_numberedListRanges_delete;
    
    CATextLayer *selectionOverlay;
}

@property (copy) NSColor *startColor;
@property (copy) NSColor *endColor;

- (NSRect)rectForPopover;
- (NSDictionary*)maskForRange:(NSRange)aRange;
- (NSRect)overlayRectForRange:(NSRange)aRange;
- (NSRect)rectForBookmarkAnimation:(NSRange)aRange;

- (NSParagraphStyle*)styleForParagraphRange:(NSRange)pRange;
- (NSDictionary*)attributesAtRange:(NSRange)aRange;
- (NSFont*)currentFont;
- (void)textViewDoForegroundLayoutToCharacterIndex:(NSUInteger)loc;

- (NSArray*)selectionFinder;

- (void) removeAttachments;
- (void) removeAttachmentsInString:(NSMutableAttributedString*)attrStr;
- (void) removeAttachmentAtPosition:(NSUInteger)position;
- (NSArray*) bookmarks;

- (NSString*)separateWordAtRange:(NSRange)range;
- (NSUInteger)indexOfBeginningOfWordAtrange:(NSRange)range;

- (NSArray*)stringsFromRange:(NSRange)activeRange stringsCount:(NSUInteger)count;
- (NSString*)commandString:(NSString*)currentParagraphStr;
- (NSMutableString*)leadingTabs:(NSUInteger)tabsNumber;
- (NSUInteger)leadingTabsNumberInString:(NSString*)string withCmdString:(NSString*)cmdString;

- (IBAction)insertMarkedList:(id)sender;
- (IBAction)insertNumberedList:(id)sender;
- (IBAction)increaseListLevel:(id)sender;
- (IBAction)decreaseListLevel:(id)sender;
- (IBAction)convertList:(id)sender;
- (IBAction)increaseQuoteLevel:(id)sender;
- (IBAction)decreaseQuoteLevel:(id)sender;

- (void)markedListInsertion:(NSRange)range;
- (void)numberedListInsertion:(NSRange)range;
- (void)increasingIndentation:(NSRange)range;
- (void)decreasingIndentation:(NSRange)range;
- (void)listTypeConversion:(NSRange)range;
- (void)increasingQuoteLevel:(NSRange)range;
- (void)decreasingQuoteLevel:(NSRange)range;*/

@end
