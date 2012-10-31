//
//  LIGradientOverlayVew.m
//  LoremIpsum
//
//  Created by Akki on 10/31/12.
//
//

#import "LIGradientOverlayVew.h"
#import "LIDocWindowController.h"
#import <QuartzCore/QuartzCore.h>

@implementation LIGradientOverlayVew
{
    //NSGradient *topGradient, *bottomGradient;
    NSColor *currentColor;
    CAGradientLayer *topLayer, *bottomLayer;
    CATextLayer *infoLayer;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    /*if (self.gradientColor) {
        if (!topGradient)
            topGradient = [[NSGradient alloc] initWithStartingColor:[self.gradientColor colorWithAlphaComponent:1] endingColor:[self.gradientColor colorWithAlphaComponent:0]];
        if (!bottomGradient)
            bottomGradient = [[NSGradient alloc] initWithStartingColor:[self.gradientColor colorWithAlphaComponent:1] endingColor:[self.gradientColor colorWithAlphaComponent:0]];
        
        if ((!currentColor && ![currentColor isEqualTo:self.gradientColor]) && (topGradient && bottomGradient)) {
            NSTextView *textView = (NSTextView*)[[self.window windowController] aTextView];
            NSSize gradientSize = textView.textContainer.containerSize;
            gradientSize.height = 100;
            
            NSBezierPath *topPath = [NSBezierPath bezierPathWithRect:NSMakeRect(textView.textContainerOrigin.x, dirtyRect.size.height-gradientSize.height, gradientSize.width, gradientSize.height)];
            NSBezierPath *bottomPath = [NSBezierPath bezierPathWithRect:NSMakeRect(textView.textContainerOrigin.x, 0, gradientSize.width, gradientSize.height)];
            [topGradient drawInBezierPath:topPath angle:270];
            [bottomGradient drawInBezierPath:bottomPath angle:90];
        }
        
    }*/
    if (![self wantsLayer] && !topLayer && !bottomLayer && !infoLayer)
        [self setWantsLayer:YES];
    
    if (self.gradientColor) {

        NSTextView *textView = (NSTextView*)[[self.window windowController] aTextView];
        NSScrollView *scrollContainer = (NSScrollView*)[[self.window windowController] scrollContainer];
        NSSize gradientSize = textView.textContainer.containerSize;
        gradientSize.height = 35.0f;
        
        if (!bottomLayer) {
            bottomLayer = [CAGradientLayer layer];
            NSArray *gLocationsBottom = @[[NSNumber numberWithFloat:0.4], [NSNumber numberWithFloat:0.65], [NSNumber numberWithFloat:0.75], [NSNumber numberWithFloat:0.85], [NSNumber numberWithFloat:1]];
        
            [bottomLayer setLocations:gLocationsBottom];
            [bottomLayer setName:@"bottomLayer"];
            [bottomLayer setAutoresizingMask:kCALayerWidthSizable];
            
            [bottomLayer setFrame:NSRectToCGRect(NSMakeRect(textView.textContainerOrigin.x, scrollContainer.frame.origin.y, gradientSize.width, gradientSize.height))];
            [self.layer addSublayer:bottomLayer];
        }
        
        if (!topLayer) {
            topLayer = [CAGradientLayer layer];
            NSArray *gLocationsTop = @[[NSNumber numberWithFloat:0.2], [NSNumber numberWithFloat:0.4], [NSNumber numberWithFloat:0.45], [NSNumber numberWithFloat:0.6], [NSNumber numberWithFloat:1]];
            
            [topLayer setLocations:gLocationsTop];
            [topLayer setName:@"topLayer"];
            [topLayer setAutoresizingMask:kCALayerWidthSizable];
            
            [self.layer addSublayer:topLayer];
            
            [topLayer setFrame:NSRectToCGRect(NSMakeRect(textView.textContainerOrigin.x, dirtyRect.size.height-gradientSize.height, gradientSize.width, gradientSize.height))];
        }
        
        NSArray *gColorsBottom = @[(__bridge id)[self.gradientColor colorWithAlphaComponent:1.0f].CGColor, (__bridge id)[self.gradientColor colorWithAlphaComponent:0.75f].CGColor, (__bridge id)[self.gradientColor colorWithAlphaComponent:0.5f].CGColor, (__bridge id)[self.gradientColor colorWithAlphaComponent:0.25f].CGColor, (__bridge id)[self.gradientColor colorWithAlphaComponent:0.05f].CGColor];
        [bottomLayer setColors:gColorsBottom];
        NSArray *gColorsTop = [[gColorsBottom reverseObjectEnumerator] allObjects];
        [topLayer setColors:gColorsTop];
        
        [CATransaction flush];
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        [topLayer setFrame:NSRectToCGRect(NSMakeRect(textView.textContainerOrigin.x, dirtyRect.size.height-gradientSize.height, gradientSize.width, gradientSize.height))];
        [bottomLayer setFrame:NSRectToCGRect(NSMakeRect(textView.textContainerOrigin.x, scrollContainer.frame.origin.y, gradientSize.width, gradientSize.height))];
        [CATransaction commit];
    }
    
    if (!infoLayer) {
        infoLayer = [CATextLayer layer];
        [infoLayer bind:@"string" toObject:[self.window windowController] withKeyPath:@"infoString" options:nil];
        [infoLayer setFont:@"Futura"];
        [infoLayer setFontSize:12.0f];
        [infoLayer setForegroundColor:[NSColor colorWithHex:@"#9E9E9E"].CGColor];
        [infoLayer setAutoresizingMask:kCALayerWidthSizable];
        [infoLayer setAlignmentMode:kCAAlignmentCenter];
        
        [infoLayer setFrame:NSRectToCGRect(NSMakeRect(0, 0, self.bounds.size.width, 16))];
        [self.layer addSublayer:infoLayer];
    }
    else {
        [CATransaction flush];
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        [infoLayer setFrame:NSRectToCGRect(NSMakeRect(0, 0, self.bounds.size.width, 20))];
        [CATransaction commit];
    }
    
    [super drawRect:dirtyRect];
}

@end
