//
//  WLPrefsWindowController.h
//  Welly
//
//  Created by Kefu Chai on 6/27/13.
//  Copyright (c) 2013 Welly Group. All rights reserved.
//

#import "DBPrefsWindowController.h"

@interface WLPrefsWindowController : DBPrefsWindowController {
    IBOutlet NSPopUpButton *_telnetPopUpButton;
    IBOutlet NSPopUpButton *_sshPopUpButton;
}

@property (strong, nonatomic) IBOutlet NSView *generalPrefView;
@property (strong, nonatomic) IBOutlet NSView *connectionPrefView;
@property (strong, nonatomic) IBOutlet NSView *fontsPrefView;
@property (strong, nonatomic) IBOutlet NSView *colorsPrefView;
@property (strong, nonatomic) IBOutlet NSView *autoReplyPrefView;


- (IBAction) setChineseFont: (id) sender;
- (IBAction) setEnglishFont: (id) sender;
- (IBAction) setDefaultTelnetClient: (id) sender;
- (IBAction) setDefaultSSHClient: (id) sender;

@end
