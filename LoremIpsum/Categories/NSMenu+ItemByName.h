//
//  NSMenu+ItemByName.h
//  LoremIpsum
//
//  Created by Akki on 11/23/12.
//
//

#import <Cocoa/Cocoa.h>

@interface NSMenu (ItemByName)
-(NSMenuItem*)getItemWithPath:(NSString*)path;
@end
