//
//  WLButtonAreaHotspotHandler.m
//  Welly
//
//  Created by K.O.ed on 09-1-27.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import "WLButtonAreaHotspotHandler.h"
#import "WLMouseBehaviorManager.h"

#import "WLTerminalView.h"
#import "WLConnection.h"
#import "WLTerminal.h"
#import "WLEffectView.h"

#define fbComposePost @"\020"
#define fbDeletePost @"dy\n"
#define fbShowNote @"\t"
#define fbShowHelp @"h"
#define fbNormalToDigest @"\07""1\n"
#define fbDigestToThread @"\07""2\n"
#define fbThreadToMark @"\07""3\n"
#define fbMarkToOrigin @"\07""4\n"
#define fbOriginToNormal @"e"
#define fbSwitchDisplayAllBoards @"y"
#define fbSwitchSortBoards @"S"
#define fbSwitchBoardsNumber @"c"

NSString *const WLButtonNameComposePost = @"Compose Post";
NSString *const WLButtonNameDeletePost = @"Delete Post";
NSString *const WLButtonNameShowNote = @"Show Note";
NSString *const WLButtonNameShowHelp = @"Show Help";
NSString *const WLButtonNameNormalToDigest = @"Normal To Digest";
NSString *const WLButtonNameDigestToThread = @"Digest To Thread";
NSString *const WLButtonNameThreadToMark = @"Thread To Mark";
NSString *const WLButtonNameMarkToOrigin = @"Mark To Origin";
NSString *const WLButtonNameOriginToNormal = @"Origin To Normal";
NSString *const WLButtonNameAuthorToNormal = @"Author To Normal";
NSString *const WLButtonNameJumpToMailList = @"Jump To Mail List";
NSString *const WLButtonNameEnterExcerption = @"Enter Excerption";

NSString *const WLButtonNameSwitchDisplayAllBoards = @"Display All Boards";
NSString *const WLButtonNameSwitchSortBoards = @"Sort Boards";
NSString *const WLButtonNameSwitchBoardsNumber = @"Switch Boards Number";
NSString *const WLButtonNameDeleteBoard = @"Delete Board";

NSString *const WLButtonNameChatWithUser = @"Chat";
NSString *const WLButtonNameMailToUser = @"Mail";
NSString *const WLButtonNameSendMessageToUser = @"Send Message";
NSString *const WLButtonNameAddUserToFriendList = @"Add To Friend List";
NSString *const WLButtonNameRemoveUserFromFriendList = @"Remove From Friend List";
NSString *const WLButtonNameSwitchUserListMode = @"Switch User List Mode";
NSString *const WLButtonNameShowUserDescription = @"Show User Description";
NSString *const WLButtonNamePreviousUser = @"Previous User";
NSString *const WLButtonNameNextUser = @"Next User";

NSString *const FBCommandSequenceAuthorToNormal = @"e";
NSString *const FBCommandSequenceChatWithUser = @"t";
NSString *const FBCommandSequenceMailToUser = @"m";
NSString *const FBCommandSequenceSendMessageToUser = @"s";
NSString *const FBCommandSequenceAddUserToFriendList = @"oY\n";
NSString *const FBCommandSequenceRemoveUserFromFriendList = @"dY\n";
NSString *const FBCommandSequenceSwitchUserListMode = @"f";
NSString *const FBCommandSequenceShowUserDescription = @"l";
NSString *const FBCommandSequencePreviousUser = termKeyUp;
NSString *const FBCommandSequenceNextUser = termKeyDown;
NSString *const FBCommandSequenceJumpToMailList = @"v";
NSString *const FBCommandSequenceEnterExcerption = @"x";

@implementation WLButtonDesc

+ (instancetype)descWithState:(int)state
                          sig:(NSString *)sig
                          len:(int)len
                         name:(NSString *)name
                      command:(NSString *)command {
    return [[WLButtonDesc alloc] initWithState:state sig:sig len:len name:name command:command];
}

- (instancetype)initWithState:(int)state
                          sig:(NSString *)sig
                          len:(int)len
                         name:(NSString *)name
                      command:(NSString *)command {
    if ((self = [super init])) {
        self.state = state;
        self.signature = sig;
        self.signatureLengthOfBytes = len;
        self.buttonName = name;
        self.commandSequence = command;
    }
    return self;
}

@end

