//
//  WLAutoReplyDelegate.h
//  MacBlueTelnet
//
//  Created by K.O.ed on 08-3-28.
//  Copyright 2008 9# Dept. Water. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"

@class WLConnection;

@interface WLMessageDelegate : NSObject<NSUserNotificationCenterDelegate> {
	NSMutableString *_unreadMessage;
    NSUserNotificationCenter *_ncenter;
}

@property (readonly) NSUInteger unreadCount;

- (void)connection:(WLConnection *)connection
 didReceiveMessage:(NSString *)message
        fromCaller:(NSString *)callerName;
- (void)showUnreadMessagesOnTextView:(NSTextView *)textView;
@end