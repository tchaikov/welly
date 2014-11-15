//
//  WLTabViewItemObjectController.m
//  Welly
//
//  Created by K.O.ed on 10-4-30.
//  Copyright 2010 Welly Group. All rights reserved.
//

#import "WLTabViewItemController.h"

@implementation WLEmptyTabBarItem

- (BOOL)isConnected {
    return NO;
}

#pragma mark MMTabBarItem

- (BOOL)hasCloseButton {
    return YES;
}

@end

