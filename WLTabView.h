//
//  WLTabView.h
//  Welly
//
//  Created by K.O.ed on 10-4-20.
//  Copyright 2010 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLSitesPanelController.h"

@class WLTerminalView;
@class WLCoverFlowPortal;
@class WLConnection;
@class WLTerminal;
@class MMTabBarView;

@protocol WLTabItemContentObserver

- (void)didChangeContent:(id)content;

@end


@interface WLTabView : NSTabView <WLSitesObserver> {
	NSView *_frontMostView;
	NSArray *_tabViews;
	
	WLCoverFlowPortal *_portal;
}

@property (readonly) NSView *frontMostView;
@property (readonly) WLConnection *frontMostConnection;
@property (readonly) WLTerminal *frontMostTerminal;
@property (nonatomic, weak) IBOutlet WLTerminalView *terminalView;
@property (nonatomic, weak) IBOutlet NSTabView *tabBarView;



// for Font size
- (IBAction)increaseFontSize:(id)sender;
- (IBAction)decreaseFontSize:(id)sender;

- (void)newTabWithConnection:(WLConnection *)theConnection 
					   label:(NSString *)theLabel;
- (void)newTabWithCoverFlowPortal;


@end
