//
//  WLTermView.m
//  Welly
//
//  Created by K.O.ed on 09-11-2.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import "WLTermView.h"
#import "CommonType.h"
#import "WLGlobalConfig.h"
#import "WLTerminal.h"
#import "WLConnection.h"
#import "WLAsciiArtRender.h"
#import "WLSite.h"


static WLGlobalConfig *gConfig;
static NSImage *gLeftImage;

@implementation WLTermView

#pragma mark -
#pragma mark Initialization & Destruction

- (void)configure {
    if (!gConfig)
        gConfig = [WLGlobalConfig sharedInstance];
    _maxColumn = [gConfig column];
    _maxRow = [gConfig row];
    _fontWidth = [gConfig cellWidth];
    _fontHeight = [gConfig cellHeight];

    [self setFrameSize:[gConfig contentSize]];

    _backedImage = [[NSImage alloc] initWithSize:[gConfig contentSize]];
    [_backedImage setFlipped:NO];

    gLeftImage = [[NSImage alloc] initWithSize:NSMakeSize(_fontWidth, _fontHeight)];

    [_asciiArtRender configure];
}

- (instancetype)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _asciiArtRender = [WLAsciiArtRender new];

        [self configure];

        // Register KVO
        NSArray *observeKeys = @[@"shouldSmoothFonts", @"showsHiddenText", @"cellWidth", @"cellHeight", @"cellSize",
                                @"chineseFontName", @"chineseFontSize", @"chineseFontPaddingLeft", @"chineseFontPaddingBottom",
                                @"englishFontName", @"englishFontSize", @"englishFontPaddingLeft", @"englishFontPaddingBottom",
                                @"colorBlack", @"colorBlackHilite", @"colorRed", @"colorRedHilite", @"colorGreen", @"colorGreenHilite",
                                @"colorYellow", @"colorYellowHilite", @"colorBlue", @"colorBlueHilite", @"colorMagenta", @"colorMagentaHilite",
                                @"colorCyan", @"colorCyanHilite", @"colorWhite", @"colorWhiteHilite", @"colorBG", @"colorBGHilite"];
        for (NSString *key in observeKeys)
            [[WLGlobalConfig sharedInstance] addObserver:self
                                              forKeyPath:key
                                                 options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
                                                 context:nil];

        // For blink cells
        [NSTimer scheduledTimerWithTimeInterval:1
                                         target:self
                                       selector:@selector(updateBlinkTicker:)
                                       userInfo:nil
                                        repeats:YES];
    }
    return self;
}

#pragma mark -
#pragma mark Accessor
- (WLConnection *)frontMostConnection {
    return _connection;
}

- (WLTerminal *)frontMostTerminal {
    return self.frontMostConnection.terminal;
}

- (BOOL)isConnected {
    return self.frontMostConnection.isConnected;
}

- (BOOL)hasBlinkCell {
    int c, r;
    WLTerminal *ds = self.frontMostTerminal;
    if (!ds) return NO;
    for (r = 0; r < _maxRow; r++) {
        [ds updateDoubleByteStateForRow: r];
        cell *currRow = [ds cellsOfRow: r];
        for (c = 0; c < _maxColumn; c++)
            if (isBlinkCell(currRow[c]))
                return YES;
    }
    return NO;
}
/*
- (void)setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
    [self refreshDisplay];
}*/

#pragma mark -
#pragma mark Drawing
- (void)refreshDisplay {
    [self.frontMostTerminal setAllDirty];
    [self updateBackedImage];
    [self setNeedsDisplay:YES];
}

- (void)refreshHiddenRegion {
    if (![self isConnected])
        return;
    for (int i = 0; i < _maxRow; i++) {
        cell *currRow = [self.frontMostTerminal cellsOfRow:i];
        for (int j = 0; j < _maxColumn; j++)
            if (isHiddenAttribute(currRow[j].attr))
                [self.frontMostTerminal setDirty:YES atRow:i column:j];
    }
    [self refreshDisplay];
}

- (void)displayCellAtRow:(int)r
                  column:(int)c {
    [self setNeedsDisplayInRect:NSMakeRect(c * _fontWidth, (_maxRow - 1 - r) * _fontHeight, _fontWidth, _fontHeight)];
}

- (void)terminalDidUpdate:(WLTerminal *)terminal {
    if (terminal == self.frontMostTerminal) {
        [self tick];
    }
}

