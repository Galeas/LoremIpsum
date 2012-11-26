//
//  NSMenu+ItemByName.m
//  LoremIpsum
//
//  Created by Akki on 11/23/12.
//
//

#import "NSMenu+ItemByName.h"

@implementation NSMenu (ItemByName)
-(NSMenuItem*)getItemWithPath:(NSString*)path
{
    NSArray* parts =[path componentsSeparatedByString:@"/"];
    NSMenuItem* currentItem =[self itemWithTitle:[parts objectAtIndex:0]];
    if([parts count]==1)
        return currentItem;
    else {
        NSString* newPath =@"";
        for(int i=1; i<[parts count]; i++) {
            newPath =[newPath stringByAppendingString:[parts objectAtIndex:i]];
        }
    return [[currentItem submenu] getItemWithPath:newPath];
    }
}
@end
