//
//  WLPortalItem.m
//  Welly
//
//  Created by K.O.ed on 10-4-17.
//  Copyright 2010 Welly Group. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "WLPortalItem.h"

static NSImage *default_image;

@implementation WLPortalItem

#pragma mark -
#pragma mark Initialize

- (instancetype)initWithTitle:(NSString *)title {
	if (self = [super init]) {
		_title = [title copy];
	}
	return self;
}

- (instancetype)initWithImage:(NSImage *)theImage{
	if (self = [super init]) {
		_image = theImage;
	}
	return self;
}

- (instancetype)initWithImage:(NSImage *)theImage
                        title:(NSString *)title {
	if (self = [super init]) {
		_image = theImage;
		_title = [title copy];
	}
	return self;
}


#pragma mark -
#pragma mark IKImageBrowserItem protocol
- (NSString *)imageUID {
    return _title;
}

- (NSString *)imageRepresentationType {
    return IKImageBrowserNSImageRepresentationType;
}

- (id)imageRepresentation {
    if (_image == nil) {
        if (default_image == nil)
            default_image = [NSImage imageNamed:@"default_site.png"];
        return default_image;
    }
    return _image;
}

#pragma mark -
#pragma mark WLPortalSource protocol
- (void)didSelect:(id)sender {
	// DO NOTHING
}
@end
