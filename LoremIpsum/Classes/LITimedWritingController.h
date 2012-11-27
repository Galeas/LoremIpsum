//
//  LITimedWritingController.h
//  LoremIpsum
//
//  Created by Akki on 6/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LITimedWritingController : NSWindowController <NSWindowDelegate>
{
    __weak NSButton *countdownCheck;
    __weak NSDatePicker *timeZ;
    __weak NSMenuItem *mainItem;
}

+ (LITimedWritingController*) timedWritingController;
- (IBAction)startCountdown:(id)sender;
- (IBAction)closeSheet:(id)sender;
- (IBAction)stopTimer:(id)sender;

- (void)performCountown:(NSTimer*)_timer;

@property NSString *showedCountdown;
@property BOOL showTimer;
@property NSTimer *cTimer;

@property (weak) IBOutlet NSButton *countdownCheck;
@property (weak) IBOutlet NSDatePicker *timeZ;
@property (weak) IBOutlet NSMenuItem *mainItem;
@end
