//
//  LITextView.m
//  LoremIpsum
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
#import "LIGradientOverlayVew.h"

#import "NSAttributedString+allAttributes.h"
#import <QuartzCore/QuartzCore.h>

#define UndoManager [[[[self window] windowController] document] undoManager]

@implementation LITextView
{
    @private
    CATextLayer *selectionOverlay;
    NSTimer *findBarDetectionTimer;
    
    BOOL mustBeMasked;
    
}
#pragma mark Subclassed Methods

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard type:(NSString *)type
{
    NSData *data;
    if ([type isEqualToString:NSHTMLPboardType]) {
        if (self.pasteHTML)
            data = [pboard dataForType:type];
        else
            data = [pboard dataForType:NSStringPboardType];
    }
    else if ([type isEqualToString:NSRTFDPboardType] || [type isEqualToString:NSRTFPboardType]) {
        
        id text = nil;
        
        if ([[[self.window.windowController document] docType] isEqualToString:TXT]) {
            data = [pboard dataForType:NSStringPboardType];
            if (!data)
                return NO;
            
            text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        
        else {
            data = [pboard dataForType:type];
            if (!data)
                return NO;
            NSDictionary *docAttributes = nil;
            NSError *error = nil;
            text = [[NSAttributedString alloc] initWithData:data options:nil documentAttributes:&docAttributes error:&error];
        }
        
        [self insertText:text];
        return  YES;
    }
    else
        data = [pboard dataForType:NSStringPboardType];
    
    if (!data)
        return NO;
    
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

- (BOOL)isPlainText
{
    return [[[[self.window windowController] document] docType] isEqualToString:TXT];
}

- (NSString*)bullet
{
    if ([self isPlainText])
        return @"* ";
    else {
        NSString *glyph = [NSString stringWithUTF8String:"\u2022"];
        return [NSString stringWithFormat:@"\t%@\t", glyph];
    }
}

- (BOOL)resignFirstResponder
{
    if ([self.window.windowController markdownPreview])
        return NO;
    return [super resignFirstResponder];
}

- (void)performFindPanelAction:(id)sender
{
    [super performFindPanelAction:sender];
    
    if ([sender tag] == 1 || [sender tag] == 12) {
        [[self.window.windowController gradientView] findActive:YES];
        if (!findBarDetectionTimer || !findBarDetectionTimer.isValid) {
            findBarDetectionTimer = [NSTimer scheduledTimerWithTimeInterval:.1f target:self selector:@selector(findPanelClosed) userInfo:nil repeats:YES];
        }
        if ([self.window.windowController masked]) {
            mustBeMasked = YES;
            [self.window.windowController setMasked:NO];
            [[self.window.windowController gradientView] removeFocus];
        }
    }
}

- (void)findPanelClosed
{
    if (![[self.window.windowController scrollContainer] isFindBarVisible]) {
        [findBarDetectionTimer invalidate];
        
        if (mustBeMasked) {
            mustBeMasked = NO;
            [self.window.windowController setMasked:YES];
        }
        
        [[self.window.windowController gradientView] findActive:NO];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem.action == @selector(pasteAsPlainText:)) {
        if ([[[self.window.windowController document] docType] isEqualToString:TXT]) {
            [menuItem setHidden:YES];
            return NO;
        }
        else {
            [menuItem setHidden:NO];
            return YES;
        }
    }
    
    return YES;
}

#pragma mark ---- KeyDown ----

- (void)keyDown:(NSEvent *)theEvent
{
    NSString *keyPressed = [theEvent charactersIgnoringModifiers];
    unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    
    if ([[[LISettingsProxy proxy] valueForSetting:@"useSmartPares"] boolValue])
        [self smartPairsPerform:keyPressed];
    
    if (key == 27)
        [self escapePerform];
    
    if (self.selectedRange.length == 0) {
        
        if ((key == 3 || key == 13) && [self isPlainText]) {
            [self enterPerform:theEvent];
            return;
        }
        else if ((key == 9)  && [self isPlainText]) {
            [self tabPerform:theEvent];
            return;
        }
        else {
            [super keyDown:theEvent];
            return;
        }
    }
    
    [super keyDown:theEvent];
}

#pragma mark KeyDown Performers

- (void)smartPairsPerform:(NSString*)keyPressed
{
    NSInteger currentPos = self.selectedRange.location;
    if (currentPos != NSNotFound) {
        
        NSCharacterSet *enteredSet = [NSCharacterSet characterSetWithCharactersInString:@"({[<'\""];
        unichar insertedCode = [keyPressed characterAtIndex:0];
        
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
                    if (self.string.length > 0 && self.selectedRange.location > 0 && self.selectedRange.location < self.string.length) {
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
                        if (hitRange.location <= self.textStorage.string.length) {
                            NSString *prevSymbol = [self.string substringWithRange:hitRange];
                            NSString *currentSymbol = [self.string substringWithRange:NSMakeRange(hitRange.location+1, 1)];
                            unichar prev = [prevSymbol characterAtIndex:0];
                            unichar curr = [currentSymbol characterAtIndex:0];
                            
                            if ((prev == 40 && curr == 41) || (prev == 91 && curr == 93) || (prev == 123 && curr == 125) || (prev == 60 && curr == 62) || (prev == 39 && curr == 39) || (prev == 34 && curr == 34))
                                [self insertText:@"" replacementRange:hitRange];
                        }
                    }
                    break;
                }
            }
        }
    }
}

- (void)escapePerform
{
    LIDocWindowController *controller = self.window.windowController;
    if ([controller.markdownPopover isShown] || [controller.textPopover isShown])
        [controller.showedPopover close];
}

