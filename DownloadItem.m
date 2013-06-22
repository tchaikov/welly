//
//  DownloadItem.m
//  Welly
//
//  Created by Kefu Chai on 6/22/13.
//  Copyright (c) 2013 Welly Group. All rights reserved.
//

#import "DownloadItem.h"

#define ICON_SIZE 72.0

static NSOperationQueue* downloadIconQueue = nil;
static NSDictionary* quickLookOptions = nil;

static NSString *WLGIFToHTMLFormat = @"<html><body bgcolor='Black'><center><img scalefit='1' style='position: absolute; top: 0; right: 0; bottom: 0; left: 0; height:100%%; margin: auto;' src='%@'></img></center></body></html>";

@implementation DownloadItem


- (instancetype)initWithPath:(NSString *)path
                         URL:(NSURL *)URL {
    if (self = [super init]) {
        if ([path.pathExtension isEqualToString:@"gif"]) {
            _resolvedFileURL = [NSURL fileURLWithPath:[[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"html"]];
            [[NSString stringWithFormat:WLGIFToHTMLFormat, [NSURL fileURLWithPath:path]] writeToURL:_resolvedFileURL atomically:NO encoding: NSUTF8StringEncoding error:NULL];
        } else {
            _resolvedFileURL = [NSURL fileURLWithPath:path];
        }
        _originalURL = URL;
    }
    return self;
}

- (NSImage *)iconImage
{
    if (_iconImage == nil) {
        _iconImage = [[NSWorkspace sharedWorkspace] iconForFile:[_resolvedFileURL path]];
        [_iconImage setSize:NSMakeSize(ICON_SIZE, ICON_SIZE)];
        if (!downloadIconQueue) {
            downloadIconQueue = [[NSOperationQueue alloc] init];
            [downloadIconQueue setMaxConcurrentOperationCount:2];
            quickLookOptions = @{@(TRUE): (__bridge NSString *)kQLThumbnailOptionIconModeKey};
        }
        [downloadIconQueue addOperationWithBlock:^{
            CGImageRef quickLookIcon =
                QLThumbnailImageCreate(NULL,
                                       (__bridge CFURLRef)_resolvedFileURL,
                                       CGSizeMake(ICON_SIZE, ICON_SIZE),
                                       (__bridge CFDictionaryRef)quickLookOptions);
            if (quickLookIcon != NULL) {
                NSImage* betterIcon = [[NSImage alloc] initWithCGImage:quickLookIcon size:NSMakeSize(ICON_SIZE, ICON_SIZE)];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.iconImage = betterIcon;
                });
                CFRelease(quickLookIcon);
            }
        }];
    }
    return _iconImage;
}

#pragma mark -
#pragma mark QLPreviewItem

- (NSURL *)previewItemURL {
    return _resolvedFileURL;
}

- (NSString *)previewItemTitle
{
    return [_originalURL absoluteString];
}

@end