- (void)tick {
    [self updateBackedImage];
    WLTerminal *ds = self.frontMostTerminal;

    if (ds && (_x != [ds cursorColumn] || _y != [ds cursorRow])) {
        [self setNeedsDisplayInRect:NSMakeRect(_x * _fontWidth, (_maxRow - 1 - _y) * _fontHeight, _fontWidth, _fontHeight)];
        [self setNeedsDisplayInRect:NSMakeRect([ds cursorColumn] * _fontWidth, (_maxRow - 1 - [ds cursorRow]) * _fontHeight, _fontWidth, _fontHeight)];
        _x = [ds cursorColumn];
        _y = [ds cursorRow];
    }
}

- (NSRect)cellRectForRect:(NSRect)r {
    int originx = r.origin.x / _fontWidth;
    int originy = r.origin.y / _fontHeight;
    int width = ((r.size.width + r.origin.x) / _fontWidth) - originx + 1;
    int height = ((r.size.height + r.origin.y) / _fontHeight) - originy + 1;
    return NSMakeRect(originx, originy, width, height);
}

- (void)drawRect:(NSRect)rect {
    WLTerminal *ds = self.frontMostTerminal;
    if ([self isConnected]) {
        // Modified by gtCarrera
        // Draw the background color first!!!
        [[gConfig colorBG] set];
            NSRect retangle = [self bounds];
        NSRectFill(retangle);
            /* Draw the backed image */

        NSRect imgRect = rect;
        imgRect.origin.y = (_fontHeight * _maxRow) - rect.origin.y - rect.size.height;
        [_backedImage drawAtPoint:rect.origin
                         fromRect:rect
                        operation:NSCompositeCopy
                         fraction:1.0];

        [self drawBlink];

            /* Draw the url underline */
#ifndef USE_CT_UNDERLINE
        int c, r;
        [[NSColor orangeColor] set];
        [NSBezierPath setDefaultLineWidth: 1.0];
        for (r = 0; r < _maxRow; r++) {
            cell *currRow = [ds cellsOfRow:r];
            for (c = 0; c < _maxColumn; c++) {
                int start;
                for (start = c; c < _maxColumn && currRow[c].attr.f.url; c++) ;
                if (c != start) {
                    [NSBezierPath strokeLineFromPoint:NSMakePoint(start * _fontWidth, (_maxRow - r - 1) * _fontHeight + 0.5)
                                              toPoint:NSMakePoint(c * _fontWidth, (_maxRow - r - 1) * _fontHeight + 0.5)];
        //                    //[self drawURLUnderlineAtRow:r fromColumn:start toColumn:c];
                }
            }
        }
#endif
        /* Draw the cursor */
        [[NSColor whiteColor] set];
        [NSBezierPath setDefaultLineWidth:2.0];
        [NSBezierPath strokeLineFromPoint:NSMakePoint([ds cursorColumn] * _fontWidth, (_maxRow - 1 - [ds cursorRow]) * _fontHeight + 1)
                                  toPoint:NSMakePoint(([ds cursorColumn] + 1) * _fontWidth, (_maxRow - 1 - [ds cursorRow]) * _fontHeight + 1) ];
            [NSBezierPath setDefaultLineWidth:1.0];
            _x = [ds cursorColumn], _y = [ds cursorRow];

            /* Draw the selection */
        //[self drawSelection];
    } else {
        [[gConfig colorBG] set];
        NSRect r = [self bounds];
        NSRectFill(r);
    }
}

- (void)updateBlinkTicker:(NSTimer *)timer {
    // TODO: use local variable to do this.
    [[WLGlobalConfig sharedInstance] updateBlinkTicker];
    if ([self hasBlinkCell])
        [self setNeedsDisplay:YES];
}

- (void)drawBlink {
    if (![gConfig blinkTicker])
        return;

    id ds = [self frontMostTerminal];
    if (!ds)
        return;

    @autoreleasepool {
        for (int r = 0; r < _maxRow; r++) {
            cell *currRow = [ds cellsOfRow: r];
            for (int c = 0; c < _maxColumn; c++) {
                if (isBlinkCell(currRow[c])) {
                    int bgColorIndex = currRow[c].attr.f.reverse ? currRow[c].attr.f.fgColor : currRow[c].attr.f.bgColor;
                    BOOL bold = currRow[c].attr.f.reverse ? currRow[c].attr.f.bold : NO;

                // Modified by K.O.ed: All background color use same alpha setting.
                NSColor *bgColor = [gConfig bgColorAtIndex:bgColorIndex hilite:bold];
                //bgColor = [bgColor colorWithAlphaComponent:[[gConfig colorBG] alphaComponent]];
                [bgColor set];
                    //[[gConfig colorAtIndex: bgColorIndex hilite: bold] set];
                    NSRectFill(NSMakeRect(c * _fontWidth, (_maxRow - r - 1) * _fontHeight, _fontWidth, _fontHeight));
                }
            }
        }

    }
}

