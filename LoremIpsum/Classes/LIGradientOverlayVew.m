//
//  LIGradientOverlayVew.m
//  LoremIpsum
//
//  Created by Akki on 10/31/12.
//
//

#import "LIGradientOverlayVew.h"
#import "LIDocWindowController.h"
#import "LISettingsProxy.h"
#import "ESSImageCategory.h"
#import "LITextView.h"

#import "LISplitView.h"
#import "LIBackColoredView.h"
#import <QuartzCore/QuartzCore.h>

@implementation LIGradientOverlayVew
{
    NSColor *currentColor;
    CAGradientLayer *topLayer, *bottomLayer;
    CALayer *topMask, *bottomMask;
    
    NSArray *topLayerColorsBackup;
}

- (void)drawRect:(NSRect)dirtyRect
{
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // Drawing code here.
    if (![self wantsLayer] && !topLayer && !bottomLayer && !_infoLayer)
        [self setWantsLayer:YES];
    
    if (self.gradientColor) {
        
        NSScrollView *scrollContainer = (NSScrollView*)[[self.window windowController] scrollContainer];
        NSSize gradientSize = scrollContainer.bounds.size/*textView.textContainer.containerSize*/;
        gradientSize.height = 25.0f;
        
        if (!bottomLayer) {
            bottomLayer = [CAGradientLayer layer];
            NSMutableArray *gLocationsBottom = [NSMutableArray array];
            for (int i = 0; i < 10; i++)
                [gLocationsBottom addObject:[NSNumber numberWithFloat:(float)i/10]];
        
            [bottomLayer setLocations:gLocationsBottom];
            [bottomLayer setName:@"bottomLayer"];
            [bottomLayer setAutoresizingMask:kCALayerWidthSizable];
            
            [bottomLayer setFrame:NSRectToCGRect(NSMakeRect(scrollContainer.frame.origin.x, scrollContainer.frame.origin.y, gradientSize.width, gradientSize.height))];
            
            NSMutableArray *gColorsBottom = [NSMutableArray array];
            for (int j = 10; j > 0; j--) {
                float alpha = (float)j / 10;
                CGColorRef cgAlfaColor = [self.gradientColor coreGraphicsColorWithAlfa:alpha];
                [gColorsBottom addObject:(__bridge id)cgAlfaColor];
                CGColorRelease(cgAlfaColor);
            }
            
            [bottomLayer setColors:gColorsBottom];
            
            [self.layer addSublayer:bottomLayer];
        }
        
        if (!topLayer) {
            topLayer = [CAGradientLayer layer];
            NSMutableArray *gLocationsTop = [NSMutableArray array];
            for (int i = 0; i < 10; i++)
                [gLocationsTop addObject:[NSNumber numberWithFloat:(float)i/10]];
            
            [topLayer setLocations:gLocationsTop];
            [topLayer setName:@"topLayer"];
            [topLayer setAutoresizingMask:kCALayerWidthSizable];
            [topLayer setFrame:NSRectToCGRect(NSMakeRect(0, dirtyRect.size.height-gradientSize.height, gradientSize.width, gradientSize.height))];
            
            NSArray *gColorsTop = [[bottomLayer.colors reverseObjectEnumerator] allObjects];
            [topLayer setColors:gColorsTop];
            
            [self.layer addSublayer:topLayer];
        }
        
        [CATransaction flush];
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        /*NSMutableArray *gColorsBottom = [NSMutableArray array];
        for (int j = 10; j > 0; j--) {
            float alpha = (float)j / 10;
             [gColorsBottom addObject:(__bridge id)[self.gradientColor colorWithAlphaComponent:alpha].CGColor];
        }
        
        [bottomLayer setColors:gColorsBottom];
        NSArray *gColorsTop = [[gColorsBottom reverseObjectEnumerator] allObjects];
        [topLayer setColors:gColorsTop];*/
        
        [bottomLayer setFrame:NSRectToCGRect(NSMakeRect(scrollContainer.frame.origin.x, scrollContainer.frame.origin.y, gradientSize.width, gradientSize.height))];
        [topLayer setFrame:NSRectToCGRect(NSMakeRect(0, dirtyRect.size.height-gradientSize.height, gradientSize.width, gradientSize.height))];
        [CATransaction commit];
        
        if (!_infoLayer) {
            _infoLayer = [CATextLayer layer];
            [_infoLayer bind:@"string" toObject:[self.window windowController] withKeyPath:@"infoString" options:nil];
            [_infoLayer setFont:@"Futura"];
            [_infoLayer setFontSize:12.0f];
            
            CGColorRef infoLayerColorRef = [[NSColor colorWithHex:@"#9E9E9E"] coreGraphicsColorWithAlfa:1];
            [_infoLayer setForegroundColor:infoLayerColorRef];
            CGColorRelease(infoLayerColorRef);
            
            [_infoLayer setAutoresizingMask:kCALayerWidthSizable];
            [_infoLayer setAlignmentMode:kCAAlignmentCenter];
            
            CGColorRef infoLayerBackColorRef = [self.gradientColor coreGraphicsColorWithAlfa:1];
            [_infoLayer setBackgroundColor:infoLayerBackColorRef];
            CGColorRelease(infoLayerBackColorRef);
            
            [_infoLayer setFrame:NSRectToCGRect(NSMakeRect(0, 0, self.bounds.size.width, 25))];
            [self.layer addSublayer:_infoLayer];
        }
        else {
            [_infoLayer setFrame:NSRectToCGRect(NSMakeRect(0, 0, self.bounds.size.width, 25))];
            CGColorRef infoBackColorRef = _infoLayer.backgroundColor;
            CGFloat *colorComponents = (CGFloat*)CGColorGetComponents(infoBackColorRef);
            NSColor *infoBackColor = [NSColor colorWithCalibratedRed:colorComponents[0] green:colorComponents[1] blue:colorComponents[2] alpha:colorComponents[3]];
            if (![infoBackColor isEqualTo:self.gradientColor]) {
                CGColorRef infoLayerBackColorRef = [self.gradientColor coreGraphicsColorWithAlfa:1];
                [_infoLayer setBackgroundColor:infoLayerBackColorRef];
                CGColorRelease(infoLayerBackColorRef);
            }
        }
        
    }    
    
    [CATransaction flush];
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    if ([[self.layer sublayers] containsObject:topMask]) {
        CGColorRef cgTopMaskBackC = topMask.backgroundColor;
        CGFloat *colorComponents = (CGFloat*)CGColorGetComponents(cgTopMaskBackC);
        NSColor *backTopMaskColor = [NSColor colorWithCalibratedRed:colorComponents[0] green:colorComponents[1] blue:colorComponents[2] alpha:colorComponents[3]];
        if (![backTopMaskColor isEqualTo:self.gradientColor]) {
            CGColorRef topMaskBackColorRef = [self.gradientColor coreGraphicsColorWithAlfa:.75f];
            [topMask setBackgroundColor:topMaskBackColorRef];
            CGColorRelease(topMaskBackColorRef);
        }
    }
    if ([[self.layer sublayers] containsObject:bottomMask]) {
        CGColorRef cgBottomMaskBackC = bottomMask.backgroundColor;
        CGFloat *colorComponents = (CGFloat*)CGColorGetComponents(cgBottomMaskBackC);
        NSColor *backBottomMaskColor = [NSColor colorWithCalibratedRed:colorComponents[0] green:colorComponents[1] blue:colorComponents[2] alpha:colorComponents[3]];
        if (![backBottomMaskColor isEqualTo:self.gradientColor]) {
            CGColorRef bottomMaskBackColorRef = [self.gradientColor coreGraphicsColorWithAlfa:.75f];
            [bottomMask setBackgroundColor:bottomMaskBackColorRef];
            CGColorRelease(bottomMaskBackColorRef);
        }
    }
    
    [CATransaction commit];
    [super drawRect:dirtyRect];
}

