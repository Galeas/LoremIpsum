/*
     File: ScalingScrollView.m
 Abstract: A subclass of NSScrollView that supports content scaling.
  Version: 1.7.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import <Cocoa/Cocoa.h>
#import "LIScalingScrollView.h"

static CGFloat scaleFactor;

@implementation LIScalingScrollView
//{
//    NSGradient *topGradient, *bottomGradient;
//}

+ (void)initialize
{
    scaleFactor = 1.0f;
}

/*- (void)drawRect:(NSRect)rect {
    
    if (!topGradient && self.startColor && self.endColor)
        topGradient = [[NSGradient alloc] initWithStartingColor:self.startColor endingColor:self.endColor];
    if (!bottomGradient && self.startColor && self.endColor)
        bottomGradient = [[NSGradient alloc] initWithStartingColor:self.startColor endingColor:self.endColor];
    
    if (topGradient && bottomGradient) {
        NSTextView *textView = self.documentView;
        NSSize gradientSize = textView.textContainer.containerSize;
        gradientSize.height = 50.0f;
        
        NSBezierPath *topPath = [NSBezierPath bezierPathWithRect:NSMakeRect(textView.textContainerOrigin.x, rect.size.height-gradientSize.height, gradientSize.width, gradientSize.height)];
        NSBezierPath *bottomPath = [NSBezierPath bezierPathWithRect:NSMakeRect(textView.textContainerOrigin.x, 0, gradientSize.width, gradientSize.height)];
        [topGradient drawInBezierPath:topPath angle:270];
        [bottomGradient drawInBezierPath:bottomPath angle:90];
    }
    
    [super drawRect:rect];
}*/

- (CGFloat)scaleFactor {
    return scaleFactor;
}

- (void)setScaleFactor:(CGFloat)newScaleFactor {
    if (scaleFactor != newScaleFactor) {
	scaleFactor = newScaleFactor;

	NSView *clipView = [[self documentView] superview];
	
	// Get the frame.  The frame must stay the same.
	NSSize curDocFrameSize = [clipView frame].size;
	
	// The new bounds will be frame divided by scale factor
	NSSize newDocBoundsSize = {curDocFrameSize.width / scaleFactor, curDocFrameSize.height / scaleFactor};
	
	[clipView setBoundsSize:newDocBoundsSize];
    }
}

- (void)setHasHorizontalScroller:(BOOL)flag {
    if (!flag) [self setScaleFactor:1.0];
    [super setHasHorizontalScroller:flag];
}

/* Reassure AppKit that ScalingScrollView supports live resize content preservation, even though it's a subclass that could have modified NSScrollView in such a way as to make NSScrollView's live resize content preservation support inoperative. By default this is disabled for NSScrollView subclasses.
*/
- (BOOL)preservesContentDuringLiveResize {
    return [self drawsBackground];
}


@end
