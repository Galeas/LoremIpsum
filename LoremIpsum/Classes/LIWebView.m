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
#import "LISettingsProxy.h"

@implementation LIWebView

- (void)draggingEnded:(id<NSDraggingInfo>)sender
{
    if ([[[sender draggingPasteboard] types] containsObject:NSURLPboardType]) {
        NSURL *cssURL = [NSURL URLFromPasteboard:[sender draggingPasteboard]];
        if ([[cssURL pathExtension] isEqualToString:@"css"] || [[cssURL pathExtension] isEqualToString:@"CSS"]) {
            
            //[SharedDefaultsController setValue:[cssURL path] forKeyPath:@"values.customCSS"];
            //[SharedDefaultsController setValue:[NSNumber numberWithBool:YES] forKeyPath:@"values.useCustomCSS"];
            [[LISettingsProxy proxy] setValue:[cssURL path] forSettingName:@"customCSS"];
            [[LISettingsProxy proxy] setValue:[NSNumber numberWithBool:YES] forSettingName:@"useCustomCSS"];
        }
    }
}

@end