@implementation WLButtonAreaHotspotHandler
#pragma mark -
#pragma mark Mouse Event Handler
- (void)mouseUp:(NSEvent *)theEvent {
	NSString *commandSequence = [_manager activeTrackingAreaUserInfo][WLMouseCommandSequenceUserInfoName];
	if (commandSequence != nil) {
		[[_view frontMostConnection] sendText:commandSequence];
		return;
	}
}

- (void)mouseEntered:(NSEvent *)theEvent {
	NSDictionary *userInfo = [[theEvent trackingArea] userInfo];
	if ([_view isMouseActive]) {
		NSString *buttonText = userInfo[WLMouseButtonTextUserInfoName];
		[[_view effectView] drawButton:[[theEvent trackingArea] rect] withMessage:buttonText];
	}
	[_manager setActiveTrackingAreaUserInfo:userInfo];
	[[NSCursor pointingHandCursor] set];
}

- (void)mouseExited:(NSEvent *)theEvent {
	[[_view effectView] clearButton];
	[_manager setActiveTrackingAreaUserInfo:nil];
	// FIXME: Temporally solve the problem in full screen mode.
	if ([NSCursor currentCursor] == [NSCursor pointingHandCursor])
		[_manager restoreNormalCursor];
}

- (void)mouseMoved:(NSEvent *)theEvent {
	if ([NSCursor currentCursor] != [NSCursor pointingHandCursor])
		[[NSCursor pointingHandCursor] set];
}

#pragma mark -
#pragma mark Update State
- (void)addButtonArea:(NSString *)buttonName
	  commandSequence:(NSString *)cmd 
				atRow:(int)r 
			   column:(int)c 
			   length:(int)len {
	NSRect rect = [_view rectAtRow:r column:c height:1 width:len];
	// Generate User Info
	NSArray *keys = @[WLMouseHandlerUserInfoName, WLMouseCommandSequenceUserInfoName, WLMouseButtonTextUserInfoName];
	NSArray *objects = @[self, cmd, NSLocalizedString(buttonName, @"Mouse Button")];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[_trackingAreas addObject:[_manager addTrackingAreaWithRect:rect userInfo:userInfo]];
}