/*
 Extend Bottom:

 AAAAAAAAAAA            BBBBBBBBBBB
 BBBBBBBBBBB            CCCCCCCCCCC
 CCCCCCCCCCC   ->    DDDDDDDDDDD
 DDDDDDDDDDD            ...........

 */
- (void)extendBottomFrom:(int)start
                      to:(int)end {
    [_backedImage lockFocus];
    [_backedImage drawAtPoint:NSMakePoint(0, (_maxRow - end) * _fontHeight)
                     fromRect:NSMakeRect(0, (_maxRow - end - 1) * _fontHeight,
                                         _maxColumn * _fontWidth, (end - start) * _fontHeight)
                    operation:NSCompositeCopy
                     fraction:1.0];

    [gConfig->_colorTable[0][gConfig->_bgColorIndex] set];
    NSRectFill(NSMakeRect(0, (_maxRow - end - 1) * _fontHeight, _maxColumn * _fontWidth, _fontHeight));
    [_backedImage unlockFocus];
}


/*
 Extend Top:
 AAAAAAAAAAA            ...........
 BBBBBBBBBBB            AAAAAAAAAAA
 CCCCCCCCCCC   ->    BBBBBBBBBBB
 DDDDDDDDDDD            CCCCCCCCCCC
 */
- (void)extendTopFrom:(int)start
                   to:(int)end {
    [_backedImage lockFocus];
    [_backedImage drawAtPoint:NSMakePoint(0, (_maxRow - end - 1) * _fontHeight)
                     fromRect:NSMakeRect(0, (_maxRow - end) * _fontHeight,
                                         _maxColumn * _fontWidth, (end - start) * _fontHeight)
                    operation:NSCompositeCopy
                     fraction:1.0];
    [gConfig->_colorTable[0][gConfig->_bgColorIndex] set];
    NSRectFill(NSMakeRect(0, (_maxRow - start - 1) * _fontHeight, _maxColumn * _fontWidth, _fontHeight));
    [_backedImage unlockFocus];
}

- (void)updateBackedImage {
    @autoreleasepool {
        WLTerminal *ds = self.frontMostTerminal;
        [_backedImage lockFocus];
        CGContextRef myCGContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
        if (ds) {
            /* Draw Background */
            for (int y = 0; y < _maxRow; y++) {
                for (int x = 0; x < _maxColumn; x++) {
                    if ([ds isDirtyAtRow:y column:x]) {
                        int startx = x;
                        for (; x < _maxColumn && [ds isDirtyAtRow:y column:x]; x++) ;
                        [self updateBackgroundForRow:y from:startx to:x];
                    }
                }
            }
            CGContextSaveGState(myCGContext);
            CGContextSetShouldSmoothFonts(myCGContext, !![gConfig shouldSmoothFonts]);
            /* Draw String row by row */
            for (int y = 0; y < _maxRow; y++) {
                NSAffineTransform *xform = [NSAffineTransform transform];
                [xform translateXBy:0 yBy:(_maxRow - 1 - y) * _fontHeight];
                [xform concat];
                [self drawStringForRow:y context:myCGContext];
                [xform invert];
                [xform concat];
            }
            CGContextRestoreGState(myCGContext);
            /*
            for (y = 0; y < _maxRow; y++) {
                for (x = 0; x < _maxColumn; x++) {
                    [ds setDirty:NO atRow:y column:x];
                }
            }*/
            [ds removeAllDirtyMarks];
        } else {
            [[NSColor clearColor] set];
            CGContextFillRect(myCGContext, CGRectMake(0, 0, _maxColumn * _fontWidth, _maxRow * _fontHeight));
        }
        [_backedImage unlockFocus];
        return;
    }
}

