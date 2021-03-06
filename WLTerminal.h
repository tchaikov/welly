//
//  WLTerminal.h
//  Welly
//
//  YLTerminal.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/9/10.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"

@class WLConnection, WLMessageDelegate, WLIntegerArray;
@class WLTerminal;

@protocol WLTerminalObserver

- (void)terminalDidUpdate:(WLTerminal *)terminal;

@end

@interface WLTerminal : NSObject {	
	
    unsigned int _offset;
	
    BOOL **_dirty;

	NSMutableSet *_observers;

    unsigned _maxRow;
    unsigned _maxColumn;

	unichar *_textBuf;
}

@property unsigned int cursorColumn;
@property unsigned int cursorRow;
@property cell **grid;

@property (weak, setter=setConnection:, nonatomic) WLConnection *connection;
@property (assign, readwrite) WLBBSType bbsType;
@property (readonly) BBSState bbsState;

/* Clear */
- (void)clearAll;

/* Dirty */
- (BOOL)isDirtyAtRow:(int)r 
			  column:(int)c;
- (void)setAllDirty;
- (void)setDirty:(BOOL)d 
		   atRow:(int)r 
		  column:(int)c;
- (void)setDirtyForRow:(int)r;
- (void)removeAllDirtyMarks;

/* Access Data */
- (attribute)attrAtRow:(int)r 
				column:(int)c ;
- (NSString *)stringAtIndex:(int)begin 
					 length:(int)length;
- (NSAttributedString *)attributedStringAtIndex:(NSUInteger)location 
										 length:(NSUInteger)length;
- (cell *)cellsOfRow:(int)r;
- (cell)cellAtIndex:(int)index;

/* Update State */
- (void)updateDoubleByteStateForRow:(int)r;
- (void)updateBBSState;

/* Accessor */
- (WLEncoding)encoding;
- (void)setEncoding:(WLEncoding)encoding;

/* Input Interface */
- (void)feedGrid:(cell **)grid;
- (void)setCursorX:(int)cursorX
				 Y:(int)cursorY;

/* Observer Interface */
- (void)addObserver:(id <WLTerminalObserver>)observer;
@end
