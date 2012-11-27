//
//  LIGradientOverlayVew.h
//  LoremIpsum
//
//  Created by Akki on 10/31/12.
//
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface LIGradientOverlayVew : NSView
{
    NSColor *_gradientColor;
}

- (void)moveFocus:(NSDictionary*)rects;
- (void)removeFocus;
- (void)animateAppearingBookmarkAtPosition:(NSInteger)position;
- (void)findActive:(BOOL)active;

@property (copy) NSColor *gradientColor;
@property (copy) CATextLayer *infoLayer;
@end
