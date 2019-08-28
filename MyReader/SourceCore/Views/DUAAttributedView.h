//
//  DUAAttributedView.h
//  MyReader
//
//  Created by xiejc on 2018/11/16.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import <DTCoreText/DTCoreText.h>
#import "DUAConVexLensView.h"

NS_ASSUME_NONNULL_BEGIN

@interface DUAAttributedView : DTAttributedLabel

@property (nonatomic, strong, nullable) DUAConVexLensView *convexView;

//长按复制、笔记
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGes;

@property (nonatomic, strong) UITapGestureRecognizer *tapGes;

//NSValue-CGRect
@property (nonatomic, strong) NSMutableArray *selectedLineArray;

@property (nonatomic, assign) NSRange hitRange;

@property (nonatomic, assign) BOOL touchLeft;

@property (nonatomic, assign) CGRect leftCursor;

@property (nonatomic, assign) CGRect rightCursor;

@property (nonatomic, assign) BOOL touchIsValide;

@end

NS_ASSUME_NONNULL_END
