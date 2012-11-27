//
//  LITableView.m
//  LoremIpsum
//
//  Created by Akki on 6/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LITableView.h"
#import "LIBookmarxController.h"

@implementation LITableView
/*
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}
*/

- (NSString *)toolTip
{
    return @"";
}

- (void)keyDown:(NSEvent *)theEvent
{    
    unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    if(key == NSDeleteCharacter || key == NSDeleteFunctionKey)
    {
        if([self selectedRow] == -1)
        {
            NSBeep();
        }
        
        BOOL isEditing = ([[self.window firstResponder] isKindOfClass:[NSText class]]);
        if (!isEditing) 
        {
            NSInteger count = [[[LIBookmarxController bookmarxController] bookmarxDataSource] count];
            [[LIBookmarxController bookmarxController] willChange:NSKeyValueObservingOptionNew valuesAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)] forKey:@"bookmarxDataSource"];
            [[[LIBookmarxController bookmarxController] bookmarxDataSource] removeObjectAtIndex:[self selectedRow]];
            
            [[LIBookmarxController bookmarxController] didChangeValueForKey:@"bookmarxDataSource"];
            return;
        }        
    }
    if (key == 27)
        [[LIBookmarxController bookmarxController] closeSheet:self];
    if (key == 13 || key == 3)
        [[LIBookmarxController bookmarxController] bookmarkDoubleClick];
    
    // still here?
    [super keyDown:theEvent];
}

- (NSRect)frame
{
    return NSMakeRect(0, 0, [self.window.contentView bounds].size.width, 17*[self numberOfRows]);
}

@end
