//
//  TADocument.m
//  TextArtist
//
//  Created by Akki on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LIDocument.h"
#import "LIDocWindowController.h"
#import "LITextView.h"
#import "LIDocumentCOntroller.h"
#import "LITextAttachmentCell.h"
#import "ESSImageCategory.h"
#import "LISettingsProxy.h"


#define WindowController [[self windowControllers] lastObject]
static NSString *plainTextBookmarkMarker = @"<!-- LoremIpsum:Bookmark -->";

@implementation LIDocument
{
    LISettingsProxy *settingsProxy;
}
@synthesize textStorage = _textStorage;
@synthesize docType;
@synthesize typingAttribs;

- (id)init
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        _textStorage = [[NSTextStorage alloc] init];
        settingsProxy = [LISettingsProxy proxy];
        
        // Исходные настройки приложения
        NSMutableDictionary *initialSettings;

        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"LIInitSettings"] == nil) {
            initialSettings = [[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LIInitSettings" ofType:@"plist"]];
            [[NSUserDefaults standardUserDefaults] setObject:initialSettings forKey:@"LIInitSettings"];
        } else
            initialSettings = [[NSUserDefaults standardUserDefaults] objectForKey:@"LIInitSettings"];
        
        [settingsProxy setSettings:initialSettings];
        //[SharedDefaultsController setInitialValues:initialSettings];
        
        [self setTypingAttribs:[NSDictionary dictionaryWithObjectsAndKeys:[self docFont:[initialSettings valueForKey:@"docFont"]], NSFontAttributeName, [NSColor colorWithHex:[initialSettings valueForKey:@"textColor"]], NSForegroundColorAttributeName, nil]];
        
        if ([[self fileType] compare:(NSString*)kUTTypePlainText] == NSOrderedSame)
            [self setDocType:TXT];
        else
            [self setDocType:RTF];
        
        [self addObserver:self forKeyPath:@"fileType" options:NSKeyValueObservingOptionNew context:NULL];
    }

    return self;
}

- (void)makeWindowControllers
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    if ([[self windowControllers] count] == 0) {
        LIDocWindowController *controller = [[LIDocWindowController alloc] initWithWindowNibName:@"LIDocWindowController"];
        [self addWindowController:controller];
    }
}

- (void)makeWindowControllersManual:(BOOL)manual
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    if (!manual)
        [self makeWindowControllers];
    else {
        if ([[self windowControllers] count] == 0) {
            if ([[[NSApp mainWindow] windowController] isMemberOfClass:[LIDocWindowController class]] && [[[NSApp mainWindow] windowController] document] == nil)
                [self addWindowController:[[NSApp mainWindow] windowController]];
        }
    }
}