- (NSAttributedString *)segmentRow:(int)r {
    WLTerminal *term = self.frontMostTerminal;
    cell *row = [term cellsOfRow:r];

    NSMutableString *text = nil;

    attribute lastLeftAttr, lastAttr;
    BOOL wasSym = FALSE;
    BOOL wasDB = FALSE;
    BOOL wasDirty = FALSE;
    BOOL wasDoubleColor = FALSE;

    NSMutableAttributedString *line = [[NSMutableAttributedString alloc] init];

    for (int col = 0; col <= _maxColumn; col++) {
        BOOL isSameRun = FALSE;
        attribute currLeftAttr, currAttr;
        BOOL isSym = FALSE;
        BOOL isDB = FALSE;
        BOOL isDoubleColor = FALSE;
        BOOL isDirty = FALSE;
        unichar ch;

        if (col == _maxColumn)
            goto close_last_run;

        cell *c = &row[col];
        int db = c->attr.f.doubleByte;

        isDirty = [term isDirtyAtRow:r column:col];
        if (!isDirty) {
            ch = NSAttachmentCharacter;
        } else if (db == 0) {
            ch = c->byte ?: ' ';
        } else if (db == 1) {
            // db == 2 will be taking care of the whole double-byte char
            continue;
        } else if (db == 2) {
            isDB = TRUE;
            cell *hi = &row[col - 1];
            cell *lo = c;
            unsigned short code = ((hi->byte) << 8) + (lo->byte) - 0x8000;
            ch = [WLEncoder toUnicode:code
                             encoding:self.frontMostConnection.site.encoding];
            if (fgColorIndexOfAttribute(hi->attr) == fgColorIndexOfAttribute(lo->attr) &&
                fgBoldOfAttribute(hi->attr) == fgBoldOfAttribute(lo->attr)) {
                currLeftAttr = hi->attr;
                isDoubleColor = FALSE;
            } else {
                currLeftAttr = hi->attr;
                isDoubleColor = TRUE;
            }
            
            isSym = [WLAsciiArtRender isAsciiArtSymbol:ch];
            if (isSym) {
                // If user desires anti-hidden, and it has hidden parts, then
                // we shall leave it to CoreText to deal with. Otherwise
                // mark it as a symbol, we will draw it manually.
                if ([gConfig showsHiddenText]) {
                    isSym = !(isHiddenAttribute(lo->attr) ||
                              isHiddenAttribute(hi->attr));
                }
            }
        } else {
            NSAssert1(FALSE, @"f.doubleByte = %d", db);
        }
        currAttr = c->attr;
        // the first char
        if (!text) {
            text = [NSMutableString string];
            wasSym = isSym;
            lastAttr = currAttr;
            lastLeftAttr = currLeftAttr;
            wasDB = isDB;
            wasDoubleColor = isDoubleColor;
            wasDirty = isDirty;
        }
        
        isSameRun = (wasDirty == isDirty &&
                     wasSym == isSym &&
                     lastAttr.v == currAttr.v &&
                     wasDB == isDB &&
                     wasDoubleColor == isDoubleColor);
        if (isSameRun && isDoubleColor) {
            isSameRun = (lastLeftAttr.v == currLeftAttr.v);
        }
        if (isSameRun)
            [text appendFormat:@"%C", ch];

    close_last_run:
        // close last run
        if (!isSameRun) {
            NSDictionary *attrs = nil;
            if (!wasDirty) {
                attrs = [gConfig attributesForFixedWidth:1
                                                withName:@"WLSpace"];
            } else if (wasSym) {
                attrs = [gConfig attributesForFixedCellWithName:@"WLSymbol"
                                                  leftAttribute:lastLeftAttr.v
                                                 rightAttribute:lastAttr.v];
            } else if (wasDoubleColor) {
                attrs = [gConfig attributesForDoubleByte:wasDB
                                                leftBold:fgBoldOfAttribute(lastLeftAttr)
                                               leftColor:fgColorIndexOfAttribute(lastLeftAttr)
                                               rightBold:fgBoldOfAttribute(lastAttr)
                                              rightColor:fgColorIndexOfAttribute(lastAttr)];
            } else {
                attrs = [gConfig attributesForDoubleByte:wasDB
                                                    bold:fgBoldOfAttribute(lastAttr)
                                                   color:fgColorIndexOfAttribute(lastAttr)
                                               underline:lastAttr.f.url];
            }
            NSAttributedString *run = [[NSAttributedString alloc] initWithString:text
                                                                      attributes:attrs];
            [line appendAttributedString:run];
            text = [NSMutableString stringWithFormat:@"%C", ch];
            lastAttr = currAttr;
            lastLeftAttr = currLeftAttr;
            wasSym = isSym;
            wasDB = isDB;
            wasDoubleColor = isDoubleColor;
            wasDirty = isDirty;
        }
    }
    return line;
}
/*
 * |               - cell-width -             |
 * +-----------------+------------------------+----
 * |                 |                        |
 * |                 |                        |
 * |                 |                        |
 * |                 @- - - - - - - - - - - - + / cell-height /
 * | - padding-left- | / descender-height /   |
 * |                 +------------------------|
 * |                 | / padding-bottom /     |
 * +-----------------------------------------------
 *
 */
