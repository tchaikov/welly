//
//  DownloadItem.h
//  Welly
//
//  Created by Kefu Chai on 6/22/13.
//  Copyright (c) 2013 Welly Group. All rights reserved.
//

#import <Quartz/Quartz.h>

@interface DownloadItem : NSObject<QLPreviewItem> {
    NSURL* _resolvedFileURL;
    NSImage* _iconImage;
}

- (instancetype)initWithPath:(NSString *)path
                         URL:(NSURL *)URL;
@property(strong, nonatomic) NSImage* iconImage;
@property(strong) NSURL* originalURL;

@end