+ (BOOL)autosavesInPlace
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    return YES;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{    //NSLog(@"%s", __PRETTY_FUNCTION__);
    NSTextStorage *aStorage;
    
    if ([fileWrapper isRegularFile] && ([typeName compare:@"public.rtf"] == NSOrderedSame)) {
        [self setDocType:RTF];
        aStorage = [[NSTextStorage alloc] initWithRTF:[fileWrapper regularFileContents] documentAttributes:nil];
    } else if ([typeName compare:@"com.apple.rtfd"] == NSOrderedSame) {
        [self setDocType:RTF];
        aStorage = [[NSTextStorage alloc] initWithRTFD:[fileWrapper serializedRepresentation] documentAttributes:nil];
    } else if ([fileWrapper isRegularFile]) {
        [self setDocType:TXT];
        NSString *contentString = [[NSString alloc] initWithData:[fileWrapper regularFileContents] encoding:NSUTF8StringEncoding];
        NSAttributedString *strToSet = [[NSAttributedString alloc] initWithString:contentString attributes:self.typingAttribs];
        aStorage = [[NSTextStorage alloc] initWithAttributedString:strToSet];
    }
    
    if (!aStorage) {
        if (outError)
            *outError = [[NSError alloc] initWithDomain:@"my.ErrrorDomain" code:60 userInfo:NULL];
        return NO;
    } else {
        [self parseTextOfType:typeName forBookmarks:aStorage];
        [_textStorage setAttributedString:aStorage];
        return YES;
    }
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    NSRange documentRange = NSMakeRange(0, [[[WindowController aTextView] textStorage] length]);
    NSMutableAttributedString *maString = [[[WindowController aTextView] attributedString] mutableCopy];
    [maString addAttributes:@{ NSBackgroundColorAttributeName : [NSColor whiteColor] , NSForegroundColorAttributeName : [NSColor blackColor] } range:documentRange];
    NSTextStorage *text = [[NSTextStorage alloc] initWithAttributedString:maString];
    //NSTextStorage *text = [[[WindowController aTextView] textStorage] copy];
    
    NSFileWrapper *resultWrapper = nil;
    if ([typeName compare:@"public.rtf"] == NSOrderedSame) {
        resultWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[text RTFFromRange:documentRange documentAttributes:[NSDictionary dictionaryWithObjectsAndKeys:NSRTFTextDocumentType, NSDocumentTypeDocumentAttribute, nil]]];
    }
    else if ([typeName compare:@"com.apple.rtfd"] == NSOrderedSame) {
        resultWrapper = [text RTFDFileWrapperFromRange:documentRange documentAttributes:[NSDictionary dictionaryWithObjectsAndKeys:NSRTFDTextDocumentType, NSDocumentTypeDocumentAttribute, nil]];
    }
    
    else {
        if ([text containsAttachments]) {
            NSUInteger location = 0, end = [text length];
            while (location < end) {	// Run through the string in terms of attachment runs 
                NSRange attachmentRange;	// Attachment attribute run 
                NSTextAttachment *attachment = [text attribute:NSAttachmentAttributeName atIndex:location longestEffectiveRange:&attachmentRange inRange:NSMakeRange(location, end-location)];
                if (attachment) {	// If there is an attachment and it is on an attachment character, replace with marker
                    if ([[(LITextAttachmentCell*)[attachment attachmentCell] identifier] isEqualToString:@"bookmark"]) {
                        [text beginEditing];
                        unichar ch = [[text string] characterAtIndex:location];
                        if (ch == NSAttachmentCharacter)
                            [text replaceCharactersInRange:NSMakeRange(location, 1) withString:plainTextBookmarkMarker];
                        end = [text length];	// New length 
                        [text endEditing];
                    }
                    else location++;	// Just skip over the current character... 
                }
                else location = NSMaxRange(attachmentRange);
            }
         }
        
        NSString *txtString = [text string];
        NSTextStorage *aTextStorage = [[NSTextStorage alloc] initWithString:txtString];
        
        NSDictionary *fileAttrs = [[NSDictionary alloc] initWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:NSPlainTextDocumentType, NSDocumentTypeDocumentAttribute, [NSNumber numberWithUnsignedInteger:NSUTF8StringEncoding], NSCharacterEncodingDocumentAttribute, nil]];
        NSRange aRange = NSMakeRange(0, [[aTextStorage string] length]);
        resultWrapper = [aTextStorage fileWrapperFromRange:aRange documentAttributes:fileAttrs error:outError];
        
        if (!resultWrapper)
            return nil;
    }
    
    return resultWrapper;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{//NSLog(@"%s", __PRETTY_FUNCTION__);
    NSString *fileType = [change valueForKey:@"new"];
    [fileType isEqualToString:@"public.plain-text"] ? [self setDocType:TXT] : [self setDocType:RTF];
}

- (NSView *)printableView
{
    NSRect frame = [[self printInfo] imageablePageBounds];
    frame.size.height = 0;
	NSTextView *printView = [[NSTextView alloc] initWithFrame:frame];
    [printView setVerticallyResizable:YES];
    [printView setHorizontallyResizable:NO];
	
	// force black text color
	NSMutableAttributedString *printStr = [[[[WindowController aTextView] textStorage] attributedSubstringFromRange:NSMakeRange(0, [[[WindowController aTextView] textStorage] length])] mutableCopy];
	NSDictionary *printAttr = [NSDictionary dictionaryWithObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	[printStr setAttributes:printAttr range:NSMakeRange(0, [printStr length])];
	
    [[printView textStorage] beginEditing];
    [[printView textStorage] appendAttributedString:printStr];
    [[printView textStorage] endEditing];
    
    [printView sizeToFit];
    
    return printView;
}

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError *__autoreleasing *)outError
{
    return [NSPrintOperation printOperationWithView:[self printableView] printInfo:[self printInfo]];
}

