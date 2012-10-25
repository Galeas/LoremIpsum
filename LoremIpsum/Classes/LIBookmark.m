//
//  LIBookmark.m
//  LoremIpsum
//
//  Created by Akki on 6/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LIBookmark.h"
#import "LIDocWindowController.h"
#import "LITextView.h"

@implementation LIBookmark
@synthesize position = position;
@synthesize lineNumber = lineNumber;
@synthesize inParagraph = inParagraph;
@synthesize length = length;

@synthesize text = text;
@synthesize posForTable = posForTable;

- (id)initWithBookmarkOnPosition:(id)pos lineNumber:(id)lNumber positionInParagraph:(id)posInParagraph length:(id)len
{
    if (self = [super init]) {
        position = [pos intValue];
        lineNumber = [lNumber intValue];
        inParagraph = [posInParagraph intValue];
        length = [len intValue];
        
        LIDocWindowController *controller = [[NSApp mainWindow] windowController];
        NSTextStorage *textStorage = [[controller aTextView] textStorage];
        
        NSRange activeRange = NSMakeRange([[controller aTextView] indexOfBeginningOfWordAtrange:NSMakeRange(position, 0)], length);
        
        NSString *toText = [[[[[[NSString alloc] initWithString:[[textStorage string] substringWithRange:activeRange]]stringByReplacingOccurrencesOfString:@"\t" withString:@" "] stringByReplacingOccurrencesOfString:@"\n" withString:@" "]stringByReplacingOccurrencesOfString:@"\r\n" withString:@" "] stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
        
        NSCharacterSet *whitespaces = [NSCharacterSet whitespaceCharacterSet];
        NSPredicate *noEmptyStrings = [NSPredicate predicateWithFormat:@"SELF != ''"];
        
        NSArray *parts = [toText componentsSeparatedByCharactersInSet:whitespaces];
        NSArray *filteredArray = [parts filteredArrayUsingPredicate:noEmptyStrings];
        toText = [filteredArray componentsJoinedByString:@" "];
        
        if (activeRange.location == 0)
            text = [[NSString alloc] initWithFormat:@"%@...", toText];
        else        
            text = [[NSString alloc] initWithFormat:@"...%@...", toText];
        posForTable = [[NSString alloc] initWithFormat:@"%ld:%ld", lineNumber, inParagraph];
        
        return self;
    }
    return nil;
}

@end