- (void)updateButtonAreaForRow:(int)r {
	NSArray *buttonsDefinition =
    @[/* BBSBrowseBoard */
      [WLButtonDesc descWithState:BBSBrowseBoard sig:@"发表文章[Ctrl-P]" len:16 name:WLButtonNameComposePost command:fbComposePost],
      [WLButtonDesc descWithState:BBSBrowseBoard sig:@"砍信[d]" len:7 name:WLButtonNameDeletePost command:fbDeletePost],
      [WLButtonDesc descWithState:BBSBrowseBoard sig:@"备忘录[TAB]" len:11 name:WLButtonNameShowNote command:fbShowNote],
      [WLButtonDesc descWithState:BBSBrowseBoard sig:@"求助[h]" len:7 name:WLButtonNameShowHelp command:fbShowHelp],
      [WLButtonDesc descWithState:BBSBrowseBoard sig:@"[一般模式]" len:10 name:WLButtonNameNormalToDigest command:fbNormalToDigest],
      [WLButtonDesc descWithState:BBSBrowseBoard sig:@"[文摘模式]" len:10 name:WLButtonNameDigestToThread command:fbDigestToThread],
      [WLButtonDesc descWithState:BBSBrowseBoard sig:@"[主题模式]" len:10 name:WLButtonNameThreadToMark command:fbThreadToMark],
      [WLButtonDesc descWithState:BBSBrowseBoard sig:@"[精华模式]" len:10 name:WLButtonNameMarkToOrigin command:fbMarkToOrigin],
      [WLButtonDesc descWithState:BBSBrowseBoard sig:@"[原作模式]" len:10 name:WLButtonNameOriginToNormal command:fbOriginToNormal],
      [WLButtonDesc descWithState:BBSBrowseBoard sig:@"[作者模式]" len:10 name:WLButtonNameAuthorToNormal command:FBCommandSequenceAuthorToNormal],
      [WLButtonDesc descWithState:BBSBrowseBoard sig:@"[您有信件]" len:10 name:WLButtonNameJumpToMailList command:FBCommandSequenceJumpToMailList],
      [WLButtonDesc descWithState:BBSBrowseBoard sig:@"阅读[→ len:]" len:10 name:WLButtonNameEnterExcerption command:FBCommandSequenceEnterExcerption],
      /* BBSBoardList */
      [WLButtonDesc descWithState:BBSBoardList sig:@"列出[y]" len:7 name:WLButtonNameSwitchDisplayAllBoards command:fbSwitchDisplayAllBoards],
      [WLButtonDesc descWithState:BBSBoardList sig:@"排序[S]" len:7 name:WLButtonNameSwitchSortBoards command:fbSwitchSortBoards],
      [WLButtonDesc descWithState:BBSBoardList sig:@"切换[c]" len:7 name:WLButtonNameSwitchBoardsNumber command:fbSwitchBoardsNumber],
      [WLButtonDesc descWithState:BBSBoardList sig:@"删除[d]" len:7 name:WLButtonNameDeleteBoard command:fbDeletePost],
      [WLButtonDesc descWithState:BBSBoardList sig:@"求助[h]" len:7 name:WLButtonNameShowHelp command:fbShowHelp],
      [WLButtonDesc descWithState:BBSBoardList sig:@"[您有信件]" len:10 name:WLButtonNameJumpToMailList command:FBCommandSequenceJumpToMailList],
      /* BBSUserInfo */
      [WLButtonDesc descWithState:BBSUserInfo sig:@"寄信[m]" len:7 name:WLButtonNameMailToUser command:FBCommandSequenceMailToUser],
      [WLButtonDesc descWithState:BBSUserInfo sig:@"聊天[t]" len:7 name:WLButtonNameChatWithUser command:FBCommandSequenceChatWithUser],
      [WLButtonDesc descWithState:BBSUserInfo sig:@"送讯息[s]" len:9 name:WLButtonNameSendMessageToUser command:FBCommandSequenceSendMessageToUser],
      [WLButtonDesc descWithState:BBSUserInfo sig:@"加,减朋" len:7 name:WLButtonNameAddUserToFriendList command:FBCommandSequenceAddUserToFriendList],
      [WLButtonDesc descWithState:BBSUserInfo sig:@"友[o,d]" len:7 name:WLButtonNameRemoveUserFromFriendList command:FBCommandSequenceRemoveUserFromFriendList],
      [WLButtonDesc descWithState:BBSUserInfo sig:@"切换模式 [f]" len:12 name:WLButtonNameSwitchUserListMode command:FBCommandSequenceSwitchUserListMode],
      [WLButtonDesc descWithState:BBSUserInfo sig:@"求救[h]" len:7 name:WLButtonNameShowHelp command:fbShowHelp],
      [WLButtonDesc descWithState:BBSUserInfo sig:@"查看说明档[l]" len:13 name:WLButtonNameShowUserDescription command:FBCommandSequenceShowUserDescription],
      [WLButtonDesc descWithState:BBSUserInfo sig:@"选择使用" len:8 name:WLButtonNamePreviousUser command:FBCommandSequencePreviousUser],
      [WLButtonDesc descWithState:BBSUserInfo sig:@"者[↑ len:]" len:9 name:WLButtonNameNextUser command:FBCommandSequenceNextUser],
    ];

	
	if (r > 3 && r < _maxRow-1)
		return;
	
	WLTerminal *ds = [_view frontMostTerminal];
	BBSState bbsState = ds.bbsState;
	
	for (int x = 0; x < _maxColumn; ++x) {
        for (WLButtonDesc *desc in buttonsDefinition) {
            if (bbsState.state != desc.state)
				continue;
			int length = desc.signatureLengthOfBytes;
			if (x < _maxColumn - length) {
				if ([[ds stringAtIndex:(x + r * _maxColumn) length:length] isEqualToString:desc.signature]) {
					[self addButtonArea:desc.buttonName
						commandSequence:desc.commandSequence
								  atRow:r
								 column:x
								 length:length];
					x += length - 1;
					break;
				}
			}
        }
	}
}

- (BOOL)shouldUpdate {
	if (![_view shouldEnableMouse] || ![_view isConnected]) {
		return YES;
	}
	
	// Only update when BBS state has been changed
	BBSState bbsState = [[_view frontMostTerminal] bbsState];
	BBSState lastBbsState = [_manager lastBBSState];
	if (bbsState.state == lastBbsState.state &&
		bbsState.subState == lastBbsState.subState)
		return NO;
	
	return YES;
}

- (void)update {
	// Clear & Update
	[self clear];
	if (![_view shouldEnableMouse] || ![_view isConnected]) {
		return;	
	}
	for (int r = 0; r < _maxRow; ++r) {
		[self updateButtonAreaForRow:r];
	}
}
@end