- (void)moveFocus:(NSDictionary *)rects
{
    if (self.gradientColor) {
        NSColor *backColor = [self.gradientColor colorWithAlphaComponent:.75f];
        CGColorRef backColorRef = [backColor coreGraphicsColorWithAlfa:.75f];
        if (![self wantsLayer])
            [self setWantsLayer:YES];
        
        if (!topMask) {
            topMask = [CALayer layer];
            [topMask setAutoresizingMask:kCALayerWidthSizable];
            [topMask setBackgroundColor:backColorRef];
        }
        if (!bottomMask) {
            bottomMask = [CALayer layer];
            [bottomMask setAutoresizingMask:kCALayerWidthSizable];
            [bottomMask setBackgroundColor:backColorRef];
        }
        
        if (bottomMask && ![[self.layer sublayers] containsObject:bottomMask])
            [[self layer] addSublayer:bottomMask];
        if (topMask && ![[self.layer sublayers] containsObject:topMask])
            [[self layer] addSublayer:topMask];
        
        if (backColorRef != bottomMask.backgroundColor)
            [bottomMask setBackgroundColor:backColorRef];
        if (backColorRef != topMask.backgroundColor)
            [topMask setBackgroundColor:backColorRef];
        
        NSRect bottom = [[rects valueForKey:@"bottomMask"] rectValue];
        bottom = [self convertRect:bottom fromView:(NSView*)[[self.window windowController] aTextView]];
        bottom.size.height += bottom.origin.y - _infoLayer.frame.size.height;
        bottom.origin.y = _infoLayer.frame.size.height;
        NSRect top = [[rects valueForKey:@"topMask"] rectValue];
        top = [self convertRect:top fromView:(NSView*)[[self.window windowController] aTextView]];
        
        [CATransaction flush];
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        [bottomMask setFrame:NSRectToCGRect(bottom)];
        [topMask setFrame:NSRectToCGRect(top)];
        [CATransaction commit];
        
        CGColorRelease(backColorRef);
    }
}

