//
//  PESplitView.h
//  PHPEdit
//
//  Created by Akki on 9/26/12.
//  Copyright (c) 2012 Akki. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LISplitView : NSSplitView
{
    CGFloat lastDividerPosition;
}

@property (assign) CGFloat lastDividerPosition;

- (void)animateSubviewAtIndex:(NSInteger)index collapse:(BOOL)collapse;
- (void)setDividerThickness:(CGFloat)thickness;
@end
