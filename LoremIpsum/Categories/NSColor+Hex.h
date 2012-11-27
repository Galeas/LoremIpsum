//
//  NSColor+Hex.h
//  PHPEdit
//
//  Created by Akki on 4/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSColor (Hex)

- (NSString *) hexColor;
- (int) intColor;
- (NSColor *) invertedColor;
- (CGColorRef) coreGraphicsColorWithAlfa:(CGFloat)alfa;
+ (NSColor *) colorWithHex:(NSString *)hexColor;
@end
