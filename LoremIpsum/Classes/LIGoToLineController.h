//
//  LIGoToLineController.h
//  LoremIpsum
//
//  Created by Akki on 6/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LIGoToLineController : NSWindowController
{
    __weak NSTextField *lineNumber;
    __weak NSButton *okButton;
    
}

- (IBAction)gotoLineOk:(id)sender;
- (IBAction)goToLineCancel:(id)sender;
@property (weak) IBOutlet NSTextField *lineNumber;
@property (weak) IBOutlet NSButton *okButton;
@end