- (void)enterPerform:(NSEvent*)theEvent
{
    NSRange paragraphRange = [self.textStorage.string paragraphRangeForRange:self.selectedRange];
    NSString *paragraphString = [self.textStorage.string substringWithRange:paragraphRange];
    NSString *leadingTabs = [self leadingTabs:paragraphString];
    NSString *validString = paragraphString;
    if (leadingTabs.length > 0)
        validString = [paragraphString stringByReplacingCharactersInRange:[paragraphString rangeOfString:leadingTabs] withString:@""];
    NSString *bullet = [self bullet];
    
    if ([validString hasPrefix:bullet]) {   // Имеем маркированный список
        if (![validString isEqualToString:bullet]) {    // есть непустая строка списка
            [super keyDown:theEvent];           // Переход на новую строку
            [self.textStorage beginEditing];
            [self.textStorage replaceCharactersInRange:self.selectedRange withString:[leadingTabs stringByAppendingString:bullet]];     // Вставляем марку с тем же отступом
            [self.textStorage endEditing];
            return;
        }
        else {
            if (leadingTabs.length > 0) {
                [self.textStorage beginEditing];
                [self.textStorage replaceCharactersInRange:paragraphRange withString:[NSString stringWithFormat:@"%@%@", [leadingTabs stringByReplacingCharactersInRange:NSMakeRange(leadingTabs.length-1, 1) withString:@""], bullet]];
                [self.textStorage endEditing];
                return;
            }
            else {
                [self.textStorage beginEditing];
                [self.textStorage replaceCharactersInRange:paragraphRange withString:@""];
                [self.textStorage endEditing];
                return;
            }
        }
    }
    
    else {  // Или нумерованный список, или строка
        
        NSError *error = nil;
        NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"^([0-9]*)\\.\\s" options:NSRegularExpressionCaseInsensitive error:&error];
        NSRange indexRange = [regexp rangeOfFirstMatchInString:validString options:0 range:NSMakeRange(0, validString.length)];
        
        if (!NSEqualRanges(indexRange, NSMakeRange(NSNotFound, 0))) {       // Нумерованный список
            NSString *indexString = [validString substringWithRange:indexRange];
            NSUInteger index = [[indexString substringToIndex:indexString.length - 2] integerValue];
            
            if (![validString isEqualToString:indexString]) { // В строке не только индекс]
                [super keyDown:theEvent];
                NSString *nextString = [NSString stringWithFormat:@"%ld. ", index+1];
                [self.textStorage beginEditing];
                [self.textStorage replaceCharactersInRange:self.selectedRange withString:[NSString stringWithFormat:@"%@%@", leadingTabs, nextString]];
                [self.textStorage endEditing];
                return;
            }
            else {  // В строке только индекс
                if (leadingTabs.length > 0) {   // Есть отступы - есть глубина списка
                    NSRange upperParagraphRange = [self.textStorage.string paragraphRangeForRange:NSMakeRange(paragraphRange.location-1, 1)];
                    NSUInteger upperLevelLastIndex = 0;
                    
                    if (upperParagraphRange.location != 0) {    // Определяем индекс последнего вышестоящего по глубине элемента
                        while (upperParagraphRange.location > 0) {
                            NSString *upperParagraphString = [self.textStorage.string substringWithRange:upperParagraphRange];
                            NSString *upperLeadingTabs = [self leadingTabs:upperParagraphString];
                            
                            if (upperLeadingTabs.length >= leadingTabs.length)
                                upperParagraphRange = [self.textStorage.string paragraphRangeForRange:NSMakeRange(upperParagraphRange.location-1, 1)];
                            else {
                                NSString *upperValidString = upperParagraphString;
                                if (upperLeadingTabs.length > 0)
                                    upperValidString = [upperParagraphString stringByReplacingCharactersInRange:[upperValidString rangeOfString:upperLeadingTabs] withString:@""];
                                NSRange upperIndexRange = [regexp rangeOfFirstMatchInString:upperValidString options:0 range:NSMakeRange(0, upperValidString.length)];
                                if (!NSEqualRanges(upperIndexRange, NSMakeRange(NSNotFound, 0))) {
                                    NSString *upperIndex = [upperValidString substringWithRange:upperIndexRange];
                                    upperLevelLastIndex = [upperIndex substringToIndex:upperIndex.length-2].integerValue;
                                    break;
                                }
                            }
                        }
                    }
                    
                    NSString *upString;
                    if (upperLevelLastIndex > 0)
                        upString = [NSString stringWithFormat:@"%@%ld. ", [leadingTabs stringByReplacingCharactersInRange:NSMakeRange(leadingTabs.length-1, 1) withString:@""], upperLevelLastIndex+1];
                    else
                        upString = [NSString stringWithFormat:@"%@1. ", [leadingTabs stringByReplacingCharactersInRange:NSMakeRange(leadingTabs.length-1, 1) withString:@""]];
                    
                    [self.textStorage beginEditing];
                    [self.textStorage replaceCharactersInRange:paragraphRange withString:upString];
                    [self.textStorage endEditing];
                    return;
                }
                
                else {  // Отступов нет - делаем элемент простой строкой
                    [self.textStorage beginEditing];
                    [self.textStorage replaceCharactersInRange:paragraphRange withString:@""];
                    [self.textStorage endEditing];
                    return;
                }
            }
        }
        
        else
            [super keyDown:theEvent];
    }
}

