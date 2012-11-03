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

- (void)moveFocus:(NSDictionary*)rects;
- (void)removeFocus;
- (void)animateAppearingBookmarkAtPosition:(NSInteger)position;

@property (copy) NSColor *gradientColor;
@property (copy) CATextLayer *infoLayer;
@end
