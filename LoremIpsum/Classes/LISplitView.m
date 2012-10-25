//
//  LISplitView.m
//  LoremIpsum
//
//  Created by Akki on 05.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LISplitView.h"
#import "NSColor+Hex.h"
#import <QuartzCore/QuartzCore.h>

@implementation LISplitView
@synthesize customAnimatableProperty;
@synthesize divColor;

- (void)anAnimation
{
    // Add a custom animation to the animations dictionary
    CABasicAnimation* animation = [CABasicAnimation animation];
    NSMutableDictionary* newAnimations = [NSMutableDictionary dictionary];
    [newAnimations addEntriesFromDictionary:[self animations]];
    [newAnimations setObject:animation forKey:@"customAnimatableProperty"];
    [self setAnimations:newAnimations];
    
    // initiate the animation
    [[self animator] setCustomAnimatableProperty:10.0f];
}

- (void)setPosition:(CGFloat)position ofDividerAtIndex:(NSInteger)dividerIndex animate:(BOOL)animate
{
    if (!animate) {
        [super setPosition:position ofDividerAtIndex:dividerIndex];
    }
    else {
        [[self animator] setValue:[NSNumber numberWithFloat:position] forKey:@"dividerPosition"];
    }
}

- (CGFloat)positionForDividerAtIndex:(NSInteger)idx
{
    NSRect frame = [[[self subviews] objectAtIndex:idx] frame];
    if (self.isVertical) {
        return NSMaxX(frame) + ([self dividerThickness] * idx);
    }
    else {
        return NSMaxY(frame) + ([self dividerThickness] * idx);
    }
}

- (id)animationForKey:(NSString *)key
{
    id animation = [super animationForKey:key];
    //NSInteger idx;
    if (animation == nil) {
        animation = [super animationForKey:@"dividerPosition"];
    }
    
    return animation;
}

- (id)valueForUndefinedKey:(NSString *)key
{
   // NSInteger idx;
    //if ([self _tryParsingDividerPositionIndex:&idx fromKey:key]) {
        CGFloat position = [self positionForDividerAtIndex:0];
        return [NSNumber numberWithFloat:position];
   // }
    
    //return nil;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    //NSInteger idx;
    if ([value isKindOfClass:[NSNumber class]]) {
        [super setPosition:[value floatValue] ofDividerAtIndex:0];
    }
}

@end
