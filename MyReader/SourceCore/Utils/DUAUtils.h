//
//  DUAUtils.h
//  MyReader
//
//  Created by xiejc on 2018/11/13.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DUAUtils : NSObject


/**
 解压文件

 @param filePath 文件地址
 @return 解压目录
 */
+ (NSString *)unzipWithFilePath:(NSString *)filePath;

/**
 获取epub类型文件的OPF地址

 @param epubPath epub文件地址
 @return OPF地址
 */
+ (NSString *)OPFPathFromEpubPath:(NSString *)epubPath;

/**
 获取目录的上级目录

 @param path 目录地址
 @return 上级目录
 */
+ (NSString *)getparentPathFromPath:(NSString *)path;


/**
 解析epub类型的OPF dict包含 chapterIndex、chapterTitle、chapterPath

 @param opfPath opf文件地址
 @return 字典数组，包含解析得到的章节信息
 */
+ (NSArray <NSDictionary *> *)parseOPF:(NSString *)opfPath;


@end

NS_ASSUME_NONNULL_END
