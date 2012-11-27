//
//  LIBookmarxController.h
//  LoremIpsum
//
//  Created by Akki on 6/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LITableView;
@interface LIBookmarxController : NSWindowController <NSTableViewDelegate>
{
@private
    __weak LITableView *bookmarxTable;
    NSMutableArray *bookmarxDataSource;
    NSArrayController *bArrayController;
}

+ (LIBookmarxController*) bookmarxController;
- (IBAction)closeSheet:(id)sender;

- (void)bookmarkDoubleClick;
- (void)updateSheetFrame;
- (void)reloadDataSource;
- (NSDictionary*)bookmarkData:(NSUInteger)bookmarkLocation;

@property (weak) IBOutlet NSTableView *bookmarxTable;
@property (copy) NSMutableArray *bookmarxDataSource;
@property (strong) IBOutlet NSArrayController *bArrayController;
@end
