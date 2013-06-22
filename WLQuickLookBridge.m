//
//  XIQuickLookBridge.m
//  Preview via Quick Look
//
//  Created by boost @ 9# on 7/11/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import "WLQuickLookBridge.h"
#import "DownloadItem.h"

@interface WLQuickLookBridge (WLQuickLookBridgeSingleton)
+ (WLQuickLookBridge *)sharedInstance;
@end

@interface QLPreviewPanelController : NSWindowController
@property(readonly) QLPreviewView *previewView;
@property(retain) QLPreviewView *sharedPreviewView; 
@end

@implementation WLQuickLookBridge

static BOOL isLeopard;
static BOOL isLion;

+ (WLQuickLookBridge *)sharedInstance {
    static WLQuickLookBridge *instance = nil;
    if (instance == nil) {
        instance = [WLQuickLookBridge new];
    }
    return instance;
}

+ (void)initialize {
    isLeopard = (NSAppKitVersionNumber >= NSAppKitVersionNumber10_6);
    isLion = (NSAppKitVersionNumber >= NSAppKitVersionNumber10_7);
}

- (instancetype)init {
	if (self = [super init]) {
		_downloads = [NSMutableArray array];
        _currentItemIndex = -1;
		// To deal with full screen window level
		// Modified by gtCarrera
		//[_panel setLevel:kCGStatusWindowLevel+1];
		// End
	}
    return self;
}

- (void)showPreviewPanel {
    if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
        return;
    }
    _previewPanel = [QLPreviewPanel sharedPreviewPanel];
    [_previewPanel makeKeyAndOrderFront:nil];
}

#pragma mark -
#pragma mark QLPreviewPanelDelegate

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event
{
    if ([event type] == NSKeyDown) {
        return YES;
    }
    return NO;
}

// This delegate method provides the rect on screen from which the panel will zoom.
- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item
{
    NSInteger index = [_downloads indexOfObject:item];
    if (index == NSNotFound) {
        return NSZeroRect;
    }
    NSRect frame;
    frame.origin = [NSEvent mouseLocation];
    frame.size.width = 1;
    frame.size.height = 1;
    return frame;
}

// This delegate method provides a transition image between the table view and the preview panel
- (id)previewPanel:(QLPreviewPanel *)panel transitionImageForPreviewItem:(id <QLPreviewItem>)item contentRect:(NSRect *)contentRect
{
    DownloadItem* downloadItem = (DownloadItem *)item;
    return downloadItem.iconImage;
}

+ (NSMutableArray *)URLs {
    return [self sharedInstance]->_downloads;
}

//+ (QLPreviewPanel *)Panel {
//    return [self sharedInstance]->_previewPanel;
//}

- (void)addDownload:(DownloadItem *)item {
    // check if the url is already under preview
    __block NSInteger previewItemIndex = -1;
    [_downloads enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DownloadItem *it = obj;
        if ([it.originalURL isEqual:item.originalURL]) {
            previewItemIndex = idx;
            *stop = YES;
        }
    }];
    if (previewItemIndex < 0) {
        previewItemIndex = _downloads.count;
        [_downloads addObject:item];
    }
    _currentItemIndex = previewItemIndex;
    
    if (_previewPanel) {
        [self updatePreviewItem];
    }
}

- (void)updatePreviewItem {
    _previewPanel.currentPreviewItemIndex = _currentItemIndex;
    [_previewPanel reloadData];
    [_previewPanel makeKeyAndOrderFront:nil];
}

/*
+ (void)removeAll {
    [[self URLs] removeAllObjects];
    [[self sharedPanel] close];
    // we don't call setURLs here
}*/

#pragma mark -
#pragma mark QLPreviewPanelDataSource protocol

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel {
    return _downloads.count;
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index {
    return _downloads[index];
}

@end