- (void)tabPerform:(NSEvent*)theEvent
{
    NSRange paragraphRange = [self.textStorage.string paragraphRangeForRange:self.selectedRange];
    NSString *paragraphString = [self.textStorage.string substringWithRange:paragraphRange];
    NSString *leadingTabs = [self leadingTabs:paragraphString];
    NSString *validString = paragraphString;
    if (leadingTabs.length > 0)
        validString = [paragraphString stringByReplacingCharactersInRange:[paragraphString rangeOfString:leadingTabs] withString:@""];
    NSString *bullet = [self bullet];
    
    NSString *upperLeadingTabs = @"";   // Отступ вышестоящей строки
    if (paragraphRange.location > 0) {
        NSRange upperRange = [self.textStorage.string paragraphRangeForRange:NSMakeRange(paragraphRange.location-1, 1)];
        NSString *upperString = [self.textStorage.string substringWithRange:upperRange];
        upperLeadingTabs = [self leadingTabs:upperString];
    }
    
    if (upperLeadingTabs.length >= leadingTabs.length) {
        
        if ([validString hasPrefix:bullet]) {       // Эелемент маркированного списка
            NSString *tabbedString = [NSString stringWithFormat:@"%@%@", [leadingTabs stringByAppendingString:@"\t"], validString];
            [self.textStorage beginEditing];
            [self.textStorage replaceCharactersInRange:paragraphRange withString:tabbedString];
            [self.textStorage endEditing];
            [self setSelectedRange:NSMakeRange(self.selectedRange.location-1, 0)];
            return;
        }
        else {      // нумерованный список или просто строка
            NSError *error = nil;
            NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"^([0-9]*)\\.\\s" options:NSRegularExpressionCaseInsensitive error:&error];
            NSRange indexRange = [regexp rangeOfFirstMatchInString:validString options:0 range:NSMakeRange(0, validString.length)];
            
            if (!NSEqualRanges(indexRange, NSMakeRange(NSNotFound, 0))) {   // Нумерованный список
                NSString *tabbedIndexString = [NSString stringWithFormat:@"%@1. \n", [leadingTabs stringByAppendingString:@"\t"]];
                [self.textStorage beginEditing];
                [self.textStorage replaceCharactersInRange:paragraphRange withString:tabbedIndexString];
                [self.textStorage endEditing];
                [self setSelectedRange:NSMakeRange(self.selectedRange.location-1, 0)];
                return;
            }
            else {
                [super keyDown:theEvent];
                return;
            }
        }
    }
    
    else {
        [super keyDown:theEvent];
        return;
    }
}

#pragma mark ---- List Handling ----
- (IBAction)markedListInsertion:(id)sender
{
    if ([self isPlainText]) {
        NSString *backup = [self.textStorage.string copy];
        [[[self undoManager] prepareWithInvocationTarget:self] mdHardcoreUndo:backup selectedRange:self.selectedRange];
        [[self undoManager] setActionName:@"insert marked list"];
        [self markdownMarkedInsertion];
    }
}

- (IBAction)numberedListInsertion:(id)sender
{
    if ([self isPlainText]) {
        NSString *backup = [self.textStorage.string copy];
        [[[self undoManager] prepareWithInvocationTarget:self] mdHardcoreUndo:backup selectedRange:self.selectedRange];
        [[self undoManager] setActionName:@"insert numbered list"];
        [self markdownNumberedInsertion];
    }
}