- (NSPrintInfo *)printInfo
{
    NSPrintInfo *printInfo = [super printInfo];
    [printInfo setHorizontalPagination:NSFitPagination];
	[printInfo setHorizontallyCentered:NO];
	[printInfo setVerticallyCentered:NO];
	[printInfo setLeftMargin:72.0];
	[printInfo setRightMargin:72.0];
	[printInfo setTopMargin:72.0];
	[printInfo setBottomMargin:72.0];
    return printInfo;
}

- (NSFont *)textFont
{    
    //NSString *fontName = [[SharedDefaultsController valueForKeyPath:@"values.docFont"] valueForKey:@"fontName"];
    //CGFloat fontSize = [[[SharedDefaultsController valueForKeyPath:@"values.docFont"] valueForKey:@"fontSize"] floatValue];
    NSString *fontName = [[settingsProxy valueForSetting:@"docFont"] valueForKey:@"fontName"];
    CGFloat fontSize = [[[settingsProxy valueForSetting:@"docFont"] valueForKey:@"fontSize"] floatValue];
    NSFont *aFont = [NSFont fontWithName:fontName size:fontSize];
    return aFont;
}

- (NSFont *)docFont:(NSDictionary *)fontDescription
{
    NSString *fontName = [fontDescription valueForKey:@"fontName"];
    CGFloat fontSize = [[fontDescription valueForKey:@"fontSize"] floatValue];
    return [NSFont fontWithName:fontName size:fontSize];
}

- (NSFileWrapper *)fileWrapperWithIdentifier:(NSString *)identifier
{
    NSString *wrapName = [identifier stringByAppendingPathExtension:@"png"];
    NSData *data = [[NSImage imageNamed:@"bookmark"] PNGRepresentation];
    NSFileWrapper *wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:data];
    [wrapper setFilename:wrapName];
    [wrapper setPreferredFilename:wrapName];
    return wrapper;
}

- (void)parseTextOfType:(NSString *)type forBookmarks:(NSTextStorage *)aStorage
{    
    //if ([type compare:(NSString*)kUTTypePlainText] == NSOrderedSame) {
    if (![type isEqualToString:(NSString*)kUTTypeRTFD]) {
        NSUInteger location = 0, end = [aStorage length];
        
        NSImage *bMark = [NSImage imageNamed:@"bookmark"];
        NSFileWrapper *wrapper = [self fileWrapperWithIdentifier:@"bookmark"];
        NSTextAttachment *attachment = [[NSTextAttachment alloc] initWithFileWrapper:wrapper];
        LITextAttachmentCell *cell = [[LITextAttachmentCell alloc] initImageCell:bMark];;
        [cell setIdentifier:@"bookmark"];
        [attachment setAttachmentCell:cell];
        
        while (location < end) {	// Run through the string in terms of attachment runs
            NSRange bookmarkRange = [[aStorage string] rangeOfString:plainTextBookmarkMarker];
            if (bookmarkRange.location != NSNotFound)  {
                // Вставляем настоящий аттачмент
                [aStorage replaceCharactersInRange:bookmarkRange withAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
                end = [aStorage length];
            }
            else location = NSMaxRange(bookmarkRange);
        }
    }
}

- (void)saveToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation completionHandler:(void (^)(NSError *))completionHandler
{
    [super saveToURL:url ofType:typeName forSaveOperation:saveOperation completionHandler:^(NSError *error) {
        if ([[self fileType] compare:(NSString*)kUTTypePlainText] == NSOrderedSame || [[self fileType] compare:(NSString*)kUTTypeText])
            [self parseTextOfType:typeName forBookmarks:[[WindowController aTextView] textStorage]];
        completionHandler(error);
    }];
}

@end