- (void)removeFocus
{
    [topMask removeFromSuperlayer];
    [bottomMask removeFromSuperlayer];
}

- (void)animateAppearingBookmarkAtPosition:(NSInteger)position
{
    LITextView *textView = [self.window.windowController aTextView];
    NSImage *bookmark = [NSImage imageNamed:@"bookmark"];
    CALayer *bookmarkLayer = [CALayer layer];
    CGImageRef imageRef = nil;
    
    NSData *imageData = [bookmark PNGRepresentation];
    
    if (imageData) {
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData,  NULL);
        imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
        CFRelease(imageSource);
    }
    
    [bookmarkLayer setContents:(__bridge id)imageRef];
    
    [bookmarkLayer setBounds:NSRectToCGRect(NSMakeRect(0, 0, bookmark.size.width, bookmark.size.height))];
    CGImageRelease(imageRef);
    
    NSRect rectForImageLayer = [textView rectForBookmarkAnimation:NSMakeRange(position, 0)];
    rectForImageLayer = [self convertRect:rectForImageLayer fromView:(NSView*)textView];
    rectForImageLayer.origin.y += _infoLayer.frame.size.height + [textView textContainerInset].height*2;
    [bookmarkLayer setName:@"bookmarkLayer"];
    [bookmarkLayer setPosition:rectForImageLayer.origin];
    
    [self.layer addSublayer:bookmarkLayer];
    
    NSPoint startPoint = bookmarkLayer.position;
    NSPoint endPoint = NSMakePoint(startPoint.x, startPoint.y - 18);
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    anim.fromValue = [NSValue valueWithPoint:startPoint];
    anim.toValue = [NSValue valueWithPoint:endPoint];
    anim.repeatCount = 1.0;
    anim.duration = 0.2;
    anim.removedOnCompletion = YES;
    [anim setDelegate:[self.window windowController]];
    
    [bookmarkLayer addAnimation:anim forKey:@"position"];
    
    [bookmarkLayer performSelector:@selector(removeFromSuperlayer) withObject:nil afterDelay:anim.duration - .15f];
}

- (void)findActive:(BOOL)active
{
    [CATransaction flush];
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    if (active) {
        if (!topLayerColorsBackup)
            topLayerColorsBackup = topLayer.colors;
        
        NSMutableArray *fakeColors = [NSMutableArray arrayWithCapacity:topLayer.colors.count];
        for (int i = 0; i < topLayer.colors.count; i++) {
            CGColorRef clearColorRef = [[NSColor clearColor] coreGraphicsColorWithAlfa:0];
            [fakeColors addObject:(__bridge id)clearColorRef];
            CGColorRelease(clearColorRef);
        }
        [topLayer setColors:fakeColors];
    }
    else {
        [topLayer setColors:topLayerColorsBackup];
        topLayerColorsBackup = nil;
    }
    [CATransaction commit];
    
    [self setNeedsDisplay:YES];
}

- (void)setGradientColor:(NSColor *)gradientColor
{
    _gradientColor = gradientColor;
    
    if (topLayer && bottomLayer) {
        NSMutableArray *gColorsBottom = [NSMutableArray array];
        for (int j = 10; j > 0; j--) {
            float alpha = (float)j / 10;
            CGColorRef cgAlfaColor = [self.gradientColor coreGraphicsColorWithAlfa:alpha];
            [gColorsBottom addObject:(__bridge id)cgAlfaColor];
            CGColorRelease(cgAlfaColor);
        }
        
        [bottomLayer setColors:gColorsBottom];
        NSArray *gColorsTop = [[gColorsBottom reverseObjectEnumerator] allObjects];
        [topLayer setColors:gColorsTop];
    }
    
    [self setNeedsDisplay:YES];
}

- (NSColor *)gradientColor
{
    return _gradientColor;
}
@end
