//
//  XIIntegerArray.m
//  Welly
//
//  Created by boost on 7/28/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import "WLIntegerArray.h"


@implementation WLIntegerArray

+ (instancetype)integerArray {
    return [[WLIntegerArray alloc] init];
}

- (instancetype)init {
    if (self = [super init]) {
        _array = [NSMutableArray array];
    }
    return self;
}


- (void)push_back:(NSInteger)integer {
    [_array addObject:@(integer)];
}

- (void)pop_front {
    [_array removeObjectAtIndex:0];
}

- (NSInteger)at:(NSUInteger)index {
    return [_array[index] integerValue];
}

- (void)set:(NSInteger)value at:(NSUInteger)index {
    _array[index] = @(value);
}

- (NSInteger)front {
    return [self at:0];
}

- (BOOL)empty {
    return [_array count] == 0;
}

- (NSUInteger)size {
    return [_array count];
}

- (void)clear {
    [_array removeAllObjects];
}

@end
