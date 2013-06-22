//
//  WLAutoReplyDelegate.m
//  MacBlueTelnet
//
//  Created by K.O.ed on 08-3-28.
//  Copyright 2008 net9.org. All rights reserved.
//


#import "WLMessageDelegate.h"
#import "WLConnection.h"
#import "WLSite.h"
#import "WLTabView.h"
#import "WLMainFrameController.h"
#import "WLGrowlBridge.h"

NSString *const WLAutoReplyGrowlTipFormat = @"AutoReplyGrowlTipFormat";

NSString *const WLNotificationNameFileTransfer = @"File Transfer";
NSString *const WLNotificationNameEXIFInformation = @"EXIF Information";
NSString *const WLNotificationNameNewMessageReceived = @"New Message Received";


@implementation WLMessageDelegate
@synthesize unreadCount = _unreadCount;

- (instancetype)init {
	if (self = [super init]) {
		_unreadMessage = [[NSMutableString alloc] initWithCapacity:400];
		[_unreadMessage setString:@""];
		_unreadCount = 0;
        _ncenter = [NSUserNotificationCenter defaultUserNotificationCenter];
        _ncenter.delegate = self;
	}
	return self;
}

- (void)connection:(WLConnection *)connection
 didReceiveMessage:(NSString *)message
        fromCaller:(NSString *)callerName {
	if (connection.site.shouldAutoReply) {
		// enclose the autoReplyString with two '\r'
		NSString *aString = [NSString stringWithFormat:@"\r%@\r", connection.site.autoReplyString];
		
		// send to the connection
		[connection sendText:aString];
		
		// now record this message
		[_unreadMessage appendFormat:@"%@\r%@\r\r", callerName, message];
		_unreadCount++;
	}

	WLTabView *view = [[WLMainFrameController sharedInstance] tabView];
    if ([NSApp isActive] &&
        connection == view.frontMostConnection &&
        !connection.site.shouldAutoReply) {
        return;
    }
    // not in focus
    [connection increaseMessageCount:1];
    NSString *description;
    // notify auto replied
    if (connection.site.shouldAutoReply) {
        description = [NSString stringWithFormat:NSLocalizedString(WLAutoReplyGrowlTipFormat, @"Auto Reply"), message];
    } else {
        description = message;
    }
    
    // should invoke growl notification
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = callerName;
    notification.subtitle = NSLocalizedString(WLNotificationNameNewMessageReceived, @"Notification Name");
    notification.hasActionButton = YES;
    notification.informativeText = description;
    notification.soundName = NSUserNotificationDefaultSoundName;
    notification.userInfo = @{@"connection": @((NSUInteger)connection)};
    [_ncenter deliverNotification:notification];
}

- (void)showUnreadMessagesOnTextView:(NSTextView *)textView {
	textView.window.title = [NSString stringWithFormat:NSLocalizedString(@"MessageWindowTitle", @"Auto Reply"), _unreadCount];
	textView.string = _unreadMessage;
	textView.textColor = [NSColor whiteColor];
    _unreadMessage.string = @"";
	_unreadCount = 0;
}

#pragma mark -
#pragma mark NSUserNotificationCenterDelegate

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification {
}
- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    // bring the window to front
    [NSApp activateIgnoringOtherApps:YES];
	
	WLTabView *view = [WLMainFrameController sharedInstance].tabView;
    [view.window makeKeyAndOrderFront:nil];
    // select the tab
    id connection = (id)notification.userInfo[@"connection"];
    NSInteger index = [view indexOfTabViewItemWithIdentifier:connection];
    if (index == NSNotFound) {
        // the tab emited the notification is gone.
        return;
    }
    [view selectTabViewItemAtIndex:index];
}

@end
