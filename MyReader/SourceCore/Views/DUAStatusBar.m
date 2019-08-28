//
//  DUAStatusBar.m
//  MyReader
//
//  Created by xiejc on 2018/11/16.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import "DUAStatusBar.h"

@interface DUAStatusBar ()

@property (nonatomic, strong) UILabel *label;

@end

@implementation DUAStatusBar

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
    
        self.label = [[UILabel alloc] init];
        self.label.textColor = [UIColor grayColor];
        self.label.font = [UIFont systemFontOfSize:11.0];
        self.label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.label];
    }
    return self;
}

- (void)updateLabelWithChapter:(int)currentChapterIndex currentPageIndex:(int)currentPageIndex totalPageCounts:(int)totalPageCounts {
    NSString *text = [NSString stringWithFormat:@"第%d章 第%d/%d页", currentChapterIndex, currentPageIndex, totalPageCounts];
    self.label.text = text;
}


- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat labelX = 0;
    CGFloat labelY = 0;
    CGFloat labelW = self.width;
    CGFloat labelH = self.height;

    self.label.y = labelY;
    self.label.x = labelX;
    self.label.frame = CGRectMake(labelX, labelY, labelW, labelH);
}

@end
