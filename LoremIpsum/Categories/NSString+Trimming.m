//
//  NSString+Trimming.m
//  LoremIpsum
//
//  Created by Akki on 6/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+Trimming.h"

@implementation NSString (Trimming)

- (NSString *)stringByTrimmingLeadingCharactersInSet:(NSCharacterSet *)characterSet {
    NSUInteger location = 0;
    NSUInteger length = [self length];
    unichar charBuffer[length];    
    [self getCharacters:charBuffer];
    
    for (location = 0; location < length; location++) {
        if (![characterSet characterIsMember:charBuffer[location]]) {
            break;
        }
    }
    
    return [self substringWithRange:NSMakeRange(location, length - location)];
}

+ (NSUInteger) countWords: (NSString *) string {
    NSScanner *scanner = [NSScanner scannerWithString: string];
    NSCharacterSet *whiteSpace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    NSUInteger count = 0;
    while ([scanner scanUpToCharactersFromSet: whiteSpace  intoString: nil]) {
        count++;
    }
    
    return count;
}

- (NSArray *)linesRanges
{
    NSUInteger count = 0, length = [self length];
    NSRange range = NSMakeRange(0, length);
    NSMutableArray *result = [[NSMutableArray alloc] init];
    while(range.location != NSNotFound)
    {
        range = [self rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:0 range:range];
        if(range.location != NSNotFound)
        {
            [result insertObject:[NSValue valueWithRange:NSMakeRange(range.location, range.length)] atIndex:[result count]];
            range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
            count++;
        }
    }
    return result;
}

- (NSUInteger)numberOfOccurencesOfString:(NSString *)string
{
    NSUInteger count = 0, length = [self length];
    NSRange range = NSMakeRange(0, length); 
    while(range.location != NSNotFound)
    {
        range = [self rangeOfString:string options:0 range:range];
        if(range.location != NSNotFound)
        {
            range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
            count++; 
        }
    }
    return count;
}

- (NSUInteger)numberOfOccurencesOfCharactersFromSet:(NSCharacterSet *)set
{
    NSUInteger count = 0, length = [self length];
    NSRange range = NSMakeRange(0, length);
    while (range.location != NSNotFound) {
        range = [self rangeOfCharacterFromSet:set options:0 range:range];
        if (range.location != NSNotFound) {
            range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
            count++;
        }
    }
    return count;
}

- (NSUInteger)firstLineBreakPosition
{
    return [self rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:0].location;
}
@end
