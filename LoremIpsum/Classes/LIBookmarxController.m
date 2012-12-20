//
//  LIBookmarxController.m
//  LoremIpsum
//
//  Created by Akki on 6/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LIBookmarxController.h"
#import "LIBookmark.h"
#import "NSColor+Hex.h"
#import "LIDocWindowController.h"
#import "LITextView.h"
#import "LITableView.h"
#import "ImageAndTextCell.h"
#import "LIDocument.h"
#import "ESSImageCategory.h"

@interface LIBookmarxController ()
{
    NSArray *dataSourceBeforeDeletion;
    NSArray *dataSourceAfterDeletion;
    
    id aSender;
    NSInteger lastModifiedRow;
}
@end

@implementation LIBookmarxController
@synthesize bArrayController;
@synthesize bookmarxTable;
@synthesize bookmarxDataSource;

+ (LIBookmarxController *)bookmarxController
{
    static LIBookmarxController *controller = nil;
    static dispatch_once_t predicate;
    dispatch_once( &predicate, ^{
        controller = [[LIBookmarxController alloc] initWithWindowNibName:@"LIBookmarxController"];
        
    } );
    return controller;
}

- (IBAction)closeSheet:(id)sender
{
    [self removeObserver:self forKeyPath:@"bookmarxDataSource"];
    [NSApp endSheet:self.window];
    [self.window orderOut:self];
    [self.window performClose:self];
    
    [self willChangeValueForKey:@"bookmarxDataSource"];
    [bookmarxDataSource removeAllObjects];
    [self didChangeValueForKey:@"bookmarxDataSource"];
    
    [aSender setAction:@selector(showWindow:)];
}

- (id)init
{
    self = [LIBookmarxController bookmarxController];
    if (self) {
        self->bookmarxDataSource = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    ImageAndTextCell *imgAndTextPos = [[ImageAndTextCell alloc] init];
    [imgAndTextPos setFont:[NSFont fontWithName:@"Geneva" size:12.0]];
    [imgAndTextPos setAlignment:NSCenterTextAlignment];
    [imgAndTextPos setWraps:NO];
    
    ImageAndTextCell *imgAndTextCont = [[ImageAndTextCell alloc] init];
    [imgAndTextCont setFont:[NSFont fontWithName:@"Geneva" size:12.0]];
    [imgAndTextCont setLineBreakMode:NSLineBreakByClipping];
    
    NSTableColumn *posColumn = [bookmarxTable tableColumnWithIdentifier:@"position"];
    NSTableColumn *contentColumn = [bookmarxTable tableColumnWithIdentifier:@"content"];
    
    [imgAndTextPos setEditable:NO];
    [imgAndTextCont setEditable:NO];
    
    [posColumn setDataCell:imgAndTextPos];
    [contentColumn setDataCell:imgAndTextCont];
    
    [bookmarxTable setDoubleAction:@selector(bookmarkDoubleClick)];
    
    [self.window setMinSize:NSMakeSize(560, 17)];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([menuItem action] == @selector(showWindow:) || [menuItem action] == @selector(closeSheet:)) {
        
        if ([[[NSApp mainWindow] windowController] isMemberOfClass:[LIDocWindowController class]]) {
            LIDocWindowController *controller = [[NSApp mainWindow] windowController];
            NSTextStorage *textStorage = [[controller aTextView] textStorage];
            
            if (![self.window isKeyWindow])
                [menuItem setTitle:@"Bookmarks Manager"];
            else
                [menuItem setTitle:@"Close Bookmarks Manager"];
            
            if ([textStorage containsAttachments])
                return YES;
            else
                return NO;
        }
    }
    
    return YES;
}

- (void)showWindow:(id)sender
{
    if (!aSender)
        aSender = sender;
    
    [self reloadDataSource];
    
    [NSApp beginSheet:self.window modalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:NULL];
    [self addObserver:self forKeyPath:@"bookmarxDataSource" options:NSKeyValueChangeRemoval context:NULL];
    
    [self updateSheetFrame];
    
    [sender setAction:@selector(closeSheet:)];
}

- (void)reloadDataSource
{
    if ([[[NSApp mainWindow] windowController] isMemberOfClass:[LIDocWindowController class]]) {
        
        if ([bookmarxDataSource count] != 0)
            [bookmarxDataSource removeAllObjects];

        NSArray *bookmarxRanges = [[NSArray alloc] initWithArray:[[[[NSApp mainWindow] windowController] aTextView] bookmarks]];
        for (NSValue *bMarkRangeValue in bookmarxRanges) {
            NSDictionary *bookmarkData = [self bookmarkData:[bMarkRangeValue rangeValue].location];
            LIBookmark *aBookmark = [[LIBookmark alloc] initWithBookmarkOnPosition:[NSString stringWithFormat:@"%ld", [bMarkRangeValue rangeValue].location] lineNumber:[bookmarkData valueForKey:@"lineNumber"] positionInParagraph:[bookmarkData valueForKey:@"inParagraph"] length:[bookmarkData valueForKey:@"bMarkLength"]];
            [self willChangeValueForKey:@"bookmarxDataSource"];
            [bookmarxDataSource addObject:aBookmark];
            [self didChangeValueForKey:@"bookmarxDataSource"];
        }
        
        [bookmarxTable selectRowIndexes:[NSIndexSet indexSetWithIndex:lastModifiedRow-1] byExtendingSelection:NO];
    }
}

- (void)bookmarkDoubleClick
{
    LIDocWindowController *controller = [[NSApp mainWindow] windowController];
    if ([controller isMemberOfClass:[LIDocWindowController class]]) { 
    
        //NSInteger position = [(LIBookmark*)[bookmarxDataSource objectAtIndex:[bookmarxTable clickedRow]] position];
        NSInteger position = [(LIBookmark*)[bookmarxDataSource objectAtIndex:[bookmarxTable selectedRow]] position];
        [[[[NSApp mainWindow] windowController] aTextView] scrollRangeToVisible:NSMakeRange(position, 0)];
        [[[[NSApp mainWindow] windowController] aTextView] setSelectedRange:NSMakeRange(position+1, 0)];
        
        [self closeSheet:aSender];
        
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
        CGImageRelease(imageRef);
        [bookmarkLayer setBounds:NSRectToCGRect(NSMakeRect(0, 0, bookmark.size.width, bookmark.size.height))];
        
        NSRect rectForImageLayer = [[controller aTextView] rectForBookmarkAnimation:NSMakeRange(position, 0)];
        [bookmarkLayer setPosition:NSPointToCGPoint(NSMakePoint(rectForImageLayer.origin.x, rectForImageLayer.origin.y-18))];
        [[[controller aTextView] layer] addSublayer:bookmarkLayer];
        
        CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform"];
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        anim.duration = 0.125;
        anim.repeatCount = 1;
        anim.autoreverses = YES;
        anim.removedOnCompletion = YES;
        anim.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.4, 1.4, 1.0)];
        [bookmarkLayer addAnimation:anim forKey:nil];
        [bookmarkLayer performSelector:@selector(removeFromSuperlayer) withObject:nil afterDelay:0.25];
    }
}