- (IBAction)listConversion:(id)sender
{
    NSString *backup = [self.textStorage.string copy];
    [[[self undoManager] prepareWithInvocationTarget:self] mdHardcoreUndo:backup selectedRange:self.selectedRange];
    [[self undoManager] setActionName:@"convert list"];
    
    NSRange selectedRange = self.selectedRange;
    NSRange extendedRange = [self.textStorage.string paragraphRangeForRange:selectedRange];
    NSDictionary *fixLastBreak = [self fixedLastBreak:extendedRange];
    NSString *activeSubstring = [fixLastBreak valueForKey:@"string"];
    extendedRange = [[fixLastBreak valueForKey:@"range"] rangeValue];
    
    NSRange rangetoKeep = selectedRange;
    
    NSArray *stringsToPerform = [self stringsToListFromString:activeSubstring];
    
    NSString *bullet = [self bullet];
    NSTextList *numList = [[NSTextList alloc] initWithMarkerFormat:@"{decimal}" options:0];
    
    NSError *error = nil;
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"^([0-9]*)\\.\\s" options:NSRegularExpressionCaseInsensitive error:&error];
    
    // Получаем тип списка по первой строке, от этого зависит тип конвертации
    NSString *firstString = [stringsToPerform objectAtIndex:0];
    NSString *fsLeadingTabs = [self leadingTabs:firstString];
    NSString *fsValidString = firstString;
    if (fsLeadingTabs.length > 0)
        fsValidString = [firstString stringByReplacingCharactersInRange:[firstString rangeOfString:fsLeadingTabs] withString:@""];
    
    BOOL toBullet = NO;
    if (![fsValidString hasPrefix:bullet])
        toBullet = YES;
    
    NSMutableArray *stringsToPlace = [NSMutableArray arrayWithCapacity:stringsToPerform.count];
    //NSUInteger insertedCount = 0;
    
    NSMutableDictionary *levelsNumbers = [[NSMutableDictionary alloc] init];
    
    for (NSString *string in stringsToPerform) {
        NSString *leadingTabs = [self leadingTabs:string];
        NSString *validString = string;
        if (leadingTabs.length > 0)
            validString = [string stringByReplacingCharactersInRange:[string rangeOfString:leadingTabs] withString:@""];
        
        if ([validString hasPrefix:bullet]) {   // Строка - элемент маркированного списка
            if (toBullet)     // Конвертация должна производиться в маркированный список
                [stringsToPlace insertObject:string atIndex:stringsToPlace.count];  // Просто добавляем строку в массив
            else {
                
                if ([stringsToPerform indexOfObject:string] > 0) {
                    NSUInteger prevIndex = [stringsToPerform indexOfObject:string]-1;
                    if ([self leadingTabs:[stringsToPerform objectAtIndex:prevIndex]].length < leadingTabs.length)
                        [levelsNumbers setValue:[NSNumber numberWithInteger:0] forKey:leadingTabs];
                }
                NSUInteger indexForCurrentString = [[levelsNumbers valueForKey:leadingTabs] integerValue];
                NSString *indexStr = [[numList markerForItemNumber:indexForCurrentString+1] stringByAppendingString:@". "];
                NSString *numberedString = [NSString stringWithFormat:@"%@%@%@", leadingTabs, indexStr, [validString stringByReplacingCharactersInRange:[validString rangeOfString:bullet] withString:@""]];
                [stringsToPlace insertObject:numberedString atIndex:stringsToPlace.count];
                [levelsNumbers setValue:[NSNumber numberWithInteger:indexForCurrentString+1] forKey:leadingTabs];
                
                if ([stringsToPerform indexOfObject:string] == 0)
                    rangetoKeep.location += indexStr.length - bullet.length;
                else
                    rangetoKeep.length += indexStr.length- bullet.length;
            }
        }
        
        else {      // Строка либо часть нумерованного списка, либо просто строка
            NSRange indexRange = [regexp rangeOfFirstMatchInString:validString options:0 range:NSMakeRange(0, validString.length)];
            if (toBullet) {     // Конвертация в маркированный список
                if (!NSEqualRanges(indexRange, NSMakeRange(NSNotFound, 0))) {     // Строка - элемент нумерованного списка
                    NSString *convertedToBulletString = [NSString stringWithFormat:@"%@%@", leadingTabs, [validString stringByReplacingCharactersInRange:indexRange withString:bullet]];
                    [stringsToPlace insertObject:convertedToBulletString atIndex:stringsToPlace.count];
                    
                    if ([stringsToPerform indexOfObject:string] == 0)
                        rangetoKeep.location += indexRange.length - bullet.length;
                    else
                        rangetoKeep.length += indexRange.length - bullet.length;
                }
                else {      // Простая строка
                    NSString *makeBulletString = [NSString stringWithFormat:@"%@%@", leadingTabs, [bullet stringByAppendingString:validString]];
                    [stringsToPlace insertObject:makeBulletString atIndex:stringsToPlace.count];
                    
                    if ([stringsToPerform indexOfObject:string] == 0)
                        rangetoKeep.location += bullet.length;
                    else
                        rangetoKeep.length += bullet.length;
                }
            }
            else {      // Конвертация в нумерованный список
                if (!NSEqualRanges(indexRange, NSMakeRange(NSNotFound, 0)))     // Строка с индексом
                    [stringsToPlace insertObject:string atIndex:stringsToPlace.count];  // Просто добавляем в массив
                else {
                    NSRange bulletRange = [validString rangeOfString:bullet];
                    
                    if ([stringsToPerform indexOfObject:string] > 0) {
                        NSUInteger prevIndex = [stringsToPerform indexOfObject:string]-1;
                        if ([self leadingTabs:[stringsToPerform objectAtIndex:prevIndex]].length < leadingTabs.length)
                            [levelsNumbers setValue:[NSNumber numberWithInteger:0] forKey:leadingTabs];
                    }
                    NSUInteger indexForCurrentString = [[levelsNumbers valueForKey:leadingTabs] integerValue];
                    NSString *indexStr = [[numList markerForItemNumber:indexForCurrentString+1] stringByAppendingString:@". "];
                    if (!NSEqualRanges(bulletRange, NSMakeRange(NSNotFound, 0))) {
                        NSString *numberedString = [NSString stringWithFormat:@"%@%@%@", leadingTabs, indexStr, [validString stringByReplacingCharactersInRange:bulletRange withString:@""]];
                        [stringsToPlace insertObject:numberedString atIndex:stringsToPlace.count];
                        [levelsNumbers setValue:[NSNumber numberWithInteger:indexForCurrentString+1] forKey:leadingTabs];
                        
                        if ([stringsToPerform indexOfObject:string] == 0)
                            rangetoKeep.location += indexStr.length - bullet.length;
                        else
                            rangetoKeep.length += indexStr.length - bullet.length;
                    }
                    else {
                        NSString *numberedString = [NSString stringWithFormat:@"%@%@", leadingTabs, [indexStr stringByAppendingString:validString]];
                        [stringsToPlace insertObject:numberedString atIndex:stringsToPlace.count];
                        [levelsNumbers setValue:[NSNumber numberWithInteger:indexForCurrentString+1] forKey:leadingTabs];
                        
                        if ([stringsToPerform indexOfObject:string] == 0)
                            rangetoKeep.location += indexStr.length;
                        else
                            rangetoKeep.length += indexStr.length;
                    }
                }
            }
        }
    }
    
    NSString *resultString = [stringsToPlace componentsJoinedByString:@"\n"];
    
    [self.textStorage beginEditing];
    [self.textStorage replaceCharactersInRange:extendedRange withString:resultString];
    [self.textStorage endEditing];

    [self setSelectedRange:rangetoKeep];
}

