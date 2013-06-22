//
//  XIQuickLookBridge.h
//  Preview via Quick Look
//
//  Created by boost @ 9# on 7/11/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
// Quartz framework provides the QLPreviewPanel public API
#import <Quartz/Quartz.h>

@class DownloadItem;
@class QLPreviewPanel;

@interface WLQuickLookBridge : NSObject <QLPreviewPanelDataSource, QLPreviewPanelDelegate> {
    NSMutableArray* _downloads;
    NSInteger _currentItemIndex;
}

+ (WLQuickLookBridge *)sharedInstance;
- (void)addDownload:(DownloadItem *)item;
- (void)showPreviewPanel;
- (void)updatePreviewItem;

@property (weak) QLPreviewPanel *previewPanel;

@end
