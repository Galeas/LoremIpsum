//
//  TADocument.h
//  TextArtist
//
//  Created by Akki on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//#define SharedDefaultsController [NSUserDefaultsController sharedUserDefaultsController]
#define RTF @"Rich Format Text"
#define TXT @"Markdown (Plain Text)"

enum {
    LIStraitText = 0,
    LIMediumText = 1,
    LIWideText = 2
};
typedef NSUInteger LITextWidth;

@interface LIDocument : NSDocument
{    
    // Book-keeping
    BOOL setUpPrintInfoDefaults;	/* YES когда -printInfo вызвана впервые */
    BOOL inDuplicate;
    
    // Document data
    NSTextStorage *_textStorage;                         /* Тектовое хранилище */
    CGFloat _scaleFactor;                                /* Масштаб из файла */
    BOOL _isReadOnly;                                    /* Документ заблокирован */
    NSColor *_backgroundColor;                           /* Задний фон документа */
    //CGFloat hyphenationFactor;                         /* Hyphenation factor in range 0.0-1.0 */
    NSSize _viewSize;                                    /* Размер вьюхи, хранится для RTF. Может быть NSZeroSize */
    BOOL _hasMultiplePages;                              /* Многостраничный ли документ? */

    NSTextAlignment _aTextAlignment;

    
    // Только для RTF
    NSString *_author;                                   /* Значение NSAuthorDocumentAttribute */
    NSString *_copyright;                                /* Значение NSCopyrightDocumentAttribute */
    NSString *_company;                                  /* Значение NSCompanyDocumentAttribute */
    NSString *_title;                                    /* Значение NSTitleDocumentAttribute */
    NSString *_subject;                                  /* Значение NSSubjectDocumentAttribute */
    NSString *_comment;                                  /* Значение NSCommentDocumentAttribute */
    NSArray  *_keywords;                                 /* Значение NSKeywordsDocumentAttribute */
    
    // Информация о создании документа
    BOOL openedIgnoringRichText;                        /* Setting at the the time the doc was open (so revert does the same thing) */
    NSStringEncoding documentEncoding;                  /* NSStringEncoding used to interpret / save the document */
    BOOL convertedDocument;                             /* Converted (or filtered) from some other format (and hence not writable) */
    BOOL lossyDocument;                                 /* Loaded lossily, so might not be a good idea to overwrite */
    BOOL transient;                                     /* Untitled document automatically opened and never modified */
    NSArray *originalOrientationSections;               /* An array of dictionaries. Each describing the text layout orientation for a page */
    
    // Временная информация о сохранении документа
    NSStringEncoding documentEncodingForSaving;         /* NSStringEncoding для сохранения документа */
    NSSaveOperationType currentSaveOperation;           /* Узнаем, что нужно использовать - documentEncodingForSaving или documentEncoding - в -fileWrapperOfType:error: */
    NSLock *saveOperationTypeLock;                      /* Атомарная блокировка документа при сохранении */
    
    
    // Временная информация о типе документа
    NSString *fileTypeToSet;
}

@property NSTextStorage *textStorage;
@property NSString *docType;
@property NSDictionary *typingAttribs;

- (NSFont*)textFont;
- (NSFont*)docFont:(NSDictionary*)fontDescription;
- (NSFileWrapper*)fileWrapperWithIdentifier:(NSString*)identifier;
- (void)parseTextOfType:(NSString*)type forBookmarks:(NSTextStorage*)aStorage;
- (void)makeWindowControllersManual:(BOOL)manual;

- (NSView*)printableView;
@end
