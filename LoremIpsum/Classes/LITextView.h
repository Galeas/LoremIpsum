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

@property BOOL pasteHTML;
@end