- (void)markdownMarkedInsertion
{
    NSString *bullet = [self bullet];
    NSRange selectedRange = self.selectedRange;
    NSRange extendedRange = [self.textStorage.string paragraphRangeForRange:selectedRange];
    NSDictionary *fixLastBreak = [self fixedLastBreak:extendedRange];
    NSString *activeSubstring = [fixLastBreak valueForKey:@"string"];
    extendedRange = [[fixLastBreak valueForKey:@"range"] rangeValue];
    
    NSRange rangetoKeep = selectedRange;
    
    NSArray *stringsToPerform = [self stringsToListFromString:activeSubstring];
    
    NSMutableArray *stringsToPlace = [[NSMutableArray alloc] initWithCapacity:stringsToPerform.count];
    BOOL deleteList = [self listDeletion:stringsToPerform];
    
    for (NSString *string in stringsToPerform) {
        
        NSString *leadingTabs = [self leadingTabs:string];
        NSString *validString = string;
        if (leadingTabs.length > 0)
            validString = [string stringByReplacingCharactersInRange:[string rangeOfString:leadingTabs] withString:@""];
        NSError *error = nil;
        NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"^([0-9]*)\\.\\s" options:NSRegularExpressionCaseInsensitive error:&error];
        NSRange indexRange = [regexp rangeOfFirstMatchInString:validString options:0 range:NSMakeRange(0, validString.length)];
        
        if (!deleteList) {  //Вставляем список
            if (![validString hasPrefix:bullet]) {        // Нету марки
                if (!NSEqualRanges(indexRange, NSMakeRange(NSNotFound, 0)))    // Если есть индекс (строка - элемент нумерованного списка) - не трогаем
                    [stringsToPlace insertObject:[NSString stringWithFormat:@"%@%@", leadingTabs, validString] atIndex:stringsToPlace.count];
                else {
                    NSString *listItemString = [NSString stringWithFormat:@"%@%@%@", leadingTabs, bullet, validString];
                    [stringsToPlace insertObject:listItemString atIndex:stringsToPlace.count];
                    
                    if ([stringsToPerform indexOfObject:string] == 0)
                        rangetoKeep.location += bullet.length;
                    else
                        rangetoKeep.length += bullet.length;
                }
            }
            else    // есть марка - оставляем строку нетронутой
                [stringsToPlace insertObject:string atIndex:stringsToPlace.count];
        }
        else {  // Удаление списка
            if (!NSEqualRanges(indexRange, NSMakeRange(NSNotFound, 0))) {
                NSString *stringWOIndex = [NSString stringWithFormat:@"%@%@", leadingTabs, [validString stringByReplacingCharactersInRange:indexRange withString:@""]];
                [stringsToPlace insertObject:stringWOIndex atIndex:stringsToPlace.count];
                
                if ([stringsToPerform indexOfObject:string] == 0)
                    rangetoKeep.location -= indexRange.length;
                else
                    rangetoKeep.length -= indexRange.length;
            }
            else {
                NSString *nonListString = [NSString stringWithFormat:@"%@%@", leadingTabs, [validString stringByReplacingCharactersInRange:[validString rangeOfString:bullet] withString:@""]];
                [stringsToPlace insertObject:nonListString atIndex:stringsToPlace.count];
                
                if ([stringsToPerform indexOfObject:string] == 0)
                    rangetoKeep.location -= bullet.length;
                else
                    rangetoKeep.length -= bullet.length;
            }
        }
    }
    NSString *listString = [stringsToPlace componentsJoinedByString:@"\n"];
    
    [self.textStorage beginEditing];
    [self.textStorage replaceCharactersInRange:extendedRange withString:listString];
    [self.textStorage endEditing];
    
    [self setSelectedRange:rangetoKeep];
}

- (void)markdownNumberedInsertion
{
    NSRange selectedRange = self.selectedRange;
    NSRange extendedRange = [self.textStorage.string paragraphRangeForRange:selectedRange];
    NSDictionary *fixLastBreak = [self fixedLastBreak:extendedRange];
    NSString *activeSubstring = [fixLastBreak valueForKey:@"string"];
    extendedRange = [[fixLastBreak valueForKey:@"range"] rangeValue];
    
    NSRange rangetoKeep = selectedRange;
    
    NSArray *stringsToPerform = [self stringsToListFromString:activeSubstring];
    NSMutableArray *stringsToPlace = [[NSMutableArray alloc] initWithCapacity:stringsToPerform.count];
    BOOL deleteList = [self listDeletion:stringsToPerform];
    
    NSTextList *numList = [[NSTextList alloc] initWithMarkerFormat:@"{decimal}" options:0];
    NSString *bullet = [self bullet];
    
    NSMutableDictionary *levelsNumbers = [[NSMutableDictionary alloc] init];
    
    for (NSString *string in stringsToPerform) {
        NSString *leadingTabs = [self leadingTabs:string];
        NSString *validString = string;
        if (leadingTabs.length > 0)
            validString = [string stringByReplacingCharactersInRange:[string rangeOfString:leadingTabs] withString:@""];
        NSError *error = nil;
        NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"^([0-9]*)\\.\\s" options:NSRegularExpressionCaseInsensitive error:&error];
        NSRange indexRange = [regexp rangeOfFirstMatchInString:validString options:0 range:NSMakeRange(0, validString.length)];
        
        if (!deleteList) {  // Вставка нумерованного списка
            if (NSEqualRanges(indexRange, NSMakeRange(NSNotFound, 0))) {    // Нет индекса
                if ([validString hasPrefix:bullet])     // Есть марка (строка - элемент маркирванного списка)
                    [stringsToPlace insertObject:string atIndex:stringsToPlace.count];  // Не трогаем
                else {
                    
                    if ([stringsToPerform indexOfObject:string] > 0) {
                        NSUInteger prevIndex = [stringsToPerform indexOfObject:string]-1;
                        if ([self leadingTabs:[stringsToPerform objectAtIndex:prevIndex]].length < leadingTabs.length)
                            [levelsNumbers setValue:[NSNumber numberWithInteger:0] forKey:leadingTabs];
                    }
                    
                    NSUInteger indexForCurrentString = [[levelsNumbers valueForKey:leadingTabs] integerValue];
                    NSString *indexStr = [[numList markerForItemNumber:indexForCurrentString+1] stringByAppendingString:@". "];
                    NSString *numberedString = [NSString stringWithFormat:@"%@%@%@", leadingTabs, indexStr, validString];
                    [stringsToPlace insertObject:numberedString atIndex:stringsToPlace.count];
                    [levelsNumbers setValue:[NSNumber numberWithInteger:indexForCurrentString+1] forKey:leadingTabs];
                    
                    if ([stringsToPerform indexOfObject:string] == 0)
                        rangetoKeep.location += indexStr.length;
                    else
                        rangetoKeep.length += indexStr.length;
                }
            }
            else    // Есть индекс - строку не трогаем
                [stringsToPlace insertObject:string atIndex:stringsToPlace.count];
        }
        
        else {  // Удаление списка
            if (!NSEqualRanges(indexRange, NSMakeRange(NSNotFound, 0))) {   // Строка с индексом - индекс удаляем
                NSString *nonNumListItemString = [NSString stringWithFormat:@"%@%@", leadingTabs, [validString stringByReplacingCharactersInRange:indexRange withString:@""]];
                [stringsToPlace insertObject:nonNumListItemString atIndex:stringsToPlace.count];
                
                if ([stringsToPerform indexOfObject:string] == 0)
                    rangetoKeep.location -= indexRange.length;
                else
                    rangetoKeep.length -= indexRange.length;
            }
            else if ([validString hasPrefix:bullet]) {
                NSString *strWOBullet = [NSString stringWithFormat:@"%@%@", leadingTabs, [validString stringByReplacingCharactersInRange:[validString rangeOfString:bullet] withString:@""]];
                [stringsToPlace insertObject:strWOBullet atIndex:stringsToPlace.count];
                
                if ([stringsToPerform indexOfObject:string] == 0)
                    rangetoKeep.location -= bullet.length;
                else
                    rangetoKeep.length -= bullet.length;
            }
            else
                [stringsToPlace insertObject:string atIndex:stringsToPlace.count];
        }
    }
    
    NSString *numListString = [stringsToPlace componentsJoinedByString:@"\n"];
    
    [self.textStorage beginEditing];
    [self.textStorage replaceCharactersInRange:extendedRange withString:numListString];
    [self.textStorage endEditing];
    
    [self setSelectedRange:rangetoKeep];
}

