//
//  LIDocumentCOntroller.m
//  LoremIpsum
//
//  Created by Akki on 6/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LIDocumentController.h"
#import "LIDocWindowController.h"
#import "LIDocument.h"

@implementation LIDocumentController

@synthesize manualCreation = manualCreation;
@synthesize manualFormat = manualFormat;

- (NSString *)defaultType
{
    if (self.manualCreation) {
        [self setManualCreation:NO];
        return (NSString*)([self.manualFormat isEqualToString:RTF] ? kUTTypeRTF : kUTTypePlainText);
    }
    return (NSString*)([[[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LIInitSettings.docType"] isEqualToString:RTF] ? kUTTypeRTF : kUTTypePlainText);
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([menuItem action] == @selector(manualNewDocument:)) {
        if ([[menuItem title] isEqualToString:[[NSUserDefaults standardUserDefaults] valueForKeyPath:@"LIInitSettings.docType"]]) {
            [menuItem setKeyEquivalent:@"n"];
            [menuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
            return YES;
        }
        else {
            [menuItem setKeyEquivalent:@""];
            return YES;
        }
    }
    
    return YES;
}

- (IBAction)manualNewDocument:(id)sender
{
    [self setManualCreation:YES];
    [self setManualFormat:[sender title]];
    [self newDocument:self];
}

@end
