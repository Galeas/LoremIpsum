//
//  LIDocumentCOntroller.h
//  LoremIpsum
//
//  Created by Akki on 6/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LIDocumentController : NSDocumentController
{
    BOOL manualCreation;
    NSString *manualFormat;
}

@property BOOL manualCreation;
@property NSString *manualFormat;

- (IBAction)manualNewDocument:(id)sender;
@end