- (NSDictionary*)fixedLastBreak:(NSRange)extRange
{
    NSString *activeSubstring = [self.textStorage.string substringWithRange:extRange];
    
    NSString *suffix = nil;
    if ([activeSubstring hasSuffix:@"\n"])
        suffix = @"\n";
    else if ([activeSubstring hasSuffix:@"\r"])
        suffix = @"\r";
    else if ([activeSubstring hasSuffix:@"\r\n"])
        suffix = @"\r\n";
    if (suffix)
        activeSubstring = [activeSubstring stringByReplacingCharactersInRange:NSMakeRange(activeSubstring.length-suffix.length, suffix.length) withString:@""];
    extRange.length -= suffix.length;
    NSDictionary *result = @{ @"range":[NSValue valueWithRange:extRange] , @"string":activeSubstring };
    return result;
}

- (NSArray*)stringsToListFromString:(NSString*)activeString
{
    NSArray *strings = [activeString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return strings;
}

- (BOOL)listDeletion:(NSArray*)listStrings
{
    NSString *bullet = [self bullet];
    
    NSUInteger marksCount = 0;
    
    if ([self isPlainText]) {
        for (NSString *string in listStrings) {
            
            NSString *leadingTabs = [self leadingTabs:string];
            NSString *validString = string;
            if (leadingTabs.length > 0)
                validString = [string stringByReplacingCharactersInRange:[string rangeOfString:leadingTabs] withString:@""];
            
            NSError *error = nil;
            NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"^([0-9]*)\\.\\s" options:NSRegularExpressionCaseInsensitive error:&error];
            NSRange indexRange = [regexp rangeOfFirstMatchInString:validString options:0 range:NSMakeRange(0, validString.length)];
            
            if ([validString hasPrefix:bullet] || indexRange.location != NSNotFound)
                marksCount++;
        }
    }
    
    else {
        NSRange selectedRange = self.selectedRange;
        NSRange extendedRange = [self.textStorage.string paragraphRangeForRange:selectedRange];
        NSDictionary *fixLastBreak = [self fixedLastBreak:extendedRange];
        NSString *activeSubstring = [fixLastBreak valueForKey:@"string"];
        extendedRange = [[fixLastBreak valueForKey:@"range"] rangeValue];
        
        for (NSString *string in listStrings) {
            NSString *leadingTabs = [self leadingTabs:string];
            NSString *validString = string;
            if (leadingTabs.length > 0)
                validString = [string stringByReplacingCharactersInRange:[string rangeOfString:leadingTabs] withString:@""];
            
            NSDictionary *stringAttributes = [self attributesAtRange:NSMakeRange(extendedRange.location + [activeSubstring rangeOfString:string].location, string.length)]; // Атрибуты строки
            NSMutableParagraphStyle *style = [[stringAttributes valueForKey:NSParagraphStyleAttributeName] mutableCopy];
            
            if ((style.textLists.count != 0) && ([[(NSTextList*)[style.textLists objectAtIndex:0] markerFormat] isEqualToString:@"{disc}"] || [[(NSTextList*)[style.textLists objectAtIndex:0] markerFormat] isEqualToString:@"{decimal}"]))
                marksCount++;
        }
    }
    
    return marksCount == listStrings.count;
}

- (NSString*)leadingTabs:(NSString*)string
{
    NSString *tabs = [NSString string];
    NSUInteger count = 0;
    if ([string hasPrefix:@"\t"]) {
        for (int i = 0; i < string.length; i++) {
            if ([[string substringWithRange:NSMakeRange(i, 1)] isEqualToString:@"\t"])
                count++;
            else
                break;
        }
    }
    
    if (count > 0) {
        tabs = [string substringWithRange:NSMakeRange(0, count)];
    }
    return tabs;
}

