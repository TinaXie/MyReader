//
//  DUAReader.h
//  MyReader
//
//  Created by xiejc on 2018/11/19.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DUAtranslationController.h"
#import "DUAContainerPageViewController.h"

#import "DUAConfiguration.h"
#import "DUADataParser.h"
#import "DUAStatusBar.h"
#import "DUATableView.h"
#import "DUAtranslationControllerExt.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    DUAReaderState_busy,
    DUAReaderState_ready
} DUAReaderState;


@class DUAReader;

@protocol DUAReaderDelegate <NSObject>

- (void)readerDidClickSettingFrame:(DUAReader *)reader;

- (void)reader:(DUAReader *)reader readerStateChanged:(DUAReaderState)state;

- (void)reader:(DUAReader *)reader readerProgressUpdatedCurrentChapter:(int)currentChapter curPage:(int)curPage totalPages:(int)totalPages;

- (void)reader:(DUAReader *)reader chapterTitles:(NSMutableArray<NSString *> *)chapterTitles;

@end



@interface DUAReader : UIViewController

@property (nonatomic, strong) DUAConfiguration *config;
@property (nonatomic, weak) id<DUAReaderDelegate> delegate;
/// 章节缓存（分页后的页面数组）
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<DUAPageModel *> *> *chapterCaches;
/// chapter model cache
@property (nonatomic, strong) NSMutableDictionary<NSString *, DUAChapterModel *> *chapterModels;
 /// 数据解析类
@property (nonatomic, strong) DUADataParser *dataParser;
 /// 缓存队列
@property (nonatomic, strong) dispatch_queue_t cacheQueue;

/// page vc - 仿真、简约、无动画翻页模式使用
@property (nonatomic, strong) DUAContainerPageViewController *pageVC;
/// table view - 滚动模式使用 每次滚动加载当前数据
@property (nonatomic, strong) DUATableView *tableView;
/// translation vc - 简约、无动画翻页模式使用
@property (nonatomic, strong) DUAtranslationControllerExt *translationVC;
/// 是否重分页
@property (nonatomic, assign) BOOL isReCutPage;
/// 当前页面 从 1 开始计算
@property (nonatomic, assign) int currentPageIndex;
/// 当前章节 从 1 开始计算
@property (nonatomic, assign) int currentChapterIndex;
/// 分页前当前页首字符索引

/// 重分页后如何定位阅读进度？
/// 首先记录分页前当前页面首字符在本章的索引，重分页后根据索引确定用户先前看的页面在章节中新的位置
@property (nonatomic, assign) int prePageStartLocation;
/// 首次进阅读器
@property (nonatomic, assign) BOOL firstIntoReader;
/// 页面饥饿
@property (nonatomic, assign) BOOL pageHunger;
/// 解析后的所有章节model
@property (nonatomic, strong) NSMutableArray<DUAChapterModel *> *totalChapterModels;

/// 对table view而言，status bar是放在reader view上的，其他模式则是放在每个page页面上
@property (nonatomic, strong) DUAStatusBar *pageStatuBar;

/// 是否成功切换到某章节，成功为0，不成功则记录未成功切换的章节index，当指定跳至某章节时使用
@property (nonatomic, assign) int successSwitchChapter;



/**
 读取文本 从第几页开始 pageIndex:从1开始

 @param filePath 文件地址
 @param pageIndex 第几页
 */
- (void)readWithFilePath:(NSString *)filePath pageIndex:(int)pageIndex;



/**
 读取某章某页
 
 @param chapterIndex 章索引
 @param pageIndex 页索引
 */
- (void)readChapterByIndex:(int)chapterIndex pageIndex:(int)pageIndex;

@end

NS_ASSUME_NONNULL_END
