//
//  LISplitView.h
//  LoremIpsum
//
//  Created by Akki on 05.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LISplitView : NSSplitView {
    CALayer *colorLayer;
}

- (void)setPosition:(CGFloat)position ofDividerAtIndex:(NSInteger)dividerIndex animate:(BOOL)animate;
- (CGFloat)positionForDividerAtIndex:(NSInteger)idx;
- (void)anAnimation;

@property (assign) float customAnimatableProperty;
@property NSColor *divColor;

@end
