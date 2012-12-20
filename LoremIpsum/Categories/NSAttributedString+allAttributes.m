//
//  NSAttributedString+allAttributes.m
//  LoremIpsum
//
//  Created by Akki on 12/19/12.
//
//

#import "NSAttributedString+allAttributes.h"

@implementation NSAttributedString (allAttributes)

- (NSArray *)allAttributes
{
    NSMutableArray *result = [NSMutableArray array];
    
    NSRange selfRange = NSMakeRange(0, self.length);
    NSUInteger max = NSMaxRange(selfRange);
    
    NSRange effectiveRange = NSMakeRange(0, NSNotFound);
    while (NSMaxRange(effectiveRange) != max) {
        NSDictionary *attributes = [self attributesAtIndex:selfRange.location longestEffectiveRange:&effectiveRange inRange:selfRange];
        [result addObject:attributes];
        
        selfRange.location += effectiveRange.length;
        selfRange.length = max - selfRange.location;
    }
    
    return result;
}

@end
