//
//  ESSImageCategory.m
//
//  Created by Matthias Gansrigler on 1/24/07.
//  Copyright 2007 Eternal Storms Software. All rights reserved.
//

#import "ESSImageCategory.h"

@implementation NSImage (ESSImageCategory)

- (NSData* )representationForFileType: (NSBitmapImageFileType) fileType 
{
	NSData *temp = [self TIFFRepresentation];
	NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:temp];
	NSData *imgData = [bitmap representationUsingType:fileType properties:nil];
	return imgData;
}

- (NSData *)JPEGRepresentation
{
	return [self representationForFileType: NSJPEGFileType];
}

- (NSData *)PNGRepresentation
{
	return [self representationForFileType: NSPNGFileType];
}

- (NSData *)JPEG2000Representation
{
	return [self representationForFileType: NSJPEG2000FileType];	
}

- (NSData *)GIFRepresentation
{
	return [self representationForFileType: NSGIFFileType];	
}

- (NSData *)BMPRepresentation
{
	return [self representationForFileType: NSBMPFileType];		
}

- (NSData *)dataForPboardType:(NSString *)pboardtype
{
	NSPasteboard *pboard = nil;
	pboard = [NSPasteboard pasteboardWithName:@"essimagecategory"];
	[pboard declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:nil];
	[pboard setData:[self TIFFRepresentation] forType:NSTIFFPboardType];
	[pboard types];
	NSData *data = [pboard dataForType:pboardtype];
	[pboard releaseGlobally];
	return data;
}

- (NSData *)PDFRepresentation
{
	return [self dataForPboardType:NSPDFPboardType];
}

- (CIImage *)CIImage
{
	CIImage *cimg = [[CIImage alloc] initWithData:[self TIFFRepresentation]];
	return cimg;
}

@end

@implementation CIImage (ESSImageCategory)

- (NSImage *)NSImage
{
	NSImage *img = [[NSImage alloc] initWithSize:NSMakeSize([self extent].size.width,[self extent].size.height)];
	NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:self];
	[img addRepresentation:rep];
	return img;
}

- (NSData *)TIFFRepresentation
{
	return [[self NSImage] TIFFRepresentation];
}

@end
