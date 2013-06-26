//
//  WLPrefsWindowController.m
//  Welly
//
//  Created by Kefu Chai on 6/27/13.
//  Copyright (c) 2013 Welly Group. All rights reserved.
//

#import "WLPrefsWindowController.h"
#import "WLGlobalConfig.h"
#import <AppKit/NSFontPanel.h>

@implementation WLPrefsWindowController

+ (NSArray *)applicationIdentifierArrayForURLScheme: (NSString *) scheme {
    CFArrayRef array = LSCopyAllHandlersForURLScheme((__bridge CFStringRef)scheme);
    NSMutableArray *result = [NSMutableArray arrayWithArray: (__bridge NSArray *) array];
    CFRelease(array);
    return result;
}

- (void)setupMenuOfURLScheme:(NSString *)scheme
                         forPopUpButton:(NSPopUpButton *)button {
    NSString *wellyIdentifier = [[[NSBundle mainBundle] bundleIdentifier] lowercaseString];
    NSMutableArray *array = [NSMutableArray arrayWithArray: [WLPrefsWindowController applicationIdentifierArrayForURLScheme: scheme]];
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSMutableArray *menuItems = [NSMutableArray array];

    int wellyCount = 0;
    for (NSString *appId in array)
        if ([[appId lowercaseString] isEqualToString: wellyIdentifier])
            wellyCount++;
    if (wellyCount == 0)
        [array addObject: [[NSBundle mainBundle] bundleIdentifier]];

    for (NSString *appId in array) {
        CFStringRef appNameInCFString;
        NSString *appPath = [ws absolutePathForAppBundleWithIdentifier: appId];
        if (appPath) {
            NSURL *appURL = [NSURL fileURLWithPath: appPath];
            if (LSCopyDisplayNameForURL((__bridge CFURLRef)appURL, &appNameInCFString) == noErr) {
                NSString *appName = [NSString stringWithString: (__bridge NSString *) appNameInCFString];
                CFRelease(appNameInCFString);

                if (wellyCount > 1 && [[appId lowercaseString] isEqualToString: wellyIdentifier])
                    appName = [NSString stringWithFormat:@"%@ (%@)", appName, [[NSBundle bundleWithPath: appPath] infoDictionary][@"CFBundleVersion"]];

                NSImage *appIcon = [ws iconForFile:appPath];
                [appIcon setSize: NSMakeSize(16, 16)];

                NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: (NSString *)appName action: NULL keyEquivalent: @""];
                [item setRepresentedObject: appId];
                if (appIcon) [item setImage: appIcon];
                [menuItems addObject: item];
            }
        }
    }

    NSMenu *menu = [[NSMenu alloc] initWithTitle: @"PopUp Menu"];
    for (NSMenuItem *item in menuItems)
        [menu addItem: item];
    [button setMenu: menu];

    /* Select the default client */
    CFStringRef defaultHandler = LSCopyDefaultHandlerForURLScheme((__bridge CFStringRef) scheme);
    if (defaultHandler) {
        NSInteger index = [button indexOfItemWithRepresentedObject: (__bridge NSString *) defaultHandler];
        if (index != -1)
            [button selectItemAtIndex: index];
        CFRelease(defaultHandler);
    }
}

- (void)awakeFromNib {
    [self setupMenuOfURLScheme:@"telnet" forPopUpButton:_telnetPopUpButton];
    [self setupMenuOfURLScheme:@"ssh" forPopUpButton:_sshPopUpButton];
}

#pragma mark -
#pragma mark Actions


- (IBAction) setChineseFont: (id) sender {
    [[NSFontManager sharedFontManager] setAction: @selector(changeChineseFont:)];
    [[sender window] makeFirstResponder: [sender window]];
    NSFontPanel *fp = [NSFontPanel sharedFontPanel];
    WLGlobalConfig *config = [WLGlobalConfig sharedInstance];
    [fp setPanelFont:[NSFont fontWithName:config.chineseFontName
                                    size:config.chineseFontSize]
          isMultiple:NO];
    [fp orderFront: self];
}

- (IBAction) setEnglishFont: (id) sender {
    [[NSFontManager sharedFontManager] setAction: @selector(changeEnglishFont:)];
    [[sender window] makeFirstResponder:[sender window]];
    NSFontPanel *fp = [NSFontPanel sharedFontPanel];
    WLGlobalConfig *config = [WLGlobalConfig sharedInstance];
    [fp setPanelFont:[NSFont fontWithName:config.englishFontName
                                     size:config.englishFontSize]
          isMultiple:NO];
    [fp orderFront: self];
}

- (void) changeChineseFont: (id) sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    NSFont *selectedFont = [fontManager selectedFont];
    if (selectedFont == nil) {
        selectedFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    }
    NSFont *panelFont = [fontManager convertFont:selectedFont];
    WLGlobalConfig *config = [WLGlobalConfig sharedInstance];
    config.chineseFontName = panelFont.fontName;
    config.chineseFontSize = panelFont.pointSize;
}

- (void) changeEnglishFont: (id) sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    NSFont *selectedFont = [fontManager selectedFont];
    if (selectedFont == nil) {
        selectedFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
   }
    NSFont *panelFont = [fontManager convertFont:selectedFont];
    WLGlobalConfig *config = [WLGlobalConfig sharedInstance];
    config.englishFontName = panelFont.fontName;
    config.englishFontSize = panelFont.pointSize;
}

- (IBAction) setDefaultTelnetClient: (id) sender {
    NSString *appId = [[sender selectedItem] representedObject];
    if (appId)
        LSSetDefaultHandlerForURLScheme(CFSTR("telnet"), (__bridge CFStringRef)appId);
}

- (IBAction) setDefaultSSHClient: (id) sender {
    NSString *appId = [[sender selectedItem] representedObject];
    if (appId)
        LSSetDefaultHandlerForURLScheme(CFSTR("ssh"), (__bridge CFStringRef)appId);
}

#pragma mark -
#pragma mark Configuration

- (void)setupToolbar
{
    [self addView:self.generalPrefView label:NSLocalizedString(@"General", @"Preferences") image: [NSImage imageNamed: @"NSPreferencesGeneral"]];
    [self addView:self.connectionPrefView label: NSLocalizedString(@"Connection", @"Preferences") image: [NSImage imageNamed: @"NSApplicationIcon"]];
    [self addView:self.fontsPrefView label: NSLocalizedString(@"Fonts", @"Preferences") image: [NSImage imageNamed: @"NSFontPanel"]];
    [self addView:self.colorsPrefView label: NSLocalizedString(@"Colors", @"Preferences") image: [NSImage imageNamed: @"NSColorPanel"]];
}

@end