#pragma mark ---- Coordinates & rects handling ----

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
    NSRect layoutRect;
    
    NSRect lRect = [[self layoutManager] boundingRectForGlyphRange:theTextRange inTextContainer:[self textContainer]];
    
    layoutRect = [self firstRectForCharacterRange:theTextRange];
    CGFloat layoutRectHeight = layoutRect.size.height;
    
    layoutRect.size.height = lRect.size.height;
    layoutRect.origin.y -= lRect.size.height - layoutRectHeight;
    
    NSRect txtViewBounds = [self convertRectToBacking:[self bounds]];
    txtViewBounds = [self.window convertRectToScreen:txtViewBounds];
    
    layoutRect = [[self superview] convertRect:layoutRect toView:nil];
    layoutRect = [self.window convertRectToScreen:layoutRect];
    
    return layoutRect;
}

#pragma mark ---- Style & Attributes Handling ----

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

#pragma mark ---- Font Handling ----

- (NSFont *)currentFont
{
    NSRange effectiveRange;
    NSRange usefulRange = [self selectedRange];
    if (usefulRange.location == [[self textStorage] length])
        usefulRange.location = usefulRange.location-1;
    return [[self textStorage] attribute:NSFontAttributeName atIndex:usefulRange.location effectiveRange:&effectiveRange];
}

#pragma mark ---- Attachments handling ----
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

#pragma mark Indentation
- (IBAction)listLevelIncreasing:(id)sender
{
    NSRange processingRange = [self selectedRange];
    NSString *backup = [self.textStorage.string copy];
    [[self.undoManager prepareWithInvocationTarget:self] mdHardcoreUndo:backup selectedRange:processingRange];
    if ([[sender title] isEqualToString:@"Increase list level"])
        [[self undoManager] setActionName:@"increase list level"];
    else
        [[self undoManager] setActionName:@"increase paragraph indentation"];
    
    [self increasingIndentation:processingRange];
}

- (IBAction)listLevelDecreasing:(id)sender
{
    NSRange processingRange = [self selectedRange];
    NSString *backup = [self.textStorage.string copy];
    [[[self undoManager] prepareWithInvocationTarget:self] mdHardcoreUndo:backup selectedRange:processingRange];
    if ([[sender title] isEqualToString:@"Decrease list level"])
        [[self undoManager] setActionName:@"decrease list level"];
    else
        [[self undoManager] setActionName:@"decrease paragraph indentation"];
    
    [self decreasingIndentation:processingRange];
}

- (IBAction)increaseQuoteLevel:(id)sender
{
    NSRange processingRange = [self selectedRange];
    NSString *backup = [self.textStorage.string copy];
    [[[self undoManager] prepareWithInvocationTarget:self] mdHardcoreUndo:backup selectedRange:processingRange];
    [[self undoManager] setActionName:@"increase quote level"];
    
    [self increasingQuoteLevel:processingRange];
}

- (IBAction)decreaseQuoteLevel:(id)sender
{
    NSRange processingRange = [self selectedRange];
    NSString *backup = [self.textStorage.string copy];
    [[[self undoManager] prepareWithInvocationTarget:self] mdHardcoreUndo:backup selectedRange:processingRange];
    [[self undoManager] setActionName:@"decrease quote level"];
    
    [self decreasingQuoteLevel:processingRange];
}

- (void)increasingIndentation:(NSRange)range
{
    NSRange extendedRange = [self.textStorage.string paragraphRangeForRange:range];
    NSDictionary *fixLastBreak = [self fixedLastBreak:extendedRange];
    NSString *activeSubstring = [fixLastBreak valueForKey:@"string"];
    extendedRange = [[fixLastBreak valueForKey:@"range"] rangeValue];
    NSArray *stringsToPerform = [self stringsToListFromString:activeSubstring];
    
    NSRange rangeToKeep = range;
    
    NSMutableArray *stringsToPlace = [NSMutableArray arrayWithCapacity:stringsToPerform.count];
    
    for (NSString *string in stringsToPerform) {
        NSString *leadingTabs = [[self leadingTabs:string] mutableCopy];
        NSString *validString = string;
        if (leadingTabs.length > 0)
            validString = [string stringByReplacingCharactersInRange:[string rangeOfString:leadingTabs] withString:@""];
        
        NSUInteger neededTabs = leadingTabs.length + 1;
        leadingTabs = [NSString string];
        for (int i = 0; i < neededTabs; i++)
            leadingTabs = [leadingTabs stringByAppendingString:@"\t"];
        
        NSString *incresingIndentStr = [NSString stringWithFormat:@"%@%@", leadingTabs, validString];
        [stringsToPlace insertObject:incresingIndentStr atIndex:stringsToPlace.count];
        
        if ([stringsToPerform indexOfObject:string] == 0)
            rangeToKeep.location += 1;
        else
            rangeToKeep.length += 1;
    }
    
    NSString *resultString = [stringsToPlace componentsJoinedByString:@"\n"];
    
    [self.textStorage beginEditing];
    [self.textStorage replaceCharactersInRange:extendedRange withString:resultString];
    [self.textStorage endEditing];
    
    [self setSelectedRange:rangeToKeep];
}

