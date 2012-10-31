//
//  LIBackColoredView.m
//  PHPEdit
//
//  Created by Akki on 9/24/12.
//  Copyright (c) 2012 Akki. All rights reserved.
//

#import "LIBackColoredView.h"
#import "NSColor+Hex.h"

@implementation LIBackColoredView

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    if (!background)
        background = [NSColor colorWithHex:@"DDE2E8"];
    
    CGFloat red = [background redComponent];
    CGFloat green = [background greenComponent];
    CGFloat blue = [background blueComponent];
    CGFloat alpha = [background alphaComponent];
    
    CGContextRef context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetRGBFillColor(context,red, green, blue, alpha);
    CGContextFillRect(context, NSRectToCGRect(dirtyRect));
}

- (NSColor *)background
{
    return background;
}

- (void)mouseDown:(NSEvent *)theEvent {
    
}

- (void)mouseDragged:(NSEvent *)theEvent {
    
}

- (void)setBackground:(NSColor *)color
{
    if ([self.background isEqual:color])
        return;
    background = color;
    [self setNeedsDisplay:YES];
}
@end
