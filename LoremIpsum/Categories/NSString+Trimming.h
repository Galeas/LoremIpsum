//
//  NSString+Trimming.h
//  LoremIpsum
//
//  Created by Akki on 6/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Trimming)

- (NSString *)stringByTrimmingLeadingCharactersInSet:(NSCharacterSet *)characterSet;
+ (NSUInteger) countWords: (NSString *) string;
- (NSArray*)linesRanges;
- (NSUInteger)numberOfOccurencesOfString:(NSString*)string;
- (NSUInteger)numberOfOccurencesOfCharactersFromSet:(NSCharacterSet *)set;
- (NSUInteger)firstLineBreakPosition;   //Первый после каретки обрыв строки
@end