- (NSDictionary *)bookmarkData:(NSUInteger)bookmarkLocation
{
    LIDocWindowController *controller = [[NSApp mainWindow] windowController];
    NSUInteger index, numberOfLines, numberOfGlyphs = [[controller layoutMgr] numberOfGlyphs], lineNumber = 0;
    NSRange lineRange/*, currentLineRange*/;
    NSUInteger caretLocation = bookmarkLocation;
    
    for (numberOfLines = 0, index = 0; index < numberOfGlyphs; numberOfLines++){
        (void)[[controller layoutMgr] lineFragmentRectForGlyphAtIndex:index effectiveRange:&lineRange];
        if (caretLocation > lineRange.location) {
            //currentLineRange = lineRange;
            lineNumber++;
        }
        index = NSMaxRange(lineRange);
    }
    
    NSRange bookmarkMaxRange = NSMakeRange(caretLocation, 75);
    
    NSRange paragraphRange = [[[[controller aTextView] textStorage] string] paragraphRangeForRange:NSMakeRange(caretLocation, 0)];
    NSInteger positionInParagraph = caretLocation - paragraphRange.location;
    if (caretLocation + bookmarkMaxRange.length > [[[[controller aTextView] textStorage] string] length])
        bookmarkMaxRange = NSMakeRange(caretLocation, [[[[controller aTextView] textStorage] string] length] - caretLocation);
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:positionInParagraph], @"inParagraph", [NSNumber numberWithUnsignedInteger:bookmarkMaxRange.length], @"bMarkLength", [NSNumber numberWithUnsignedInteger:lineNumber], @"lineNumber", nil];
    return dict;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    LIDocWindowController *controller = [[NSApp mainWindow] windowController];
    
    [self updateSheetFrame];

    NSArray *aNew = [change valueForKey:@"new"];
    NSArray *anOld = [change valueForKey:@"old"];
    
    if (![aNew isEqualToArray:anOld]) {
        LIBookmark *bMarkToDelete = nil;
        for (LIBookmark *bMark in anOld) {
            if (![aNew containsObject:bMark]) {
                bMarkToDelete = bMark;
                lastModifiedRow = [bookmarxTable selectedRow];
            }
        }
    
        [[controller aTextView] removeAttachmentAtPosition:bMarkToDelete.position];
        [self reloadDataSource];
    }
    
    if ([aNew count] == 0) {
        [self closeSheet:self];
        return;
    }
}

- (void)updateSheetFrame
{
    
    if ([bookmarxDataSource count] > 0) {
        NSRect mainWindowFrame = [[NSApp mainWindow] frame];
        NSRect contentRect = [NSWindow contentRectForFrameRect:mainWindowFrame styleMask:NSTitledWindowMask];
    
        NSRect aNewFrame = NSZeroRect;
    
        NSRect frame = NSMakeRect (0, 0, 100, 100);
        CGFloat titleBarHeight = frame.size.height - [NSWindow contentRectForFrameRect: frame styleMask: NSTitledWindowMask].size.height;

        CGFloat tableHeight = ([bookmarxTable rowHeight]+2)*([bookmarxDataSource count]-1);
        if (tableHeight > contentRect.size.height*0.8)
            tableHeight = contentRect.size.height*0.8;
        
        aNewFrame = NSMakeRect(self.window.frame.origin.x, contentRect.origin.y+contentRect.size.height-tableHeight-titleBarHeight, self.window.frame.size.width, tableHeight+titleBarHeight);
        [[self.window animator] setFrame:aNewFrame display:YES];
    
        NSTableColumn *column = [bookmarxTable tableColumnWithIdentifier:@"position"];
        [column sizeToFit];
    }
}

@end
