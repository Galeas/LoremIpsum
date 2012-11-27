//
//  LITextAttachmentCell.h
//  LoremIpsum
//
//  Created by Akki on 6/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LITextAttachmentCell : NSTextAttachmentCell
{
    NSString *_identifier;
}
@property (strong) NSString *identifier;
@end