- (void)decreasingIndentation:(NSRange)range
{
    NSRange extendedRange = [self.textStorage.string paragraphRangeForRange:range];
    NSDictionary *fixLastBreak = [self fixedLastBreak:extendedRange];
    NSString *activeSubstring = [fixLastBreak valueForKey:@"string"];
    extendedRange = [[fixLastBreak valueForKey:@"range"] rangeValue];
    NSArray *stringsToPerform = [self stringsToListFromString:activeSubstring];
    
    NSRange rangeToKeep = range;
    
    NSMutableArray *stringsToPlace = [NSMutableArray arrayWithCapacity:stringsToPerform.count];
    
    for (NSString *string in stringsToPerform) {
        NSString *leadingTabs = [[self leadingTabs:string] mutableCopy];
        NSString *validString = string;
        if (leadingTabs.length > 0)
            validString = [string stringByReplacingCharactersInRange:[string rangeOfString:leadingTabs] withString:@""];
        
        if (leadingTabs.length > 0) {
            if ([stringsToPerform indexOfObject:string] == 0) {
                rangeToKeep.location -= 1;
            }
            else
                rangeToKeep.length -= 1;
        }
        
        NSInteger neededTabs = leadingTabs.length - 1;
        leadingTabs = [NSString string];
        if (neededTabs > 0)
            for (int i = 0; i < neededTabs; i++)
                leadingTabs = [leadingTabs stringByAppendingString:@"\t"];
        NSString *decresingIndentStr = [NSString stringWithFormat:@"%@%@", leadingTabs, validString];
        [stringsToPlace insertObject:decresingIndentStr atIndex:stringsToPlace.count];
    }
    
    NSString *resultString = [stringsToPlace componentsJoinedByString:@"\n"];
    
    [self.textStorage beginEditing];
    [self.textStorage replaceCharactersInRange:extendedRange withString:resultString];
    [self.textStorage endEditing];
    
    [self setSelectedRange:rangeToKeep];
}

- (void)increasingQuoteLevel:(NSRange)range
{
    NSRange extendedRange = [self.textStorage.string paragraphRangeForRange:range];
    NSDictionary *fixLastBreak = [self fixedLastBreak:extendedRange];
    NSString *activeSubstring = [fixLastBreak valueForKey:@"string"];
    extendedRange = [[fixLastBreak valueForKey:@"range"] rangeValue];
    NSArray *stringsToPerform = [self stringsToListFromString:activeSubstring];
    
    NSRange rangeToKeep = range;
    
    NSMutableArray *stringsToPlace = [NSMutableArray arrayWithCapacity:stringsToPerform.count];
    
    for (NSString *string in stringsToPerform) {
        NSString *leadingTabs = [[self leadingTabs:string] mutableCopy];
        NSString *validString = string;
        if (leadingTabs.length > 0)
            validString = [string stringByReplacingCharactersInRange:[string rangeOfString:leadingTabs] withString:@""];
        
        NSString *quoter = @">";
        if (![validString hasPrefix:quoter])
            quoter = @"> ";
        
        NSString *increasedQuote = [NSString stringWithFormat:@"%@%@%@", leadingTabs, quoter, validString];
        [stringsToPlace insertObject:increasedQuote atIndex:stringsToPlace.count];
        
        if ([stringsToPerform indexOfObject:string] == 0)
            rangeToKeep.location += quoter.length;
        else
            rangeToKeep.length += quoter.length;
    }
    NSString *resultString = [stringsToPlace componentsJoinedByString:@"\n"];
    
    [self.textStorage beginEditing];
    [self.textStorage replaceCharactersInRange:extendedRange withString:resultString];
    [self.textStorage endEditing];
    
    [self setSelectedRange:rangeToKeep];
}

- (void)decreasingQuoteLevel:(NSRange)range
{
    NSRange extendedRange = [self.textStorage.string paragraphRangeForRange:range];
    NSDictionary *fixLastBreak = [self fixedLastBreak:extendedRange];
    NSString *activeSubstring = [fixLastBreak valueForKey:@"string"];
    extendedRange = [[fixLastBreak valueForKey:@"range"] rangeValue];
    NSArray *stringsToPerform = [self stringsToListFromString:activeSubstring];
    
    NSRange rangeToKeep = range;
    
    NSMutableArray *stringsToPlace = [NSMutableArray arrayWithCapacity:stringsToPerform.count];
    
    for (NSString *string in stringsToPerform) {
        NSString *leadingTabs = [[self leadingTabs:string] mutableCopy];
        NSString *validString = string;
        if (leadingTabs.length > 0)
            validString = [string stringByReplacingCharactersInRange:[string rangeOfString:leadingTabs] withString:@""];
        NSString *quoter = @">";
        if ([validString hasPrefix:@"> "]) {
            NSString *lastQuote = [NSString stringWithFormat:@"%@%@", leadingTabs, [validString stringByReplacingCharactersInRange:[validString rangeOfString:@"> "] withString:@""]];
            [stringsToPlace insertObject:lastQuote atIndex:stringsToPlace.count];
            
            if ([stringsToPerform indexOfObject:string] == 0)
                rangeToKeep.location -= 2;
            else
                rangeToKeep.length -= 2;
        }
        else if ([validString hasPrefix:quoter]) {
            NSString *minusQuote = [NSString stringWithFormat:@"%@%@", leadingTabs, [validString stringByReplacingCharactersInRange:[validString rangeOfString:quoter] withString:@""]];
            [stringsToPlace insertObject:minusQuote atIndex:stringsToPlace.count];
            
            if ([stringsToPerform indexOfObject:string] == 0)
                rangeToKeep.location -= quoter.length;
            else
                rangeToKeep.length -= quoter.length;
        }
        else
            [stringsToPlace insertObject:string atIndex:stringsToPlace.count];
    }
    
    NSString *resultString = [stringsToPlace componentsJoinedByString:@"\n"];
    
    [self.textStorage beginEditing];
    [self.textStorage replaceCharactersInRange:extendedRange withString:resultString];
    [self.textStorage endEditing];
    
    [self setSelectedRange:rangeToKeep];
}

#pragma mark ---- Undo ----
- (void)mdHardcoreUndo:(NSString*)string selectedRange:(NSRange)range
{
    [self setString:string];
    [self setSelectedRange:range];
}
@end