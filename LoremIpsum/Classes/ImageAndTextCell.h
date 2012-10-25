//
//  ImageAndTextCell.h
//  PHPEdit
//
//  Created by Akki on 2/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ImageAndTextCell : NSTextFieldCell
{
@private
	NSImage *image;
}

- (void)setImage:(NSImage *)anImage;
- (NSImage *)image;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (NSSize)cellSize;
@end
