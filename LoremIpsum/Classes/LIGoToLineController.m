//
//  LIGoToLineController.m
//  LoremIpsum
//
//  Created by Akki on 6/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LIGoToLineController.h"
#import "LIDocWindowController.h"

@interface LIGoToLineController ()

@end

@implementation LIGoToLineController
@synthesize okButton;
@synthesize lineNumber;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

- (IBAction)gotoLineOk:(id)sender
{
    if ([[[NSApp mainWindow] windowController] isMemberOfClass:[LIDocWindowController class]]) {
        [[[NSApp mainWindow] windowController] gotoLine:[lineNumber intValue]];
    }
    [self goToLineCancel:self];
}

- (IBAction)goToLineCancel:(id)sender {
    [NSApp endSheet:self.window];
    [self.window orderOut:self];
    [self.window performClose:self];
}
@end
