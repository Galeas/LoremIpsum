//
//  LITimedWritingController.m
//  LoremIpsum
//
//  Created by Akki on 6/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LITimedWritingController.h"
#import "LIDocWindowController.h"

@interface LITimedWritingController ()
{
    NSTimer *countdownTimer;
    NSDate *dateZ;
    NSTimeInterval hourZ;
}
@end

@implementation LITimedWritingController
@synthesize timeZ;
@synthesize countdownCheck;
@synthesize showedCountdown;
@synthesize showTimer;
@synthesize cTimer = countdownTimer;
@synthesize mainItem;

+ (LITimedWritingController *)timedWritingController
{
    static LITimedWritingController *controller = nil;
    static dispatch_once_t predicate;
    dispatch_once( &predicate, ^{
        controller = [[LITimedWritingController alloc] initWithWindowNibName:@"LITimedWritingController"];
        
    } );
    return controller;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem.action == @selector(showWindow:)) {
        [menuItem setTitle:@"Timed Writing"];
        return YES;
    }
    
    if (menuItem.action == @selector(stopTimer:)) {
        [menuItem setTitle:@"Stop Timer"];
        return YES;
    }
    return YES;
}

- (IBAction)startCountdown:(id)sender
{
    hourZ = [[timeZ dateValue] timeIntervalSinceNow];
    dateZ = [timeZ dateValue];
    
    if ([dateZ compare:[NSDate date]] == NSOrderedAscending) {
        NSAlert *dateAlrt = [NSAlert alertWithMessageText:@"Time is gone!" defaultButton:@"Re-Pick Date" alternateButton:@"" otherButton:@"" informativeTextWithFormat:@"You can't choose past time!"];
        [dateAlrt setAlertStyle:NSInformationalAlertStyle];
        if ([[[NSApp mainWindow] windowController] isMemberOfClass:[LIDocWindowController class]]) {
            [dateAlrt beginSheetModalForWindow:[NSApp keyWindow] modalDelegate:nil didEndSelector:nil contextInfo:NULL];
        }
    } else {
        if (![countdownTimer isValid])
            countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(performCountown:) userInfo:nil repeats:YES];
        [self closeSheet:self];
        [mainItem setAction:@selector(stopTimer:)];
    }
}

- (IBAction)closeSheet:(id)sender
{
    [[NSApplication sharedApplication] endSheet:self.window];
    [self.window orderOut:self];
    [self.window performClose:self];
}

- (IBAction)stopTimer:(id)sender
{
    [countdownTimer invalidate];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"timerStopped" object:nil];
    [mainItem setAction:@selector(showWindow:)];
}

- (id) init
{
    self = [LITimedWritingController timedWritingController];
    return  self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [countdownCheck setState:1];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [self setShowTimer:[countdownCheck state]];
}

- (void)showWindow:(id)sender
{
    if ([[[NSApp mainWindow] windowController] isMemberOfClass:[LIDocWindowController class]]) {
        [[NSApplication sharedApplication] beginSheet:[self window] modalForWindow:[[NSApplication sharedApplication] keyWindow] modalDelegate:nil didEndSelector:nil contextInfo:NULL];
        [timeZ setDateValue:[NSDate dateWithTimeIntervalSinceNow:0]];
    }
}

- (void)performCountown:(NSTimer *)_timer
{
#pragma unused (_timer)
    
    --hourZ;
    
    if (hourZ <= 0) {
        [countdownTimer invalidate];
        //[self setShowTimer:NO];
        
        NSString *pathToSound = [[NSBundle mainBundle] pathForResource:@"countdown" ofType:@"wav"];
        NSSound *cSound = [[NSSound alloc] initWithContentsOfFile:pathToSound byReference:YES];
        [cSound play];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"timerStopped" object:nil];
        [mainItem setAction:@selector(showWindow:)];
        return;
    }
    
    if (self.showTimer) {
    
        div_t h = div(hourZ, 3600);
        int hours = h.quot;
    
        div_t m = div(h.rem, 60);
        int minutes = m.quot;
        int seconds = m.rem;
    
        NSString *resultString;
        
        if (hours == 0 && minutes == 0 && seconds <= 10) {
            resultString = [NSString stringWithFormat:@"%ds.", seconds];
        }
        else if (hours == 0 && minutes == 0 && seconds > 10) {
            div_t dec_s = div(seconds, 10);
            int tensOfSeconds = dec_s.quot;
            if (tensOfSeconds+1 == 6)
                resultString = @"1m.";
            else
                resultString = [NSString stringWithFormat:@"%ds.", 10*(tensOfSeconds+1)];
        }
        else if (hours == 0 && minutes > 0) {
            if (minutes+1 == 60)
                resultString = @"1h.";
            else
                resultString = [NSString stringWithFormat:@"%dm.", minutes+1];
        }
        else if (hours > 0) {
            if (minutes+1 == 60)
                resultString = [NSString stringWithFormat:@"%dh.", hours+1];
            else
                resultString = [NSString stringWithFormat:@"%dh. %dm.", hours, minutes+1];
        }
        
        [self setShowedCountdown:resultString];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"yarlyTimer" object:nil];
    }
}

@end
