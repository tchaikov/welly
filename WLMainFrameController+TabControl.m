//
//  WLMainFrameController+TabControl.m
//  Welly
//
//  Created by K.O.ed on 10-4-30.
//  Copyright 2010 Welly Group. All rights reserved.
//

#import "WLMainFrameController+TabControl.h"

#import "WLTabView.h"
#import "WLConnection.h"
#import "WLSite.h"
#import "WLGlobalConfig.h"

#import <MMTabBarView/MMTabBarView.h>

@interface WLMainFrameController ()

- (void)updateEncodingMenu;
- (void)exitPresentationMode;

@end

@implementation WLMainFrameController (TabControl)

- (void)initializeTabControl {
	// tab control style
    [self.tabBarView setStyleNamed:@"Safari"];
    self.tabBarView.canCloseOnlyTab = YES;
    // show a new-tab button
    self.tabBarView.showAddTabButton = YES;
    // show close button
    self.tabBarView.disableTabClose = NO;
    self.tabBarView.onlyShowCloseOnHover = YES;
    self.tabBarView.hideForSingleTab = NO;
    self.tabBarView.allowsBackgroundTabClosing = YES;
    // the switch
    [self tabViewDidChangeNumberOfTabViewItems:self.tabView];
}

#pragma mark -
#pragma mark Actions
- (IBAction)newTab:(id)sender {
    [self addNewTabToTabView:self.tabView];
}

- (IBAction)selectNextTab:(id)sender {
    
    NSTabViewItem *item = self.tabView.selectedTabViewItem;
    if (!item)
        return;
    if ([self.tabView indexOfTabViewItem:item] == [self.tabView numberOfTabViewItems] - 1) {
        [self.tabView selectFirstTabViewItem:sender];
    } else {
        [self.tabView selectNextTabViewItem:sender];
    }
}

- (IBAction)selectPrevTab:(id)sender {
    NSTabViewItem *item = self.tabView.selectedTabViewItem;
    if (!item)
        return;
    if ([self.tabView indexOfTabViewItem:item] == 0) {
        [self.tabView selectLastTabViewItem:sender];
    } else {
        [self.tabView selectPreviousTabViewItem:sender];
    }
}

- (IBAction)closeTab:(id)sender {
    NSTabViewItem *item = self.tabView.selectedTabViewItem;
    if (!item) return;
	// Here, sometimes it may throw a exception...
	@try {
        if ([self tabView:self.tabView shouldCloseTabViewItem:item]) {
            [self tabView:self.tabView willCloseTabViewItem:item];
            [self.tabView removeTabViewItem:item];
        }
	}
	@catch (NSException * e) {
	}
}

#pragma mark -
#pragma mark MMTabBarViewDelegate

- (void)addNewTabToTabView:(NSTabView *)aTabView {
    // Draw the portal and entering the portal control mode if needed...
    if ([WLGlobalConfig shouldEnableCoverFlow]) {
        [self.tabView newTabWithCoverFlowPortal];
    } else {
        [self newConnectionWithSite:[WLSite site]];
        // let user input
        [_mainWindow makeFirstResponder:_addressBar];
    }
}

- (BOOL)tabView:(NSTabView *)tabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem {
	// Restore from full screen firstly
	[self exitPresentationMode];
	
	// TODO: why not put these in WLTabView?
    if (![[tabViewItem identifier] isConnected])
		return YES;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:WLConfirmOnCloseEnabledKeyName]) 
		return YES;
	
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"Are you sure you want to close this tab?", @"Sheet Title");
    alert.informativeText = NSLocalizedString(@"The connection is still alive. If you close this tab, the connection will be lost. Do you want to close this tab anyway?", @"Sheet Message");
    [alert addButtonWithTitle:NSLocalizedString(@"Close", @"Default Button")];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel Button")];
    return ([alert runModal] == NSAlertFirstButtonReturn);
}

- (void)tabView:(NSTabView *)tabView willCloseTabViewItem:(NSTabViewItem *)tabViewItem {
    // close the connection
	if ([[tabViewItem identifier] isKindOfClass:[WLConnection class]])
		[[tabViewItem identifier] close];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    NSAssert(tabView == self.tabView, @"tabView");
	[_addressBar setStringValue:@""];
    id identifier = [tabViewItem identifier];
	if ([identifier isKindOfClass:[WLConnection class]]) {
		WLConnection *connection = identifier;
		WLSite *site = [connection site];
		if (connection && [site address]) {
			[_addressBar setStringValue:[site address]];
			[connection resetMessageCount];
		}
		
		[_mainWindow makeFirstResponder:tabView];
		
		[self updateEncodingMenu];
#define CELLSTATE(x) ((x) ? NSOnState : NSOffState)
		[_detectDoubleByteButton setState:CELLSTATE([site shouldDetectDoubleByte])];
		[_detectDoubleByteMenuItem setState:CELLSTATE([site shouldDetectDoubleByte])];
		[_autoReplyButton setState:CELLSTATE([site shouldAutoReply])];
		[_autoReplyMenuItem setState:CELLSTATE([site shouldAutoReply])];
		[_mouseButton setState:CELLSTATE([site shouldEnableMouse])];
#undef CELLSTATE
	}
}

- (void)tabViewDidChangeNumberOfTabViewItems:(NSTabView *)tabView {
    // all tab closed, no didSelectTabViewItem will happen
    if ([tabView numberOfTabViewItems] == 0) {
        if ([WLGlobalConfig shouldEnableCoverFlow]) {
            [_mainWindow makeFirstResponder:tabView];
        } else {
            [_mainWindow makeFirstResponder:_addressBar];
        }
    }
}

@end
