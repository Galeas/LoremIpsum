//
//  LIPopoverView.m
//  LoremIpsum
//
//  Created by Akki on 6/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LIPopoverView.h"
#import "NSColor+Hex.h"

@implementation LIPopoverView
/*
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}
*/
- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    [super drawRect:dirtyRect];
    switch ([[[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.whiteBlack"] intValue]) {
        case 0: {
            CGContextRef context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
            CGContextSetRGBFillColor(context, 0.227,0.251,0.337,0.8);
            CGContextFillRect(context, NSRectToCGRect(dirtyRect));
            break;
        }
        case 1: {
            CGContextRef context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
            CGContextSetFillColorWithColor(context, [[NSColor colorWithHex:[[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.backgroundColor"]] coreGraphicsColorWithAlfa:0.8]);
            CGContextFillRect(context, NSRectToCGRect(dirtyRect));
            break;
        }
    }
}
@end
