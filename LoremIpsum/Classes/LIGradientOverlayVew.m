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
#import "LIScalingScrollView.h"
#import <QuartzCore/QuartzCore.h>

@implementation LIGradientOverlayVew
{
    //NSGradient *topGradient, *bottomGradient;
    NSColor *currentColor;
    CAGradientLayer *topLayer, *bottomLayer;
    CALayer *topMask, *bottomMask;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    if (![self wantsLayer] && !topLayer && !bottomLayer && !_infoLayer)
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
    
    if (!_infoLayer) {
        _infoLayer = [CATextLayer layer];
        [_infoLayer bind:@"string" toObject:[self.window windowController] withKeyPath:@"infoString" options:nil];
        [_infoLayer setFont:@"Futura"];
        [_infoLayer setFontSize:12.0f];
        [_infoLayer setForegroundColor:[NSColor colorWithHex:@"#9E9E9E"].CGColor];
        [_infoLayer setAutoresizingMask:kCALayerWidthSizable];
        [_infoLayer setAlignmentMode:kCAAlignmentCenter];
        
        [_infoLayer setFrame:NSRectToCGRect(NSMakeRect(0, 0, self.bounds.size.width, 16))];
        [self.layer addSublayer:_infoLayer];
    }
    else {
        [CATransaction flush];
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        [_infoLayer setFrame:NSRectToCGRect(NSMakeRect(0, 0, self.bounds.size.width, 20))];
        [CATransaction commit];
    }
    
    if ([[self.layer sublayers] containsObject:topMask])
        [topMask setBackgroundColor:[self.gradientColor colorWithAlphaComponent:.75f].CGColor];
    if ([[self.layer sublayers] containsObject:bottomMask])
        [bottomMask setBackgroundColor:[self.gradientColor colorWithAlphaComponent:.75f].CGColor];
    
    [super drawRect:dirtyRect];
}

- (void)moveFocus:(NSDictionary *)rects
{
    if (self.gradientColor) {
        NSColor *backColor = [self.gradientColor colorWithAlphaComponent:.75f];
        if (![self wantsLayer])
            [self setWantsLayer:YES];
        
        if (!topMask) {
            topMask = [CALayer layer];
            [topMask setAutoresizingMask:kCALayerWidthSizable];
            [topMask setBackgroundColor:backColor.CGColor];
        }
        if (!bottomMask) {
            bottomMask = [CALayer layer];
            [bottomMask setAutoresizingMask:kCALayerWidthSizable];
            [bottomMask setBackgroundColor:backColor.CGColor];
        }
        
        if (bottomMask && ![[self.layer sublayers] containsObject:bottomMask])
            [[self layer] addSublayer:bottomMask];
        if (topMask && ![[self.layer sublayers] containsObject:topMask])
            [[self layer] addSublayer:topMask];
        
        if (backColor.CGColor != bottomMask.backgroundColor)
            [bottomMask setBackgroundColor:backColor.CGColor];
        if (backColor.CGColor != topMask.backgroundColor)
            [topMask setBackgroundColor:backColor.CGColor];
        
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
    CGFloat scaleFactor = [[[self.window windowController] scrollContainer] scaleFactor];
    if (scaleFactor == 0) scaleFactor = 1;
    
    [bookmarkLayer setBounds:NSRectToCGRect(NSMakeRect(0, 0, bookmark.size.width*scaleFactor, bookmark.size.height*scaleFactor))];
    CGImageRelease(imageRef);
    
    NSRect rectForImageLayer = [textView rectForBookmarkAnimation:NSMakeRange(position, 0)];
    rectForImageLayer = [self convertRect:rectForImageLayer fromView:(NSView*)textView];
    rectForImageLayer.origin.y += _infoLayer.frame.size.height + [textView textContainerInset].height*2;
    [bookmarkLayer setName:@"bookmarkLayer"];
    [bookmarkLayer setPosition:rectForImageLayer.origin];
    
    [self.layer addSublayer:bookmarkLayer];
    
    NSPoint startPoint = bookmarkLayer.position;
    NSPoint endPoint = NSMakePoint(startPoint.x, startPoint.y - 18*scaleFactor);
    
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

@end
