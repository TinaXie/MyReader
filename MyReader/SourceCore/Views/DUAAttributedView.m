//
//  DUAAttributedView.m
//  MyReader
//
//  Created by xiejc on 2018/11/16.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import "DUAAttributedView.h"

@interface DUAAttributedView () <UIGestureRecognizerDelegate>


@end

@implementation DUAAttributedView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.touchLeft = NO;
        self.touchIsValide = NO;
    
        self.leftCursor = CGRectZero;
        self.rightCursor = CGRectZero;

        self.hitRange = NSMakeRange(0, 0);

        self.longPressGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
        [self addGestureRecognizer:self.longPressGes];
    }
    return self;
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gesture {
    CGPoint hitPoint = [gesture locationInView:gesture.view];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        NSInteger hitIndex = [self closestCursorIndexToPoint:hitPoint];
        self.hitRange = [self locateParaRangeByIndex:hitIndex];
        self.selectedLineArray = [self lineArrayFromRange:self.hitRange];
        [self setNeedsDisplayInRect:self.bounds];
        [self showMenuItemView];
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        self.tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGes:)];
        [self addGestureRecognizer:self.tapGes];
    }
}

- (void)handleTapGes:(UITapGestureRecognizer *)gesture {
    [self.selectedLineArray removeAllObjects];
    [self setNeedsDisplay];
    [self removeGestureRecognizer:gesture];
    
    [self hideMenuItemView];
}


- (NSRange)locateParaRangeByIndex:(NSInteger)index {
    NSRange targetRange = NSMakeRange(0, 0);
    for (id obj in self.layoutFrame.paragraphRanges){
        NSRange paraRange = [obj rangeValue];
        if (index >= paraRange.location && index < paraRange.location + paraRange.length) {
            targetRange = paraRange;
            break;
        }
    }
    return targetRange;
}

- (NSMutableArray *)lineArrayFromRange:(NSRange)range {
    NSMutableArray *lineArray = [NSMutableArray array];
    DTCoreTextLayoutLine *line = [self.layoutFrame lineContainingIndex:range.location];
    NSInteger selectedMaxIndex = range.location + range.length;
    NSInteger startIndex = range.location;

    while (line.stringRange.location < selectedMaxIndex) {
        NSInteger lineMaxIndex = line.stringRange.location + line.stringRange.length;
        CGFloat startX = line.frame.origin.x + [line offsetForStringIndex:startIndex];
        CGFloat lineEndOffset = lineMaxIndex <= selectedMaxIndex ? [line offsetForStringIndex:lineMaxIndex] : [line offsetForStringIndex:selectedMaxIndex];
        CGFloat endX = line.frame.origin.x + lineEndOffset;
        CGRect rect = CGRectMake(startX, line.frame.origin.y, endX - startX, line.frame.size.height);
        [lineArray addObject:[NSValue valueWithCGRect:rect]];
        
        startIndex = lineMaxIndex;
        line = [self.layoutFrame lineContainingIndex:startIndex];
        if (lineMaxIndex == selectedMaxIndex || line == nil) {
            break;
        }
    }
    return lineArray;
}


- (void)updateHitRangeWithPoint:(CGPoint)point touchIsLeft:(BOOL)touchIsLeft {
    NSInteger hitIndex = [self.layoutFrame closestCursorIndexToPoint:point];
    if (touchIsLeft) {
        if (hitIndex >= self.hitRange.location + self.hitRange.length) {
            return;
        }
        self.hitRange = NSMakeRange(hitIndex, self.hitRange.location + self.hitRange.length - hitIndex);
    } else {
        if (hitIndex <= self.hitRange.location) {
            return;
        }
        self.hitRange = NSMakeRange(self.hitRange.location, hitIndex - self.hitRange.location);
    }
}