/*
 
 // FIXME: why?
 if (col == 0)
 [self setNeedsDisplayInRect:NSMakeRect((col - 1) * _fontWidth,
 (_maxRow - 1 - r) * _fontHeight,
 _fontWidth, _fontHeight)];

 
 */
- (void)drawStringForRow:(int)r
                 context:(CGContextRef)myCGContext {
    // the colors of first half the double-byte char and the second half char
    // are different.
    WLTerminal *ds = self.frontMostTerminal;
    [ds updateDoubleByteStateForRow:r];


    NSAttributedString *attributedString = [self segmentRow:r];
    // Run-length of the style

    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attributedString);

    // walk thru each run, examine each character in each of them
    NSArray *runs = (__bridge NSArray *)CTLineGetGlyphRuns(line);

    for (id obj in runs) {
        CTRunRef run = (__bridge CTRunRef)obj;
        NSDictionary *attrs = (__bridge NSDictionary *)CTRunGetAttributes(run);
        CGFloat x = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
        if (attrs[@"WLSpace"]) {
            continue;
        }
        if (attrs[@"WLSymbol"]) {
            CFRange range = CTRunGetStringRange(run);
            NSString *symbols = [attributedString.string substringWithRange:NSMakeRange(range.location, range.length)];
            attribute leftAttr = {
                .v = [attrs[kWLLeftCellTraitsAttributeName] unsignedShortValue],
            };
            attribute rightAttr = {
                .v = [attrs[kWLRightCellTraitsAttributeName] unsignedShortValue],
            };
            for (int i = 0; i < symbols.length; i++) {
                // symbols are double width glyphs
                [self drawSpecialSymbol:[symbols characterAtIndex:i]
                                     at:x + i * _fontWidth * 2
                          leftAttribute:leftAttr
                         rightAttribute:rightAttr];
            }
        } else {
            CGFloat descent;
            CTRunGetTypographicBounds(run, CFRangeMake(0, 0), NULL, &descent, NULL);
            CGContextSaveGState(myCGContext);
            CGContextTranslateCTM(myCGContext, 0, descent);
            CTRunDraw(run, myCGContext, CFRangeMake(0, 0));
            CGContextRestoreGState(myCGContext);

            if (attrs[kWLLeftCellTraitsAttributeName]) {
                // Double Color
                // the character have been rendered using the color of its right half.
                NSDictionary *leftAttrs = attrs[kWLLeftCellTraitsAttributeName];
                CFRange range = CTRunGetStringRange(run);
                NSString *leftString = [attributedString attributedSubstringFromRange:NSMakeRange(range.location, range.length)].string;
                NSAttributedString *leftAttrStr = [[NSAttributedString alloc] initWithString:leftString
                                                                                  attributes:leftAttrs];
                [self drawLeftString:leftAttrStr x:x];
            }
        }
    }
    CFRelease(line);
}

