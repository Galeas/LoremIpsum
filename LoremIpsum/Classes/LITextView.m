//
//  TATextView.m
//  TextArtist
//
//  Created by Akki on 22.05.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LITextView.h"
#import "LIDocument.h"
#import "NSColor+Hex.h"
#import "NSString+Trimming.h"
#import "LITextAttachmentCell.h"
#import "LIDocWindowController.h"
#import "LISettingsProxy.h"
#import <QuartzCore/QuartzCore.h>

#define UndoManager [[[[self window] windowController] document] undoManager]

@implementation LITextView

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard type:(NSString *)type
{
    NSData *data;
    if ([[pboard types] containsObject:NSStringPboardType])
        data = [pboard dataForType:NSStringPboardType];
    if ([[pboard types] containsObject:NSHTMLPboardType])
        data = [pboard dataForType:NSHTMLPboardType];
    [self insertText:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
    return YES;
}

- (NSParagraphStyle *)defaultParagraphStyle
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:15.0f];
    [paragraphStyle setParagraphSpacing:25.0f];    
    return paragraphStyle;
}

- (void)draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint
{
    NSRange theTextRange = [[self layoutManager] glyphRangeForCharacterRange:[self selectedRange] actualCharacterRange:NULL];
    NSRect layoutRect = [[self layoutManager] boundingRectForGlyphRange:theTextRange inTextContainer:[self textContainer]];
    NSPoint containerOrigin = [self textContainerOrigin];
    layoutRect.origin.x += containerOrigin.x;
    layoutRect.origin.y += containerOrigin.y;
    layoutRect = [self convertRectToLayer:layoutRect];
    if (![self wantsLayer])
        [self setWantsLayer:YES];
    if (!selectionOverlay)
        selectionOverlay = [CATextLayer layer];
    [selectionOverlay setBackgroundColor:[(NSColor*)[[self selectedTextAttributes] valueForKey:NSBackgroundColorAttributeName] coreGraphicsColorWithAlfa:1]];
    [selectionOverlay setFrame:NSRectToCGRect(layoutRect)];
    [selectionOverlay setString:[self attributedSubstringFromRange:[self selectedRange]]];
    [self.layer addSublayer:selectionOverlay];
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
    NSPoint draggingLocation = [self convertPoint:[sender draggingLocation] fromView:nil];
    NSUInteger position = [self characterIndexForInsertionAtPoint:draggingLocation];
    [[self window] makeFirstResponder:self];
    [self setSelectedRange:NSMakeRange(position, 0)];
    
    return  [super draggingUpdated:sender];
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender
{
    [selectionOverlay removeFromSuperlayer];
    if (self.wantsLayer)
        [self setWantsLayer:NO];
}

- (NSUInteger)characterIndexForPoint:(NSPoint)aPoint
{
    NSUInteger glyphIndex;
    NSLayoutManager *layoutManager = [self layoutManager];
    CGFloat fraction;
    NSRange range;
    
    range = [layoutManager glyphRangeForTextContainer:[self textContainer]];
    glyphIndex = [layoutManager glyphIndexForPoint:aPoint inTextContainer:[self textContainer] fractionOfDistanceThroughGlyph:&fraction];
    if( fraction > 0.5 ) glyphIndex++;
    
    if( glyphIndex == NSMaxRange(range) )
        return  [[self textStorage] length];
    else
        return [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
}

- (void)removeAttachments {
    //NSTextStorage *attrString = [self textStorage];
    NSUInteger loc = 0;
    NSUInteger end = [[self textStorage] length];
    
    while (loc < end) {	// Run through the string in terms of attachment runs
        NSRange attachmentRange;	// Attachment attribute run
        NSTextAttachment *attachment = [[self textStorage] attribute:NSAttachmentAttributeName atIndex:loc longestEffectiveRange:&attachmentRange inRange:NSMakeRange(loc, end-loc)];
        if (attachment) {	// If there is an attachment and it is on an attachment character, remove the character 
            if (![[(LITextAttachmentCell*)[attachment attachmentCell] identifier] isEqualToString:@"bookmark"]) {
                [[self textStorage] beginEditing];
                unichar ch = [[[self textStorage] string] characterAtIndex:loc];
                if (ch == NSAttachmentCharacter) {
                    if ([self shouldChangeTextInRange:NSMakeRange(loc, 1) replacementString:@""]) {
                        [[self textStorage] replaceCharactersInRange:NSMakeRange(loc, 1) withString:@""];
                        [self didChangeText];
                    }
                    end = [[self textStorage] length];	// New length
                }
                [[self textStorage] endEditing];
            }
            else loc++;	// Just skip over the current character...
        }
    	else loc = NSMaxRange(attachmentRange);
    }
}

- (void)removeAttachmentsInString:(NSMutableAttributedString *)attrStr
{
    NSUInteger loc = 0;
    NSUInteger end = [attrStr length];
    
    while (loc < end) {	// Run through the string in terms of attachment runs
        NSRange attachmentRange;	// Attachment attribute run 
        NSTextAttachment *attachment = [attrStr attribute:NSAttachmentAttributeName atIndex:loc longestEffectiveRange:&attachmentRange inRange:NSMakeRange(loc, end-loc)];
        if (attachment) {	// If there is an attachment and it is on an attachment character, remove the character 
            unichar ch = [[attrStr string] characterAtIndex:loc];
            if (ch == NSAttachmentCharacter) {
                [attrStr removeAttribute:NSAttachmentAttributeName range:attachmentRange];
                [[attrStr mutableString] replaceCharactersInRange:attachmentRange withString:@""];
                end = [attrStr length];	// New length 
            }
            else loc++;	// Just skip over the current character...
        }
    	else loc = NSMaxRange(attachmentRange);
    }
}

- (void)removeAttachmentAtPosition:(NSUInteger)position
{
    NSTextStorage *text = [self textStorage];
    [text beginEditing];
    NSRange attachmentRange;
    NSTextAttachment *attachment = [text attribute:NSAttachmentAttributeName atIndex:position longestEffectiveRange:&attachmentRange inRange:NSMakeRange(position, 1)];
    if (attachment) {
        unichar ch = [[text string] characterAtIndex:position];
        if (ch == NSAttachmentCharacter) {
            if ([self shouldChangeTextInRange:NSMakeRange(position, 1) replacementString:@""]) {
                [text replaceCharactersInRange:NSMakeRange(position, 1) withString:@""];
                [self didChangeText];
            }
        }
    }
    [text endEditing];
}

- (NSArray *)bookmarks
{
    NSTextStorage *aTextStorage = [self textStorage];
    NSUInteger location = 0;
    NSUInteger end = [aTextStorage length];
    NSMutableArray *bookmarksArray = [[NSMutableArray alloc] init];
    
    while (location < end) {
        NSRange bookmarkRange;
        NSTextAttachment *bookmark = [aTextStorage attribute:NSAttachmentAttributeName atIndex:location longestEffectiveRange:&bookmarkRange inRange:NSMakeRange(location, end - location)];
        if (bookmark) {
            unichar ch = [[aTextStorage string] characterAtIndex:location];
            if (ch == NSAttachmentCharacter) {
                [bookmarksArray addObject:[NSValue valueWithRange:NSMakeRange(location, 0)]];
                location++;
            }
            else location++;
        }
        else location = NSMaxRange(bookmarkRange);
    }
    return bookmarksArray;
}

- (NSDictionary *)selectedTextAttributes
{
    if (![[[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.whiteBlack"] boolValue])
        return [NSDictionary dictionaryWithObjectsAndKeys:[NSColor colorWithHex:@"#808080"], NSBackgroundColorAttributeName, [NSColor colorWithHex:@"#333333"], NSForegroundColorAttributeName,  nil];
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSColor colorWithHex:[[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.textColor"]], NSForegroundColorAttributeName, [NSColor colorWithHex:@"#B4D4FF"], NSBackgroundColorAttributeName, nil];
}

- (NSRect)rectForPopover
{   
    NSRange selectedRange = [self selectedRange];
    
    NSRect rect = [self firstRectForCharacterRange:selectedRange];
    NSRect txtViewBounds = [self convertRectToBacking:[self bounds]];
    txtViewBounds = [self.window convertRectToScreen:txtViewBounds];
    
    rect = [[self superview] convertRect:rect toView:nil];
    rect = [self.window convertRectToScreen:rect];

    rect.origin = NSMakePoint(rect.origin.x - txtViewBounds.origin.x - self.window.frame.origin.x, rect.origin.y);
    
    return rect;
}

- (NSRect)rectForBookmarkAnimation:(NSRange)aRange
{
    NSUInteger location = aRange.location;
    NSPoint containerOrigin = [self textContainerOrigin];
    
    NSRange attachmentRange;	/* Attachment attribute run */
    (void)[[self textStorage] attribute:NSAttachmentAttributeName atIndex:location longestEffectiveRange:&attachmentRange inRange:NSMakeRange(location, [self textStorage].length-location)];
    
    NSRange placeRange = [[self layoutManager] glyphRangeForCharacterRange:attachmentRange actualCharacterRange:NULL];
    NSRect layoutRect = [[self layoutManager] boundingRectForGlyphRange:placeRange inTextContainer:[self textContainer]];

    layoutRect.origin.x += containerOrigin.x + 8;
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7
    NSRect frame = NSMakeRect (0, 0, 100, 100);
    NSRect contentRect;
    contentRect = [NSWindow contentRectForFrameRect:frame styleMask:NSTitledWindowMask];
    CGFloat titleBarHeight = (frame.size.height - contentRect.size.height);
    
    layoutRect.origin.y += containerOrigin.y + titleBarHeight + 3;// + 3 коррекция; иначе показывается чуть выше
#endif
    
#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_8
    layouteRect.origin.y += containerOrigin.y + 30;
#endif
    
    layoutRect.size.width = 16;
    
    layoutRect = [self convertRectToLayer:layoutRect];
    
    return layoutRect;
}

- (NSDictionary *)maskForRange:(NSRange)aRange
{
    NSRect txtViewBounds = [self convertRectToBacking:[self bounds]];
    txtViewBounds = [self.window convertRectToScreen:txtViewBounds];
    
    NSRect rect = [self overlayRectForRange:aRange];
    
    NSRect topMask = NSMakeRect(0, 0, txtViewBounds.size.width, rect.origin.y);
    NSRect bottomMask = NSMakeRect(0, rect.origin.y + rect.size.height, txtViewBounds.size.width, txtViewBounds.size.height - (rect.size.height + topMask.size.height));
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithRect:bottomMask], @"bottomMask", [NSValue valueWithRect:topMask], @"topMask", nil];
}

- (NSRect)overlayRectForRange:(NSRange)aRange
{    
    NSRange theTextRange = [[self layoutManager] glyphRangeForCharacterRange:aRange actualCharacterRange:NULL];
    NSRect layoutRect = [[self layoutManager] boundingRectForGlyphRange:theTextRange inTextContainer:[self textContainer]];
    NSPoint containerOrigin = [self textContainerOrigin];
    layoutRect.origin.x += containerOrigin.x;
    layoutRect.origin.y += containerOrigin.y;
    
    layoutRect = [self convertRectToLayer:layoutRect];
    layoutRect.origin = NSMakePoint([self textContainerOrigin].x, layoutRect.origin.y);
    layoutRect.size.width = [[self textContainer] containerSize].width;
    
    return layoutRect;
}

- (NSParagraphStyle *)styleForParagraphRange:(NSRange)pRange
{
    NSRange effectiveRange;
    if (pRange.location == [[self textStorage] length]) {
        pRange.location -= 1;
    }
    NSDictionary *attribs = [[self textStorage] attributesAtIndex:pRange.location effectiveRange:&effectiveRange];    
    NSParagraphStyle *paragraphStyle = [attribs valueForKey:NSParagraphStyleAttributeName];
    
    if (!paragraphStyle)
        paragraphStyle = [NSParagraphStyle defaultParagraphStyle];
    return paragraphStyle;
}

- (NSDictionary *)attributesAtRange:(NSRange)aRange
{
    NSRange effectiveRange;
    
    NSTextStorage *currStorage = [self textStorage];
    
    if ([currStorage length] == 0) {
        return nil;
    }
    
    if (aRange.location >= [[self.textStorage string] length])
        aRange = NSMakeRange([[self.textStorage string] length]-1, aRange.length);
    
    NSDictionary *attribs = [currStorage attributesAtIndex:aRange.location effectiveRange:&effectiveRange];
    return attribs;
}

- (NSFont *)currentFont
{
    NSRange effectiveRange;
    NSRange usefulRange = [self selectedRange];
    if (usefulRange.location == [[self textStorage] length])
        usefulRange.location = usefulRange.location-1;
    return [[self textStorage] attribute:NSFontAttributeName atIndex:usefulRange.location effectiveRange:&effectiveRange];
}

- (void)keyDown:(NSEvent *)theEvent
{
    if ([[[LISettingsProxy proxy] valueForSetting:@"useSmartPares"] boolValue]) {
        NSString *keyPressed = [theEvent charactersIgnoringModifiers];
        NSCharacterSet *enteredSet = [NSCharacterSet characterSetWithCharactersInString:@"({[<'\""];
        unichar insertedCode = [keyPressed characterAtIndex:0];
        NSInteger currentPos = self.selectedRange.location;
        
        if ([keyPressed rangeOfCharacterFromSet:enteredSet].location != NSNotFound) {
            switch (insertedCode) {
                case 40: {
                    keyPressed = @")";
                    break;
                }
                case 91: {
                    keyPressed = @"]";
                    break;
                }
                case 123: {
                    keyPressed = @"}";
                    break;
                }
                case 60: {
                    keyPressed = @">";
                    break;
                }
                default:break;
            }
            [self insertText:keyPressed replacementRange:NSMakeRange(currentPos, 0)];
            [self setSelectedRange:NSMakeRange(currentPos, 0)];
        }
        
        else {
            switch (insertedCode) {
                case 127: {
                    if (self.string.length > 0 && self.selectedRange.location > 0) {
                        NSRange hitRange = NSMakeRange(currentPos, 1);
                        NSString *nextSymbol = [self.string substringWithRange:hitRange];
                        NSString *currentSymbol = [self.string substringWithRange:NSMakeRange(hitRange.location-1, 1)];
                        unichar next = [nextSymbol characterAtIndex:0];
                        unichar curr = [currentSymbol characterAtIndex:0];
                        
                        if ((curr == 40 && next == 41) || (curr == 91 && next == 93) || (curr == 123 && next == 125) || (curr == 60 && next == 62) || (curr == 39 && next == 39) || (curr == 34 && next == 34))
                            [self insertText:@"" replacementRange:hitRange];
                    }

                    break;
                }
                case 63272: {
                    if (self.string.length > 0 && [self selectedRange].location < self.string.length) {
                        NSRange hitRange = NSMakeRange(currentPos-1, 1);
                        NSString *prevSymbol = [self.string substringWithRange:hitRange];
                        NSString *currentSymbol = [self.string substringWithRange:NSMakeRange(hitRange.location+1, 1)];
                        unichar prev = [prevSymbol characterAtIndex:0];
                        unichar curr = [currentSymbol characterAtIndex:0];
                        
                        if ((prev == 40 && curr == 41) || (prev == 91 && curr == 93) || (prev == 123 && curr == 125) || (prev == 60 && curr == 62) || (prev == 39 && curr == 39) || (prev == 34 && curr == 34))
                            [self insertText:@"" replacementRange:hitRange];
                    }
                    break;
                }
            }
        }
    }
    
    if ([[[[self.window windowController] document] docType] isEqualToString:TXT] && self.selectedRange.length == 0) {
        NSError *error;
        NSRange paragraphRange;
        NSString *paragraphString, *commandString;
        NSString *leadingTabs;
        
        NSRange activeRange = [self selectedRange];
        
        unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
        if (key == 3 || key == 9 || key == 13) {
            paragraphRange = [[[self textStorage] string] paragraphRangeForRange:activeRange];
            paragraphString = [[[self textStorage] string] substringWithRange:paragraphRange];
            commandString = [self commandString:paragraphString];
            
            NSUInteger leadingTabsNumber = [self leadingTabsNumberInString:paragraphString withCmdString:commandString];
            leadingTabs = [self leadingTabs:leadingTabsNumber];
        }
        else {
            [super keyDown:theEvent];
            return;
        }
        
            // Обработка Enter/Return
        if (key == 3 || key == 13) {
            if ([commandString hasPrefix:@"* "] || [commandString hasPrefix:@"- "]) {
                NSString *marker;
                if ([commandString hasPrefix:@"* "])
                    marker = @"* ";
                else
                    marker = @"- ";
        
                if (![[commandString stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] isEqualToString:marker]) {
                    [super keyDown:theEvent];
                    [[self textStorage] beginEditing];
                    [[self textStorage] replaceCharactersInRange:[self selectedRange] withString:[leadingTabs stringByAppendingString:marker]];
                    [[self textStorage] endEditing];
                    return;
                }
                
                else {
                    if (leadingTabs.length != 0) {
                        [[self textStorage] beginEditing];
                        [[self textStorage] replaceCharactersInRange:paragraphRange withString:[[self leadingTabs:leadingTabs.length-1] stringByAppendingString:marker]];
                        [[self textStorage] endEditing];
                        return;
                    }
                    else {
                        [[self textStorage] beginEditing];
                        [[self textStorage] replaceCharactersInRange:paragraphRange withString:@""];
                        [[self textStorage] endEditing];
                        [super keyDown:theEvent];
                        return;
                    }
                }
            }
            else {
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^([0-9]*)\\.\\s" options:NSRegularExpressionCaseInsensitive error:&error];
                NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:commandString options:0 range:NSMakeRange(0, [commandString length])];
                
                if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
                    NSUInteger index = [[commandString substringWithRange:NSMakeRange(rangeOfFirstMatch.location, rangeOfFirstMatch.length-2)] intValue];
                    
                    if (![[commandString stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] isEqualToString:[commandString substringWithRange:rangeOfFirstMatch]]) {
                        [super keyDown:theEvent];
                        [[self textStorage] beginEditing];
                        [[self textStorage] replaceCharactersInRange:[self selectedRange] withString:[leadingTabs stringByAppendingString:[NSString stringWithFormat:@"%ld. ", index+1]]];
                        [[self textStorage] endEditing];
                        return;
                    }
                    else {
                        if (leadingTabs.length != 0) {
                            [[self textStorage] beginEditing];
                            [[self textStorage] replaceCharactersInRange:paragraphRange withString:[[self leadingTabs:leadingTabs.length-1] stringByAppendingString:@"1. "]];
                            [[self textStorage] endEditing];
                            return;
                        }
                        else {
                            [[self textStorage] beginEditing];
                            [[self textStorage] replaceCharactersInRange:paragraphRange withString:@""];
                            [[self textStorage] endEditing];
                            [super keyDown:theEvent];
                            return;
                        }
                    }
                }
                else {
                    [super keyDown:theEvent];
                    [[self textStorage] beginEditing];
                    [[self textStorage] replaceCharactersInRange:[self selectedRange] withString:leadingTabs];
                    [[self textStorage] endEditing];
                    return;
                }
            }
        }
        else if (key == 9) {
            if ([[commandString stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] isEqualToString:@"* "] || [[commandString stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] isEqualToString:@"- "]) {
                
                [[self textStorage] beginEditing];
                [[self textStorage] replaceCharactersInRange:paragraphRange withString:[[self leadingTabs:leadingTabs.length+1] stringByAppendingString:commandString]];
                [[self textStorage] endEditing];
                [self setSelectedRange:NSMakeRange(activeRange.location+1, 0)];
                return;
            }
            else {
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^([0-9]*)\\.\\s" options:NSRegularExpressionCaseInsensitive error:&error];
                NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:commandString options:0 range:NSMakeRange(0, [commandString length])];
                if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
                    [[self textStorage] beginEditing];
                    [[self textStorage] replaceCharactersInRange:paragraphRange withString:[[self leadingTabs:leadingTabs.length+1] stringByAppendingString:@"1. "]];
                    [[self textStorage] endEditing];
                    [self setSelectedRange:NSMakeRange(activeRange.location+1, 0)];
                    return;
                }
                else {
                    [super keyDown:theEvent];
                    return;
                }
            }
        }
    }
    
    [super keyDown:theEvent];
}

- (void)textViewDoForegroundLayoutToCharacterIndex:(NSUInteger)loc {
    NSUInteger len;
    if (loc > 0 && (len = [[self textStorage] length]) > 0) {
        NSRange glyphRange;
        if (loc >= len) loc = len - 1;
        /* Find out which glyph index the desired character index corresponds to */
        glyphRange = [[self layoutManager] glyphRangeForCharacterRange:NSMakeRange(loc, 1) actualCharacterRange:NULL];
        if (glyphRange.location > 0) {
            /* Now cause layout by asking a question which has to determine where the glyph is */
            (void)[[self layoutManager] textContainerForGlyphAtIndex:glyphRange.location - 1 effectiveRange:NULL];
        }
    }
}

- (NSArray*)selectionFinder
{
    NSAttributedString *contentString = [[NSAttributedString alloc] initWithAttributedString:[self textStorage]];
    NSRange limitRange = NSMakeRange(0, [contentString length]);
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSRange effectiveRange;
    id attributeValue;
    while (limitRange.length > 0) {
        attributeValue = [contentString attribute:NSBackgroundColorAttributeName atIndex:limitRange.location longestEffectiveRange:&effectiveRange inRange:limitRange];
        if ([[attributeValue hexColor] isEqualToString:@"#FFFB41"])
            [array addObject:[NSValue valueWithRange:NSMakeRange(effectiveRange.location, effectiveRange.length)]];
        limitRange = NSMakeRange(NSMaxRange(effectiveRange), NSMaxRange(limitRange) - NSMaxRange(effectiveRange));
    }
    return array;
}

-(NSString *)separateWordAtRange:(NSRange)range
{
    NSTextStorage *text = [self textStorage];
    NSMutableString *potentialWord;
    NSUInteger location = range.location;
    
    NSUInteger endOfWord = [[[text string] substringFromIndex:location] rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location + location;
    potentialWord = [[[text string] substringWithRange:NSMakeRange(location, endOfWord-location)] mutableCopy];
    
    NSUInteger beginningOfWord = location;
    NSString *hitTestString = [[NSString alloc] initWithString:[[text string] substringWithRange:NSMakeRange(beginningOfWord, 1)]];
    while ([hitTestString rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location == NSNotFound || beginningOfWord == 0) {
        beginningOfWord--;
        potentialWord = [[hitTestString stringByAppendingString:potentialWord] mutableCopy];
        hitTestString = [[text string] substringWithRange:NSMakeRange(beginningOfWord, 1)];
    }
    
    return potentialWord;
}

- (NSUInteger)indexOfBeginningOfWordAtrange:(NSRange)range
{
    NSTextStorage *text = [self textStorage];
    NSMutableString *potentialWord;
    NSUInteger location = range.location;
    NSUInteger endOfWord;
    
    NSRange endRange = [[[text string] substringFromIndex:location] rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (endRange.location == NSNotFound) {  //Не нашли пробел или обрыв строки - конец текста?
        if ([text length] - location > 75)
            endOfWord = location + 75;
        else
            endOfWord = location + (text.length - location);
    }
    else
        endOfWord = endRange.location + location;
    
    potentialWord = [[[text string] substringWithRange:NSMakeRange(location, endOfWord-location)] mutableCopy];
    
    NSUInteger beginningOfWord = location;
    //NSString *hitTestString = [[NSString alloc] initWithString:[[text string] substringWithRange:NSMakeRange(beginningOfWord, 1)]];
    NSRange aRange = NSMakeRange(NSNotFound, 0);
    
    while (aRange.location == NSNotFound) {
        beginningOfWord--;
        NSString *hitTestString = [[text string] substringWithRange:NSMakeRange(beginningOfWord, 1)];
        aRange = [hitTestString rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (aRange.location == NSNotFound)
            potentialWord = [[hitTestString stringByAppendingString:potentialWord] mutableCopy];
        if (beginningOfWord == 0)
            break;
    }
    return beginningOfWord;
}

- (NSString *)commandString:(NSString *)currentParagraphStr
{
    return [currentParagraphStr stringByTrimmingLeadingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSUInteger)leadingTabsNumberInString:(NSString *)string withCmdString:(NSString *)cmdString
{
    return [[string stringByReplacingOccurrencesOfString:cmdString withString:@""] numberOfOccurencesOfString:@"\t"];
}

- (NSMutableString *)leadingTabs:(NSUInteger)tabsNumber
{
    NSMutableString *lTabs = [[NSMutableString alloc] init];
    if (tabsNumber > 0) {
        for (int i = 0; i < tabsNumber; i++)
            lTabs = [[lTabs stringByAppendingString:@"\t"] mutableCopy];
    }
    else 
        lTabs = [NSMutableString stringWithString:@""];
    return lTabs;
}

- (NSArray *)stringsFromRange:(NSRange)activeRange stringsCount:(NSUInteger)count
{
    NSUInteger endOfSelection = NSMaxRange(activeRange);
    
    NSMutableArray *strings = [[NSMutableArray alloc] initWithCapacity:count];
    for (int i = 0; i < count; i++) {
        NSUInteger endOfParagraph = [[[[self textStorage] string] substringWithRange:activeRange] firstLineBreakPosition];
        if (endOfParagraph == NSNotFound)
            endOfParagraph = endOfSelection - activeRange.location;
        NSRange bufferRange = NSMakeRange(activeRange.location, endOfParagraph);        
        NSRange currentParagraphRange = [[[self textStorage] string] paragraphRangeForRange:bufferRange];
        NSString *currentParagraphString = [[[self textStorage] string] substringWithRange:currentParagraphRange];
        
        [strings insertObject:currentParagraphString atIndex:strings.count];
        
        activeRange = NSMakeRange(NSMaxRange(currentParagraphRange), endOfSelection - NSMaxRange(currentParagraphRange));
    }
    return strings;
}

- (void)markedListInsertion:(NSRange)range
{        
    BOOL isDeleting = NO;
    
    NSRange activeRange = range, selectionRange = range;
    NSUInteger numberOfParagraphs = [[[[self textStorage] string] substringWithRange:activeRange] numberOfOccurencesOfCharactersFromSet:[NSCharacterSet newlineCharacterSet]]+1;
    
    NSUInteger currentPosition = 0;
    
    NSTextList *list;
    NSString *bullet;
    if ([[[[[self window] windowController] document] docType] isEqualToString:TXT]) {
        list = [[NSTextList alloc] initWithMarkerFormat:@"* " options:0];
        bullet = [list markerForItemNumber:1];
    }
    else {
        list = [[NSTextList alloc] initWithMarkerFormat:@"{disc}" options:0];
        bullet = [NSString stringWithFormat:@"\t%@\t", [list markerForItemNumber:1]];
    }
    
    NSArray *strings = [self stringsFromRange:activeRange stringsCount:numberOfParagraphs];
    
    for (NSString *paragraphString in strings) {
        NSRange paragraphRange = [[[self textStorage] string] rangeOfString:paragraphString];
        
        if (paragraphRange.location == NSNotFound) {
            if ([strings indexOfObject:paragraphString] == 0)
                paragraphRange.location = range.location;
            else
                paragraphRange.location = currentPosition;
        }
        
        NSMutableDictionary *attrs = [[[NSMutableDictionary alloc] initWithDictionary:[self attributesAtRange:paragraphRange]] mutableCopy];
        NSMutableParagraphStyle *style = [[attrs valueForKey:NSParagraphStyleAttributeName] mutableCopy];
        
        if (!style) {
            NSString *commandString = [self commandString: paragraphString];
            NSUInteger leadingTabsNumber = [self leadingTabsNumberInString:paragraphString withCmdString:commandString];
            NSString *leadingTabs = [self leadingTabs:leadingTabsNumber];
            
            [[self textStorage] beginEditing];
            if ([commandString hasPrefix:@"* "] || [commandString hasPrefix:@"- "]) {
                NSMutableAttributedString *toAdd = [[self attributedSubstringFromRange:paragraphRange] mutableCopy];
                
                NSString *marker;
                if ([commandString hasPrefix:@"* "])
                    marker = @"* ";
                else
                    marker = @"- ";
                
                NSRange rangeOfFirstMatch = [[toAdd string] rangeOfString:marker];
                [toAdd replaceCharactersInRange:rangeOfFirstMatch withString:@""];
                [[self textStorage] replaceCharactersInRange:paragraphRange withAttributedString:toAdd];
            }
            
            else {
                NSMutableAttributedString *toAdd = [[NSMutableAttributedString alloc] initWithString:[leadingTabs stringByAppendingString:[bullet stringByAppendingString:commandString]] attributes:[self attributesAtRange:paragraphRange]];
                [[self textStorage] replaceCharactersInRange:paragraphRange withAttributedString:toAdd];
            }
            [[self textStorage] endEditing];
        }
        
        else if ([[style textLists] count] == 0) {
            
            [[self textStorage] beginEditing];
            [style setTextLists:[NSArray arrayWithObject:list]];
            [attrs setValue:style forKey:NSParagraphStyleAttributeName];
            
            NSString *commandString = [self commandString:paragraphString];
            NSUInteger leadingTabsNumber = [self leadingTabsNumberInString:paragraphString withCmdString:commandString];
            NSString *leadingTabs = [self leadingTabs:leadingTabsNumber];
            
            NSAttributedString *toAdd = [[NSAttributedString alloc] initWithString:[leadingTabs stringByAppendingString:[bullet stringByAppendingString:commandString]] attributes:attrs];
            [[self textStorage] replaceCharactersInRange:paragraphRange withAttributedString:toAdd];
            
            [[self textStorage] endEditing];
        }
        
        else if (style && [[style textLists] count] > 0) {
            [[self textStorage] beginEditing];
            
            NSMutableAttributedString *toAdd = [[self attributedSubstringFromRange:paragraphRange] mutableCopy];            
            if ([[(NSTextList*)[[style textLists] objectAtIndex:0] markerFormat] isEqualToString:@"{disc}"]) {
                
                [style setTextLists:nil];
                [attrs setValue:style forKey:NSParagraphStyleAttributeName];
                NSRange rangeOfFirstMatch = [toAdd.string rangeOfString:bullet];
                [toAdd replaceCharactersInRange:rangeOfFirstMatch withAttributedString:[[NSAttributedString alloc] initWithString:@""]];
                [toAdd addAttributes:attrs range:NSMakeRange(0, toAdd.length)];
                [[self textStorage] replaceCharactersInRange:paragraphRange withAttributedString:toAdd];
                
                isDeleting = YES;
            }
            
            else {

                NSError *error;
                NSString *commandString = [self commandString:paragraphString];
                
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^([0-9]*)\\.\\s" options:NSRegularExpressionCaseInsensitive error:&error];
                NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:commandString options:0 range:NSMakeRange(0, [commandString length])];
                
                [style setTextLists:[NSArray arrayWithObject:list]];
                [attrs setValue:style forKey:NSParagraphStyleAttributeName];
                [[self textStorage] setAttributes:attrs range:paragraphRange];
                
                NSRange trueRange;
                NSString *index = [commandString substringWithRange:rangeOfFirstMatch];
                trueRange = [paragraphString rangeOfString:index];
                trueRange = NSMakeRange(paragraphRange.location + trueRange.location, trueRange.length);                
                [[self textStorage] replaceCharactersInRange:trueRange withString:[NSString stringWithFormat:@"%@\t", [list markerForItemNumber:1]]];
            }
            
            [[self textStorage] endEditing];
        }
        
        currentPosition = NSMaxRange(paragraphRange)+1;
    }
    
    if (!isDeleting)
        [self setSelectedRange:NSMakeRange(selectionRange.location+bullet.length, selectionRange.length + bullet.length*numberOfParagraphs)];
    else
        [self setSelectedRange:NSMakeRange(selectionRange.location-bullet.length, selectionRange.length + bullet.length*numberOfParagraphs)];
}

- (void)numberedListInsertion:(NSRange)range
{   
    BOOL isDeleting = NO;
    NSRange activeRange = range, selectionRange = range;
    
    NSUInteger currentPosition = 0;
    
    NSUInteger numberOfParagraphs = [[[[self textStorage] string] substringWithRange:activeRange] numberOfOccurencesOfCharactersFromSet:[NSCharacterSet newlineCharacterSet]]+1;
    NSTextList *list = [[NSTextList alloc] initWithMarkerFormat:@"{decimal}." options:0];
    NSMutableArray *strings = [[self stringsFromRange:activeRange stringsCount:numberOfParagraphs] mutableCopy];
    
    for (NSString *paragraphString in strings) {
        NSRange paragraphRange = [[[self textStorage] string] rangeOfString:paragraphString];
        
        if (paragraphRange.location == NSNotFound) {
            if ([strings indexOfObject:paragraphString] == 0)
                paragraphRange.location = range.location;
            else
                paragraphRange.location = currentPosition;
        }
        
        NSMutableDictionary *attrs = [[[NSMutableDictionary alloc] initWithDictionary:[self attributesAtRange:paragraphRange]] mutableCopy];
        NSMutableParagraphStyle *style = [[attrs valueForKey:NSParagraphStyleAttributeName] mutableCopy];
        
        if ([[(NSParagraphStyle*)[attrs valueForKey:NSParagraphStyleAttributeName] textLists] count] == 0) {
        
            [[self textStorage] beginEditing];
            
            NSString *index;
            
            if ([[[[[self window] windowController] document] docType] isEqualToString:RTF])
                index = [NSString stringWithFormat:@"\t%@\t", [list markerForItemNumber:[strings indexOfObject:paragraphString]+1]];
            else
                index = [NSString stringWithFormat:@"%@ ", [list markerForItemNumber:[strings indexOfObject:paragraphString]+1]];
            
            [style setTextLists:[NSArray arrayWithObject:list]];
            [attrs setValue:style forKey:NSParagraphStyleAttributeName];
        
            NSString *commandString = [self commandString:paragraphString];
            NSUInteger leadingTabsNumber = [self leadingTabsNumberInString:paragraphString withCmdString:commandString];
            NSString *leadingTabs = [self leadingTabs:leadingTabsNumber];
        
            NSAttributedString *toAdd = [[NSAttributedString alloc] initWithString:[leadingTabs stringByAppendingString:[index stringByAppendingString:commandString]] attributes:attrs];
            [[self textStorage] replaceCharactersInRange:paragraphRange withAttributedString:toAdd];
            
            [[self textStorage] endEditing];
        }
        
        else {
            
            [[self textStorage] beginEditing];
            
            if (![[(NSTextList*)[[style textLists] objectAtIndex:0] markerFormat] isEqualToString:@"{disc}"]) {
                
                NSMutableAttributedString *toAdd = [[self attributedSubstringFromRange:paragraphRange] mutableCopy];
                [style setTextLists:nil];
                [attrs setValue:style forKey:NSParagraphStyleAttributeName];
                
                NSError *error;
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([0-9]*)\\.\\s" options:NSRegularExpressionCaseInsensitive error:&error];
                NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:toAdd.string options:0 range:NSMakeRange(0, [toAdd.string length])];
                
                [toAdd replaceCharactersInRange:rangeOfFirstMatch withAttributedString:[[NSAttributedString alloc] initWithString:@""]];
                [toAdd addAttributes:attrs range:NSMakeRange(0, toAdd.length)];
                [[self textStorage] replaceCharactersInRange:paragraphRange withAttributedString:toAdd];
                isDeleting = YES;
            }
            
            else {
                NSString *index;
                
                if ([[[[[self window] windowController] document] docType] isEqualToString:RTF])
                    index = [NSString stringWithFormat:@"%@\t", [list markerForItemNumber:[strings indexOfObject:paragraphString]+1]];
                else
                    index = [NSString stringWithFormat:@"%@ ", [list markerForItemNumber:[strings indexOfObject:paragraphString]+1]];
                
                [style setTextLists:[NSArray arrayWithObject:list]];
                [attrs setValue:style forKey:NSParagraphStyleAttributeName];
                
                NSString *commandString = [self commandString:paragraphString];
                NSUInteger leadingTabsNumber = [self leadingTabsNumberInString:paragraphString withCmdString:commandString];
                NSString *leadingTabs = [self leadingTabs:leadingTabsNumber];
                
                NSAttributedString *toAdd = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@%@", leadingTabs, index, [commandString stringByReplacingCharactersInRange:NSMakeRange(0, 2) withString:@""]] attributes:attrs];
                [[self textStorage] replaceCharactersInRange:paragraphRange withAttributedString:toAdd];
            }
            
            [[self textStorage] endEditing];
        }
        currentPosition = NSMaxRange(paragraphRange)+1;
    }
    if (!isDeleting)
        [self setSelectedRange:NSMakeRange(selectionRange.location+4, selectionRange.length + 4*numberOfParagraphs)];
    else
        [self setSelectedRange:NSMakeRange(selectionRange.location-4, selectionRange.length + 4*numberOfParagraphs)];
}

- (void)increasingIndentation:(NSRange)range
{
    NSRange activeRange = range, selectionRange = range;
    NSUInteger numberOfParagraphs = [[[[self textStorage] string] substringWithRange:activeRange] numberOfOccurencesOfCharactersFromSet:[NSCharacterSet newlineCharacterSet]]+1;
    NSArray *strings = [self stringsFromRange:activeRange stringsCount:numberOfParagraphs];
    
    NSUInteger currentPosition = 0;
    
    for (NSString *paragraphString in strings) {
        
        NSRange paragraphRange = [[[self textStorage] string] rangeOfString:paragraphString];
        
        if (paragraphRange.location == NSNotFound) {
            if ([strings indexOfObject:paragraphString] == 0)
                paragraphRange.location = range.location;
            else
                paragraphRange.location = currentPosition;
        }
        
        NSString *commandString = [self commandString:paragraphString];
        NSUInteger leadingTabsNumber = [self leadingTabsNumberInString:paragraphString withCmdString:commandString]+1;
        NSString *leadingTabs = [self leadingTabs:leadingTabsNumber];
        
        [[self textStorage] beginEditing];
        [[self textStorage] replaceCharactersInRange:paragraphRange withString:[leadingTabs stringByAppendingString:commandString]];
        [[self textStorage] endEditing];
        
        currentPosition = NSMaxRange(paragraphRange)+1;
    }
    [self setSelectedRange:NSMakeRange(selectionRange.location+[[NSString stringWithFormat:@"\t"] length], selectionRange.length+[[NSString stringWithFormat:@"\t"] length]*(numberOfParagraphs-1))];
}

- (void)decreasingIndentation:(NSRange)range
{
    BOOL performed = NO;
    NSRange activeRange = range, selectionRange = range;    
    NSUInteger numberOfParagraphs = [[[[self textStorage] string] substringWithRange:activeRange] numberOfOccurencesOfCharactersFromSet:[NSCharacterSet newlineCharacterSet]]+1;
    NSArray *strings = [self stringsFromRange:activeRange stringsCount:numberOfParagraphs];
    NSUInteger currentPosition = 0;
    
    for (NSString *paragraphString in strings) {
        NSRange paragraphRange = [[[self textStorage] string] rangeOfString:paragraphString];
        
        if (paragraphRange.location == NSNotFound) {
            if ([strings indexOfObject:paragraphString] == 0)
                paragraphRange.location = range.location;
            else
                paragraphRange.location = currentPosition;
        }
        
        NSString *commandString = [self commandString:paragraphString];
        NSUInteger leadingTabsNumber = [self leadingTabsNumberInString:paragraphString withCmdString:commandString];
        if (leadingTabsNumber > 0) {
            [[self textStorage] beginEditing];
            [[self textStorage] replaceCharactersInRange:paragraphRange withString:[[self leadingTabs:leadingTabsNumber-1] stringByAppendingString:commandString]];
            [[self textStorage] endEditing];
            currentPosition = NSMaxRange(paragraphRange)+1;
            performed = YES;
        }
    }
    if (performed)
        [self setSelectedRange:NSMakeRange(selectionRange.location-[[NSString stringWithFormat:@"\t"] length], selectionRange.length-[[NSString stringWithFormat:@"\t"] length]*(numberOfParagraphs-1))];
}

- (void)listTypeConversion:(NSRange)range
{
    NSError *error;
    
    NSRange activeRange = range;
    NSUInteger numberOfParagraphs = [[[[self textStorage] string] substringWithRange:activeRange] numberOfOccurencesOfCharactersFromSet:[NSCharacterSet newlineCharacterSet]]+1;
    NSMutableArray *strings = [[self stringsFromRange:activeRange stringsCount:numberOfParagraphs] mutableCopy];
    
    if (NSEqualRanges(range, [[[self textStorage] string] rangeOfString:[strings objectAtIndex:0]])) {
        numberOfParagraphs--;
        [strings removeLastObject];
    }
    
    NSTextList *markedList;
    NSString *bullet;
    if ([[[[[self window] windowController] document] docType] isEqualToString:RTF]) {
        markedList = [[NSTextList alloc] initWithMarkerFormat:@"{disc}" options:0];
        bullet = [NSString stringWithFormat:@"%@\t", [markedList markerForItemNumber:1]];
    }
    else {
        markedList = [[NSTextList alloc] initWithMarkerFormat:@"*" options:0];
        bullet = [NSString stringWithFormat:@"%@ ", [markedList markerForItemNumber:1]];
    }
    NSTextList *numberedList = [[NSTextList alloc] initWithMarkerFormat:@"{decimal}." options:0];
    
    //NSString *bullet = [NSString stringWithFormat:@"%@\t", [markedList markerForItemNumber:1]];
    
    NSUInteger currentPosition = 0;
    
    for (NSString *paragraphString in strings) {
        NSRange paragraphRange = [[[self textStorage] string] rangeOfString:paragraphString];
        
        if (paragraphRange.location == NSNotFound) {
            if ([strings indexOfObject:paragraphString] == 0)
                paragraphRange.location = range.location;
            else
                paragraphRange.location = currentPosition;
        }
        
        NSString *commandString = [self commandString:paragraphString];
        if (![commandString isEqualToString:@""]) {
            NSUInteger leadingTabsNumber = [self leadingTabsNumberInString:paragraphString withCmdString:commandString];
            NSString *leadingTabs = [self leadingTabs:leadingTabsNumber];
            NSMutableDictionary *attrs = [[[NSMutableDictionary alloc] initWithDictionary:[self attributesAtRange:paragraphRange]] mutableCopy];
            NSMutableParagraphStyle *style = [[attrs valueForKey:NSParagraphStyleAttributeName] mutableCopy];
            
            [[self textStorage] beginEditing];
            
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^([0-9]*)\\.\\s" options:NSRegularExpressionCaseInsensitive error:&error];
            NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:commandString options:0 range:NSMakeRange(0, [commandString length])];
            
            if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
                [style setTextLists:[NSArray arrayWithObject:markedList]];
                [attrs setValue:style forKey:NSParagraphStyleAttributeName];
                [[self textStorage] setAttributes:attrs range:paragraphRange];
                
                NSRange trueRange;
                NSString *index = [commandString substringWithRange:rangeOfFirstMatch];
                trueRange = [paragraphString rangeOfString:index];
                trueRange = NSMakeRange(paragraphRange.location + trueRange.location, trueRange.length);                
                [[self textStorage] replaceCharactersInRange:trueRange withString:bullet];
            }
            
            else {
                NSString *index;
                if ([[[self.window.windowController document] docType] isEqualToString:RTF])
                    index = [NSString stringWithFormat:@"%@\t",[numberedList markerForItemNumber:[strings indexOfObject:paragraphString]+1]];
                else
                    index = [NSString stringWithFormat:@"%@ ",[numberedList markerForItemNumber:[strings indexOfObject:paragraphString]+1]];
                //NSString *index = [NSString stringWithFormat:@"%@\t",[numberedList markerForItemNumber:[strings indexOfObject:paragraphString]+1]];
                [style setTextLists:[NSArray arrayWithObject:numberedList]];
                [attrs setValue:style forKey:NSParagraphStyleAttributeName];
                
                NSAttributedString *toAdd = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@%@", leadingTabs, index, [commandString stringByReplacingOccurrencesOfString:bullet withString:@""]] attributes:attrs];
                [[self textStorage] replaceCharactersInRange:paragraphRange withAttributedString:toAdd];
            }
            
            [[self textStorage] endEditing];
        }
        
        currentPosition = NSMaxRange(paragraphRange)+1;
    }
}

- (void)increasingQuoteLevel:(NSRange)range
{
    NSRange activeRange = range, toSelect = range;
    
    NSUInteger numberOfParagraphs = [[[[self textStorage] string] substringWithRange:activeRange] numberOfOccurencesOfCharactersFromSet:[NSCharacterSet newlineCharacterSet]]+1;
    NSArray *strings = [self stringsFromRange:activeRange stringsCount:numberOfParagraphs];
    
    NSUInteger currentPosition = 0;
    
    for (NSString *paragraphString in strings) {
        NSRange paragraphRange = [[[self textStorage] string] rangeOfString:paragraphString];
        
        if (paragraphRange.location == NSNotFound) {
            if ([strings indexOfObject:paragraphString] == 0)
                paragraphRange.location = range.location;
            else
                paragraphRange.location = currentPosition;
        }
        
        NSString *commandString = [self commandString:paragraphString];
        NSUInteger leadingTabsNumber = [self leadingTabsNumberInString:paragraphString withCmdString:commandString];
        NSString *leadingTabs = [self leadingTabs:leadingTabsNumber];
        
        NSString *toAdd = [NSString stringWithFormat:@"%@> %@", leadingTabs, commandString];
        [[self textStorage] beginEditing];
        [[self textStorage] replaceCharactersInRange:paragraphRange withString:toAdd];
        [[self textStorage] endEditing];
        
        currentPosition = NSMaxRange(paragraphRange)+1;
    }
    [self setSelectedRange:NSMakeRange(toSelect.location+2, toSelect.length)];
}

- (void)decreasingQuoteLevel:(NSRange)range
{
    NSRange activeRange = range, toSelect = range;
    NSUInteger numberOfParagraphs = [[[[self textStorage] string] substringWithRange:activeRange] numberOfOccurencesOfCharactersFromSet:[NSCharacterSet newlineCharacterSet]]+1;
    NSArray *strings = [self stringsFromRange:activeRange stringsCount:numberOfParagraphs];
    
    NSUInteger currentPosition = 0;
    
    for (NSString *paragraphString in strings) {
        NSRange paragraphRange = [[[self textStorage] string] rangeOfString:paragraphString];
        
        if (paragraphRange.location == NSNotFound) {
            if ([strings indexOfObject:paragraphString] == 0)
                paragraphRange.location = range.location;
            else
                paragraphRange.location = currentPosition;
        }
        
        NSString *commandString = [self commandString:paragraphString];
        NSUInteger leadingTabsNumber = [self leadingTabsNumberInString:paragraphString withCmdString:commandString];
        NSString *leadingTabs = [self leadingTabs:leadingTabsNumber];
        
        if ([commandString hasPrefix:@"> "]) {
            [[self  textStorage] beginEditing];
            NSString *toAdd = [leadingTabs stringByAppendingString:[commandString stringByReplacingCharactersInRange:[commandString rangeOfString:@"> "] withString:@""]];
            [[self textStorage] replaceCharactersInRange:paragraphRange withString:toAdd];
            [[self textStorage] endEditing];
        }
        currentPosition = NSMaxRange(paragraphRange)+1;
    }
    
    NSString *cString = [self commandString:[strings objectAtIndex:0]];
    if ([cString hasPrefix:@"> "])
        [self setSelectedRange:NSMakeRange(toSelect.location-2, toSelect.length)];
}

- (IBAction)insertMarkedList:(id)sender
{
    NSRange processingRange = [self selectedRange];
    [[[self undoManager] prepareWithInvocationTarget:self] markedListInsertion:processingRange];
    [[self undoManager] setActionName:@"marked list insertion"];
    
    [self markedListInsertion:processingRange];
}

- (IBAction)insertNumberedList:(id)sender
{
    NSRange processingRange = [self selectedRange];
    [[[self undoManager] prepareWithInvocationTarget:self] numberedListInsertion:processingRange];
    [[self undoManager] setActionName:@"numbered list insertion"];
    
    [self numberedListInsertion:processingRange];
}

- (IBAction)increaseListLevel:(id)sender
{
    NSRange processingRange = [self selectedRange];
    [[[self undoManager] prepareWithInvocationTarget:self] increasingIndentation:processingRange];
    if ([[sender title] isEqualToString:@"Increase list level"])
        [[self undoManager] setActionName:@"increase list level"];
    else
        [[self undoManager] setActionName:@"increase paragraph indentation"];
    
    [self increasingIndentation:[self selectedRange]];
}

- (IBAction)decreaseListLevel:(id)sender
{
    NSRange processingRange = [self selectedRange];
    [[[self undoManager] prepareWithInvocationTarget:self] decreasingIndentation:processingRange];
    if ([[sender title] isEqualToString:@"Decrease list level"])
        [[self undoManager] setActionName:@"decrease list level"];
    else
        [[self undoManager] setActionName:@"decrease paragraph indentation"];
    
    [self decreasingIndentation:processingRange];
}

- (IBAction)convertList:(id)sender
{   
    NSRange processingRange = [self selectedRange];
    [[[self undoManager] prepareWithInvocationTarget:self] listTypeConversion:processingRange];
    [[self undoManager] setActionName:@"list type conversion"];
    
    [self listTypeConversion:processingRange];
}

- (IBAction)increaseQuoteLevel:(id)sender
{
    NSRange processingRange = [self selectedRange];
    [[[self undoManager] prepareWithInvocationTarget:self] increasingQuoteLevel:processingRange];
    [[self undoManager] setActionName:@"increase quote level"];
    
    [self increasingQuoteLevel:processingRange];
}

- (IBAction)decreaseQuoteLevel:(id)sender
{
    NSRange processingRange = [self selectedRange];
    [[[self undoManager] prepareWithInvocationTarget:self] decreasingQuoteLevel:processingRange];
    [[self undoManager] setActionName:@"decrease quote level"];
    
    [self decreasingQuoteLevel:processingRange];
}
@end
