//
//  LIBookmark.h
//  LoremIpsum
//
//  Created by Akki on 6/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LIBookmark : NSObject
{
@private
    NSInteger position;
    NSInteger inParagraph;
    NSInteger lineNumber;
    NSInteger length;
    
    NSString *text;
    NSString *posForTable;
}

- (id)initWithBookmarkOnPosition:(id)pos lineNumber:(id)lNumber positionInParagraph:(id)posInParagraph length:(id)len;

@property NSInteger position;
@property NSInteger inParagraph;
@property NSInteger lineNumber;
@property NSInteger length;

@property (copy) NSString *text;
@property (copy) NSString *posForTable;
@end
