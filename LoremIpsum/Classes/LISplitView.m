//
//  PESplitView.m
//  PHPEdit
//
//  Created by Akki on 9/26/12.
//  Copyright (c) 2012 Akki. All rights reserved.
//

#import "LISplitView.h"

@implementation LISplitView
@synthesize lastDividerPosition;

static CGFloat dividerThickness;

- (void)setDividerThickness:(CGFloat)thickness
{
    dividerThickness = thickness;
}

- (CGFloat)dividerThickness
{
    CGFloat result = [super dividerThickness];
    if (dividerThickness)
        result = dividerThickness;
    return result;
}

- (void)animateSubviewAtIndex:(NSInteger)index collapse:(BOOL)collapse
{
    NSMutableDictionary *firstAnimationDict = [NSMutableDictionary dictionaryWithCapacity:2];
    NSMutableDictionary *secondAnimationDict = [NSMutableDictionary dictionaryWithCapacity:2];
    
    NSView *first = [self.subviews objectAtIndex:0];
    NSView *second = [self.subviews objectAtIndex:1];
    
    [firstAnimationDict setObject:first forKey:NSViewAnimationTargetKey];
    [secondAnimationDict setObject:second forKey:NSViewAnimationTargetKey];
    
    NSRect newFirstFrame = first.frame;
    NSRect newSecondFrame = second.frame;
    
    if ([self isVertical]) {
        switch (index) {
            case 0: {
                if (collapse) {
                    [self setLastDividerPosition:newFirstFrame.size.width];
                    newFirstFrame.size.width = 0.0f;
                    newSecondFrame.origin.x = 0.0f;
                    newSecondFrame.size.width = self.frame.size.width;
                }
                else {
                    if (self.lastDividerPosition == NSNotFound || self.lastDividerPosition == 0)
                        [self setLastDividerPosition:self.frame.size.width/2];
                    
                    newFirstFrame.size.width = self.lastDividerPosition;
                    newSecondFrame.origin.x = self.lastDividerPosition + self.dividerThickness;
                    newSecondFrame.size.width = self.frame.size.width - newSecondFrame.origin.x;
                    [first setHidden:NO];
                }
                break;
            }
            case 1: {
                if (collapse) {
                    [self setLastDividerPosition:newFirstFrame.size.width];
                    newFirstFrame.size.width = self.frame.size.width;
                    newSecondFrame.origin.x = self.frame.size.width;
                    newSecondFrame.size.width = 0.0f;
                }
                else {
                    if (self.lastDividerPosition == NSNotFound || self.lastDividerPosition == 0)
                        [self setLastDividerPosition:self.frame.size.width/2];
                    
                    newFirstFrame.size.width = self.lastDividerPosition;
                    newSecondFrame.origin.x = self.lastDividerPosition + self.dividerThickness;
                    newSecondFrame.size.width = self.frame.size.width - newSecondFrame.origin.x;
                    [second setHidden:NO];
                }
                break;
            }
            default:break;
        }
    }
    
    else {
        switch (index) {
            case 0: {
                if (collapse) {
                    [self setLastDividerPosition:newFirstFrame.size.height];
                    newFirstFrame.size.height = 0.0f;
                    newSecondFrame.origin.y = 0.0f;
                    newSecondFrame.size.height = self.frame.size.height;
                }
                else {
                    if (self.lastDividerPosition == NSNotFound || self.lastDividerPosition == 0)
                        [self setLastDividerPosition:self.frame.size.height/2];
                    
                    newFirstFrame.size.height = self.lastDividerPosition;
                    newSecondFrame.origin.y = self.lastDividerPosition + self.dividerThickness;
                    newSecondFrame.size.height = self.frame.size.height - newSecondFrame.origin.y;
                    
                    [first setHidden:NO];
                }
                break;
            }
            case 1: {
                if (collapse) {
                    [self setLastDividerPosition:newFirstFrame.size.height];
                    newFirstFrame.size.height = self.frame.size.height;
                    newSecondFrame.origin.y = self.frame.size.height;
                    newSecondFrame.size.height = 0.0f;
                }
                else {
                    if (self.lastDividerPosition == NSNotFound || self.lastDividerPosition == 0)
                        [self setLastDividerPosition:self.frame.size.height/2];
                    
                    newFirstFrame.size.height = self.lastDividerPosition;
                    newSecondFrame.origin.y = self.lastDividerPosition + self.dividerThickness;
                    newSecondFrame.size.height = self.frame.size.height - newSecondFrame.origin.y;
                    [second setHidden: NO];
                }
                break;
            }
            default:break;
        }
    }
    
    [firstAnimationDict setObject:[NSValue valueWithRect:newFirstFrame] forKey:NSViewAnimationEndFrameKey];
    [secondAnimationDict setObject:[NSValue valueWithRect:newSecondFrame] forKey:NSViewAnimationEndFrameKey];
    
    NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:@[ firstAnimationDict, secondAnimationDict ]];
    [animation setDuration:0.25f];
    [animation startAnimation];
}
@end
