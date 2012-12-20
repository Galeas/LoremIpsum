//
//  NSColor+Hex.m
//  PHPEdit
//
//  Created by Akki on 4/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSColor+Hex.h"

@implementation NSColor (Hex)

- (NSString *) hexColor {
    float r, g, b;
    
    if ([[self colorSpaceName] isEqualToString:NSCalibratedWhiteColorSpace]) {
        r = [self whiteComponent];
        g = [self whiteComponent];
        b = [self whiteComponent];
    }

    else if ([[self colorSpaceName] isEqualToString:NSCalibratedRGBColorSpace]
             || [[self colorSpaceName] isEqualToString:NSDeviceRGBColorSpace]) {
        r = [self redComponent];
        g = [self greenComponent];
        b = [self blueComponent];
        
    } else {
        return @"transparent";
    }
    return [NSString stringWithFormat:@"#%0.2X%0.2X%0.2X",
            (int)(r * 255),
            (int)(g * 255),
            (int)(b * 255)];
}

- (int)intColor {
    
    uint8_t r = (uint32_t)(MIN(1.0f, MAX(0.0f, [self redComponent])) * 0xff);
    uint8_t g = (uint32_t)(MIN(1.0f, MAX(0.0f, [self greenComponent])) * 0xff);
    uint8_t b = (uint32_t)(MIN(1.0f, MAX(0.0f, [self blueComponent])) * 0xff);
    uint8_t alfa = (uint32_t)(MIN(1.0f, MAX(0.0f, [self alphaComponent])) * 0xff);
    
    int value = (alfa << 24) | (b<< 16) | (g << 8) | r;
    
    return value;
}

+ (NSColor *) colorWithHex:(NSString *)hexColor {
    
    // Remove the hash if it exists
    hexColor = [hexColor stringByReplacingOccurrencesOfString:@"#" withString:@""];
    int length = (int)[hexColor length];
    bool triple = (length == 3);
    
    NSMutableArray *rgb = [[NSMutableArray alloc] init];
    
    // Make sure the string is three or six characters long
    if (triple || length == 6) {
        
        CFIndex i = 0;
        UniChar character = 0;
        NSString *segment = @"";
        CFStringInlineBuffer buffer;
        CFStringInitInlineBuffer((__bridge CFStringRef)hexColor, &buffer, CFRangeMake(0, length));
        
        
        while ((character = CFStringGetCharacterFromInlineBuffer(&buffer, i)) != 0 ) {
            if (triple) segment = [segment stringByAppendingFormat:@"%c%c", character, character];
            else segment = [segment stringByAppendingFormat:@"%c", character];
            
            if ((int)[segment length] == 2) {
                NSScanner *scanner = [[NSScanner alloc] initWithString:segment];
                
                unsigned number;
                
                while([scanner scanHexInt:&number]){
                    [rgb addObject:[NSNumber numberWithFloat:(float)(number / (float)255)]];
                }
                segment = @"";
            }
            
            i++;
        }
        
        // Pad the array out (for cases where we're given invalid input)
        while ([rgb count] != 3) [rgb addObject:[NSNumber numberWithFloat:0.0]];
        
        NSColor *resultColor = [NSColor colorWithCalibratedRed:[[rgb objectAtIndex:0] floatValue]
                                                         green:[[rgb objectAtIndex:1] floatValue]
                                                          blue:[[rgb objectAtIndex:2] floatValue]
                                                         alpha:1];    
        return resultColor;
    }
    else {
        NSException* invalidHexException = [NSException exceptionWithName:@"InvalidHexException"
                                                                   reason:@"Hex color not three or six characters excluding hash"                                    
                                                                 userInfo:nil];
        @throw invalidHexException;
        
    }
    
}

- (NSColor *)invertedColor
{
    float r, g, b, alfa;
    
    if ([[self colorSpaceName] isEqualToString:NSCalibratedRGBColorSpace] || [[self colorSpaceName] isEqualToString:NSDeviceRGBColorSpace]) {
        r = [self redComponent];
        g = [self greenComponent];
        b = [self blueComponent];
        alfa = [self alphaComponent];
    } else
        return nil;
    return [NSColor colorWithCalibratedRed:1-r green:1-g blue:1-b alpha:alfa];
}

- (CGColorRef)coreGraphicsColorWithAlfa:(CGFloat)alfa
{
    CGColorSpaceRef colorspaceRef = CGColorSpaceCreateDeviceRGB();
    NSColor *deviceColor = [self colorUsingColorSpaceName:NSDeviceRGBColorSpace];
    CGFloat components[4];
    
    [deviceColor getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];
    components[3] = alfa;
    CGColorRef colorRef = CGColorCreate(colorspaceRef, components);
    CGColorSpaceRelease(colorspaceRef);
    
    return colorRef;
}

@end
