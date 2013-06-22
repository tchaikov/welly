//
//  WLTerminalView+QuickLook.m
//  Welly
//
//  Created by Kefu Chai on 6/23/13.
//  Copyright (c) 2013 Welly Group. All rights reserved.
//

#import "WLTerminalView+QuickLook.h"
#import <Quartz/Quartz.h>

#import "WLQuickLookBridge.h"

@implementation WLTerminalView (QuickLook)

#pragma mark -
#pragma mark QLPreviewPanelController

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel {
    return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel {
    // This document is now responsible of the preview panel
    // It is allowed to set the delegate, data source and refresh panel.
    WLQuickLookBridge *quickLook = [WLQuickLookBridge sharedInstance];
    quickLook.previewPanel = panel;
    panel.delegate = quickLook;
    panel.dataSource = quickLook;
    [quickLook updatePreviewItem];
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel {
    // This bridge loses its responsisibility on the preview panel
    // Until the next call to -beginPreviewPanelControl: it must not
    // change the panel's delegate, data source or refresh it.
    WLQuickLookBridge *quickLook = [WLQuickLookBridge sharedInstance];
    quickLook.previewPanel = nil;
}

@end