- (void)updateBackgroundForRow:(int)r
                          from:(int)start
                            to:(int)end {
    cell *currRow = [self.frontMostTerminal cellsOfRow:r];
    NSRect rowRect = NSMakeRect(start * _fontWidth,
                                (_maxRow - 1 - r) * _fontHeight,
                                (end - start) * _fontWidth,
                                _fontHeight);

    attribute currAttr, lastAttr = (currRow + start)->attr;
    int length = 0;
    unsigned int currentBackgroundColor = 0;
    BOOL currentBold = NO;
    unsigned int lastBackgroundColor = bgColorIndexOfAttribute(lastAttr);
    BOOL lastBold = bgBoldOfAttribute(lastAttr);
    /*
     Optimization Idea:
     for example:

     BBBBBBBBBBBWWWWWWWWWWBBBBBBBBBBB

     currently, we draw each color segment one by one, like this:

     1. BBBBBBBBBBB
     2. BBBBBBBBBBBWWWWWWWWWW
     3. BBBBBBBBBBBWWWWWWWWWWBBBBBBBBBBB

     but we can use only two fillRect:

     1. BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
     2. BBBBBBBBBBBWWWWWWWWWWBBBBBBBBBBB

     If further optimization of background drawing is needed, consider the 2D reduction.

     NOTE: 2007/12/07

     We don't have to reduce the number of fillRect. We should reduce the number of pixels it draws.
     Obviously, the current method draws less pixels than the second one. So it's optimized already!
     */
    for (int c = start; c <= end; c++) {
        if (c < end) {
            currAttr = (currRow + c)->attr;
            currentBackgroundColor = bgColorIndexOfAttribute(currAttr);
            currentBold = bgBoldOfAttribute(currAttr);
        }

        if (currentBackgroundColor != lastBackgroundColor || currentBold != lastBold || c == end) {
            /* Draw Background */
            NSRect rect = NSMakeRect((c - length) * _fontWidth, (_maxRow - 1 - r) * _fontHeight,
                                     _fontWidth * length, _fontHeight);

            // Modified by K.O.ed: All background color use same alpha setting.
            NSColor *bgColor = [gConfig bgColorAtIndex:lastBackgroundColor hilite:lastBold];
            //bgColor = [bgColor colorWithAlphaComponent:[[gConfig colorBG] alphaComponent]];
            [bgColor set];

            //[[gConfig colorAtIndex: lastBackgroundColor hilite: lastBold] set];
            // [NSBezierPath fillRect: rect];
            NSRectFill(rect);

            /* finish this segment */
            length = 1;
            lastAttr.v = currAttr.v;
            lastBackgroundColor = currentBackgroundColor;
            lastBold = currentBold;
        } else {
            length++;
        }
    }

    [self setNeedsDisplayInRect:rowRect];
}

- (void)drawLeftString:(NSAttributedString *)string
                 x:(CGFloat)x {
    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)string);
    NSArray *runs = (__bridge NSArray *)CTLineGetGlyphRuns(line);
    NSAssert1(runs.count == 1, @"has %lu runs in the line", runs.count);
    CTRunRef run = (__bridge CTRunRef)runs[0];
    CFIndex glyphCount = CTRunGetGlyphCount(run);
    NSAssert(string.length == glyphCount, @"there should be no ligatures");
    
    NSRect rect = {
        .origin = NSZeroPoint,
        .size = [gLeftImage size],
    };

    for (CFIndex i = 0; i < glyphCount; i++) {
        [gLeftImage lockFocus];
        {
            CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
            CGContextSetShouldSmoothFonts(context, !![gConfig shouldSmoothFonts]);
            
            CGContextSaveGState(context);
            CFRange range = CFRangeMake(index, index + 1);
            CGPoint position;
            CTRunGetPositions(run, range, &position);
            CGContextTranslateCTM(context, -position.x, -position.y);
            CTRunDraw(run, context, range);
            CGContextRestoreGState(context);
        }
        [gLeftImage unlockFocus];
        [gLeftImage drawAtPoint:NSMakePoint(x + i * _fontWidth, 0)
                       fromRect:rect
                      operation:NSCompositeCopy
                       fraction:1.0];
    }
    CFRelease(line);
}

- (void)drawSpecialSymbol:(unichar)ch
                       at:(CGFloat)x
            leftAttribute:(attribute)attr1
           rightAttribute:(attribute)attr2 {
    [_asciiArtRender drawSpecialSymbol:ch
                                    at:x
                         leftAttribute:attr1
                        rightAttribute:attr2];
}

// Get current BBS image
- (NSImage *)image {
    // Leave for others to release it
    return [[NSImage alloc] initWithData:[self dataWithPDFInsideRect:[self frame]]];
}

#pragma mark -
#pragma mark WLTabItemContentObserver protocol
- (void)didChangeContent:(id)content {
    if (!content)
        _connection = nil;
    if ([content isKindOfClass:[WLConnection class]]) {
        _connection = content;
        [self refreshDisplay];
    }
}

#pragma mark -
#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"shouldSmoothFonts"]) {
        [self refreshDisplay];
    } else if ([keyPath hasPrefix:@"cell"]) {
        [self configure];
        [self refreshDisplay];
    } else if ([keyPath hasPrefix:@"chineseFont"] || [keyPath hasPrefix:@"englishFont"] || [keyPath hasPrefix:@"color"]) {
        //[[WLGlobalConfig sharedInstance] refreshFont];
        [self refreshDisplay];
    } else if ([keyPath isEqualToString:@"showsHiddenText"]) {
        [self refreshHiddenRegion];
    }
}
@end
