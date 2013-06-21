//
//  WLPortalItem.h
//  Welly
//
//  Created by K.O.ed on 10-4-17.
//  Copyright 2010 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol WLPortalSource

- (NSImage *)image;
- (void)didSelect:(id)sender;

@end

@protocol WLDraggingSource

- (BOOL)acceptsDragging;
- (NSImage *)draggingImage;
- (NSPasteboard *)draggingPasteboard;
- (void)draggedToRemove:(id)sender;

@end

@protocol WLPasteboardReceiver

- (BOOL)acceptsPBoard:(NSPasteboard *)pboard;
- (BOOL)didReceivePBoard:(NSPasteboard *)pboard;

@end



@interface WLPortalItem : NSObject <WLPortalSource> {
    NSString *_title;
    NSImage  *_image;
}

@property (readonly) NSImage *image;

- (instancetype)initWithTitle:(NSString *)title;
- (instancetype)initWithImage:(NSImage *)theImage;
- (instancetype)initWithImage:(NSImage *)theImage title:(NSString *)title;

#pragma mark -
#pragma mark IKImageBrowserItem protocol
- (NSString *)imageUID;
- (NSString *)imageRepresentationType;
- (id)imageRepresentation;

#pragma mark -
#pragma mark WLPortalSource protocol
- (void)didSelect:(id)sender;
@end
