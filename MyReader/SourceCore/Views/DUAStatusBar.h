//
//  DUAStatusBar.h
//  MyReader
//
//  Created by xiejc on 2018/11/16.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DUAStatusBar : UIView


/**
 更新数据显示

 @param currentChapterIndex 章节索引
 @param currentPageIndex 页面索引
 @param totalPageCounts 章节总页数
 */
- (void)updateLabelWithChapter:(int)currentChapterIndex currentPageIndex:(int)currentPageIndex totalPageCounts:(int)totalPageCounts;

@end

NS_ASSUME_NONNULL_END
