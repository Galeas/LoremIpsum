//
//  ESSImageCategory.h
//
//  Created by Matthias Gansrigler on 1/24/07.
//  Copyright 2007 Eternal Storms Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//The QuartzCore.framework needs to be added to your project in order for CIImage / NSImage conversions to work
#import <QuartzCore/QuartzCore.h>

@interface NSImage (ESSImageCategory)
- (NSData *)JPEGRepresentation;
- (NSData *)JPEG2000Representation;
- (NSData *)PNGRepresentation;
- (NSData *)GIFRepresentation;
- (NSData *)BMPRepresentation;
- (NSData *)PDFRepresentation;
- (CIImage *)CIImage; //convert NSImage to CIImage

//internal stuff
- (NSData *)dataForPboardType:(NSString *)pboardtype;
- (NSData* )representationForFileType: (NSBitmapImageFileType) fileType ;
@end

@interface CIImage (ESSImageCategory)
- (NSImage *)NSImage; //Convert CIImage to NSImage
- (NSData *)TIFFRepresentation; //just for convenience
@end