- (void)showMenuItemView {
    [self becomeFirstResponder];
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    UIMenuItem *copyItem = [[UIMenuItem alloc] initWithTitle:@"复制" action:@selector(onCopyItemClicked)];
    UIMenuItem *noteItem = [[UIMenuItem alloc] initWithTitle:@"笔记" action:@selector(onNoteItemClicked)];
    menuController.menuItems = @[copyItem, noteItem];

    CGRect rect = CGRectZero;
    if (self.selectedLineArray.count > 0) {
        rect = [self.selectedLineArray.firstObject CGRectValue];
    }
    [menuController setTargetRect:rect inView:self];
    [menuController setMenuVisible:YES animated:YES];
}

- (void)hideMenuItemView {
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    [menuController setMenuVisible:NO animated:YES];
    [self resignFirstResponder];
}


- (void)showConvexLensView:(CGPoint)point {
    if (self.convexView == nil) {
        self.convexView = [[DUAConVexLensView alloc] init];
        [[UIApplication sharedApplication].keyWindow addSubview:self.convexView];
    }
}

- (void)hideConvexLensView {
    if (self.convexView != nil) {
        [self.convexView removeFromSuperview];
        self.convexView = nil;
    }
}

//menu item click method
- (void)onCopyItemClicked {
    [self onNoteItemClicked];
}


- (void)onNoteItemClicked {
    NSString *pageContent = self.attributedString.string;
    NSInteger startIndex = self.hitRange.location;
    NSInteger endIndex = startIndex + self.hitRange.length;
    if (pageContent.length <= endIndex) {
        endIndex = pageContent.length;
    }
    
    NSString *slice = [pageContent substringWithRange:NSMakeRange(startIndex, endIndex - startIndex + 1)];
    NSLog(@"当前选中范围 %@  选中内容 %@", NSStringFromRange(self.hitRange), slice);
    
    [self resignFirstResponder];
    [self.selectedLineArray removeAllObjects];
    [self setNeedsDisplay];
    [self removeGestureRecognizer:self.tapGes];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    [super drawLayer:layer inContext:ctx];
    [self drawSelectedLines:ctx];
}

- (void)drawSelectedLines:(CGContextRef)context {
    if (self.selectedLineArray.count == 0) {
        return;
    }
    
    CGMutablePathRef path = CGPathCreateMutable();
    for (NSValue *item in self.selectedLineArray) {
        CGPathAddRect(path, NULL, item.CGRectValue);
    }
    
    UIColor *color = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextAddPath(context, path);
    CGContextFillPath(context);
    //        save left and roght cursor location
    
    CGRect firstRect = [self.selectedLineArray.firstObject CGRectValue];
    self.leftCursor = CGRectMake(firstRect.origin.x - 4, firstRect.origin.y, 4, firstRect.size.height);
    
    CGRect lastRect = [self.selectedLineArray.lastObject CGRectValue];
    self.rightCursor = CGRectMake(CGRectGetMaxX(lastRect), lastRect.origin.y, 4, lastRect.size.height);

    CGContextAddRect(context, self.leftCursor);
    CGContextAddRect(context, self.rightCursor);
    CGContextAddEllipseInRect(context, CGRectMake(CGRectGetMidX(self.leftCursor) - 3, self.leftCursor.origin.y - 6, 6, 6));
    CGContextAddEllipseInRect(context, CGRectMake(CGRectGetMidX(self.rightCursor) - 3, CGRectGetMaxY(self.rightCursor), 6, 6));
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillPath(context);
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}


//gesture delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        CGPoint hitPoint = [gestureRecognizer locationInView:gestureRecognizer.view];
        CGRect leftRect = CGRectMake(CGRectGetMinX(self.leftCursor) - 20, CGRectGetMinY(self.leftCursor) - 20, self.leftCursor.size.width + 40, self.leftCursor.size.height + 40);
        
        CGRect rightRect = CGRectMake(CGRectGetMinX(self.rightCursor) - 20, CGRectGetMinY(self.rightCursor) - 20, self.rightCursor.size.width + 40, self.rightCursor.size.height + 40);
        
        if (!CGRectContainsPoint(leftRect, hitPoint) && CGRectContainsPoint(rightRect, hitPoint)) {
            return YES;
        }
        return false;
    }
    return NO;
}

@end
