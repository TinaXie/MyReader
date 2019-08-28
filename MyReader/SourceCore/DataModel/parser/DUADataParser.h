//
//  DUADataParser.h
//  MyReader
//
//  Created by xiejc on 2018/11/14.
//  Copyright © 2018 xiejc. All rights reserved.
//


#import "DUAChapterModel.h"
#import "DUAConfiguration.h"
#import "DUAPageModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DUADataParser : NSObject


/**
 解析文件章节

 @param path 文件地址
 @param completeHandler 解析完章节的完成回调
 */
- (void)parseChapterFromBook:(NSString *)path completeHandler:(void(^)(NSMutableArray<NSString *> *titles, NSMutableArray<DUAChapterModel *> *models))completeHandler;


/**
 获取某章节的显示文字

 @param chapter 章节
 @param config 显示配置
 @return 显示文字
 */
- (NSMutableAttributedString *)attributedStringFromChapterModel:(DUAChapterModel *)chapter config:(DUAConfiguration *)config;


/**

将章节内容根据当前样式进行分页，获取pagelist
 @param attrString 当前章节的字符串
 @param config 显示样式
 @param completeHandler 分割成每一页面后的回调
 */
- (void)cutChapterPageAtIndex:(int)chapterIndex attrString:(NSAttributedString *)attrString config:(DUAConfiguration *)config completeHandler:(void(^)(int count, DUAPageModel *pageModel, BOOL completed))completeHandler;



@end

NS_ASSUME_NONNULL_END
