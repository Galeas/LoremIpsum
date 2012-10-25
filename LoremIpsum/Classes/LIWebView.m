//
//  LIWebView.m
//  LoremIpsum
//
//  Created by Akki on 7/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LIWebView.h"
#import "LIDocWindowController.h"
#import "LIDocument.h"

@implementation LIWebView

/*- (id)initWithFrame:(NSRect)frame
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

- (void)draggingEnded:(id<NSDraggingInfo>)sender
{
    if ([[[sender draggingPasteboard] types] containsObject:NSURLPboardType]) {
        NSURL *cssURL = [NSURL URLFromPasteboard:[sender draggingPasteboard]];
        if ([[cssURL pathExtension] isEqualToString:@"css"] || [[cssURL pathExtension] isEqualToString:@"CSS"]) {
            
            [SharedDefaultsController setValue:[cssURL path] forKeyPath:@"values.customCSS"];
            [SharedDefaultsController setValue:[NSNumber numberWithBool:YES] forKeyPath:@"values.useCustomCSS"];
        }
    }
}

@end
