//
//  DUAReader.m
//  MyReader
//
//  Created by xiejc on 2018/11/19.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import "DUAReader.h"
#import "DUAEpubDataParser.h"
#import "DUATextDataParser.h"
#import "DUAAttributedView.h"
#import "DUATableViewCell.h"

#import "DUAPageViewController.h"
#import "DUABackViewController.h"

@interface DUAReader ()
<UIPageViewControllerDelegate, UIPageViewControllerDataSource,
UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate,
DUATranslationProtocol>

//滚动模式下的背景图片 - 在tableview下
@property (nonatomic, strong) UIImageView *bgImgView;

@end

@implementation DUAReader

- (instancetype)init {
    if (self = [super init]) {
        self.chapterCaches = [NSMutableDictionary dictionary];
        self.chapterModels = [NSMutableDictionary dictionary];
        self.dataParser = [[DUADataParser alloc] init];
        self.cacheQueue = dispatch_queue_create("duareader.cache.queue", NULL);
        self.isReCutPage = NO;
        self.currentPageIndex = -1;
        self.currentChapterIndex = -1;
        self.prePageStartLocation = -1;
        self.firstIntoReader = YES;
        self.pageHunger = NO;
        self.totalChapterModels = [NSMutableArray array];
        self.successSwitchChapter = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    if (self.config.bookType == DUAReaderBookType_epub) {
        self.dataParser = [[DUAEpubDataParser alloc] init];
    } else {
        self.dataParser = [[DUATextDataParser alloc] init];
    }

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pagingTap:)];
    [self.view addGestureRecognizer:tapGesture];

    [self addObserverForConfiguration];
    [self loadReaderView];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


#pragma mark - 页面UI

/**
 弹出设置菜单
 
 @param ges 单击手势
 */
- (void)pagingTap:(UITapGestureRecognizer *)ges {
    CGPoint tapPoint = [ges locationInView:self.view];
    CGFloat width = Screen_Width;
    CGRect rect = CGRectMake(width / 3, 0, width / 3, Screen_Height);
    if (CGRectContainsPoint(rect, tapPoint)) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(readerDidClickSettingFrame:)]) {
            [self.delegate readerDidClickSettingFrame:self];
        }
    }
}


/**
 初始化阅读器View
 */
- (void)loadReaderView {
    switch(self.config.scrollType) {
        case DUAReaderScrollType_curl:
            [self loadPageViewController];
            break;
        case DUAReaderScrollType_vertical:
            [self loadTableView];
            break;
        case DUAReaderScrollType_horizontal:
            [self loadTranslationVC:YES];
            break;
        case DUAReaderScrollType_none:
            [self loadTranslationVC:NO];
            break;
    }
    
    [self loadBackgroundImage];
}


/**
 初始化page VC - 仿真模式使用
 */
- (void)loadPageViewController {
    [self clearReaderViewIfNeed];
    UIPageViewControllerTransitionStyle transtionStyle = self.config.scrollType == DUAReaderScrollType_curl ? UIPageViewControllerTransitionStylePageCurl : UIPageViewControllerTransitionStyleScroll;
    self.pageVC = [[DUAContainerPageViewController alloc] initWithTransitionStyle:transtionStyle navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageVC.delegate = self;
    self.pageVC.dataSource = self;
    self.pageVC.view.backgroundColor = [UIColor clearColor];
    self.pageVC.doubleSided = self.config.scrollType == DUAReaderScrollType_curl;
    [self addChildViewController:self.pageVC];
    [self.view addSubview:self.pageVC.view];
    [self.pageVC didMoveToParentViewController:self];
}


/**
 初始化滚动table
 */
- (void)loadTableView {
    [self clearReaderViewIfNeed];
    self.tableView = [[DUATableView alloc] initWithFrame:CGRectMake(0, self.config.contentFrame.origin.y, Screen_Width, self.config.contentFrame.size.height) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.estimatedRowHeight = 0;
    self.tableView.scrollsToTop = NO;
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];
    
    [self addStatusBarToView:self.view];
}

/**
 加载转换页面 - 简约、无动画使用
 
 @param animating 是否需要动画
 */
- (void)loadTranslationVC:(BOOL)animating {
    [self clearReaderViewIfNeed];
    self.translationVC = [[DUAtranslationControllerExt alloc] init];
    self.translationVC.delegate = self;
    self.translationVC.allowAnimating = animating;
    [self addChildViewController:self.translationVC];
    [self.translationVC didMoveToParentViewController:self];
    [self.view addSubview:self.translationVC.view];
}



#pragma mark 对外接口


- (void)readWithFilePath:(NSString *)filePath pageIndex:(int)pageIndex {
    [self postReaderStateNotification:DUAReaderState_busy];
    [self.dataParser parseChapterFromBook:filePath completeHandler:^(NSMutableArray<NSString *> * _Nonnull titles, NSMutableArray<DUAChapterModel *> * _Nonnull models) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(reader:chapterTitles:)]) {
            [self.delegate reader:self chapterTitles:titles];
        }
        self.totalChapterModels = models;
        if (models.count > 0) {
            [self readWithChapter:models.firstObject pageIndex:pageIndex];
        }
    }];
}



/**
 读取某章某页

 @param chapterIndex 章索引
 @param pageIndex 页索引
 */
- (void)readChapterByIndex:(int)chapterIndex pageIndex:(int)pageIndex {
    NSLog(@"readChapterByIndex chapter:%d page:%d", chapterIndex, pageIndex);
    if (chapterIndex < 1 || chapterIndex > self.totalChapterModels.count) {
        return;
    }
    
    int chapterPages = (int)[self pageArrayFromCache:chapterIndex].count;

    if (chapterPages == 0) {
        //没缓存 需要处理
        NSLog(@"readChapter no cache!! chapter:%d page:%d", chapterIndex, pageIndex);
        self.successSwitchChapter = chapterIndex;
        [self postReaderStateNotification:DUAReaderState_busy];
        [self requestChapterWithIndex:chapterIndex];
    } else {
        self.successSwitchChapter = 0;
        self.currentPageIndex = MAX(1, pageIndex);
        [self updateChapterIndex:chapterIndex];
        [self loadPage:self.currentPageIndex];
        if (self.delegate && [self.delegate respondsToSelector:@selector(reader:readerProgressUpdatedCurrentChapter:curPage:totalPages:)]) {
            int totalPages = (int)[self pageArrayFromCache:self.currentChapterIndex].count;
            [self.delegate reader:self readerProgressUpdatedCurrentChapter:self.currentChapterIndex curPage:self.currentPageIndex totalPages:totalPages];
        }
    }
}


#pragma mark - 私有方法

- (void)readWithChapter:(DUAChapterModel *)chapter pageIndex:(int)pageIndex {
    NSLog(@"readWithChapter chapter:%d pageIndex:%d", chapter.chapterIndex, pageIndex);
    [self.chapterModels setObject:chapter forKey:[NSString stringWithFormat:@"%d", chapter.chapterIndex]];
    if (![NSThread isMainThread]) {
        [self forwardCacheWith:chapter];
        return;
    }
    
    NSMutableArray<DUAPageModel *> *pageModels = [NSMutableArray array];
    if (self.isReCutPage) {
        [self postReaderStateNotification:DUAReaderState_busy];
        [self.chapterCaches removeAllObjects];
    } else {
        pageModels = [NSMutableArray arrayWithArray:[self pageArrayFromCache:chapter.chapterIndex]];
    }

    if (pageModels.count == 0 || self.isReCutPage) {
        dispatch_async(self.cacheQueue, ^{
            NSArray *cacheList = [self pageArrayFromCache:chapter.chapterIndex];
            if (cacheList.count > 0) {
                return;
            }
            
            NSAttributedString *attrString = [self.dataParser attributedStringFromChapterModel:chapter config:self.config];
            [self.dataParser cutChapterPageAtIndex:chapter.chapterIndex attrString:attrString config:self.config completeHandler:^(int count, DUAPageModel * _Nonnull pageModel, BOOL completed) {
                [pageModels addObject:pageModel];
                if (completed) {
                    NSLog(@"cutChapterPageAtIndex chapter1:%d pageModelChapter%d:", chapter.chapterIndex, pageModel.chapterBlong);

                    [self cachePageArray:pageModels chapterIndex:chapter.chapterIndex];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self processPageArray:pageModels chapter:chapter pageIndex:pageIndex];
                    });
                }
            }];
        });
    }
}


/**
 从本地加载章节页面结束后显示

 @param pageArray 页面pagelist
 @param chapter 章节索引
 @param pageIndex 页面索引
 */
- (void)processPageArray:(NSMutableArray<DUAPageModel *> *)pageArray chapter:(DUAChapterModel *)chapter pageIndex:(int)pageIndex {
    [self postReaderStateNotification:DUAReaderState_ready];
    if (self.pageHunger) {
        self.pageHunger = NO;
        if (self.pageVC != nil) {
            [self loadPage:self.currentPageIndex];
        } else if (self.tableView != nil) {
            if (self.currentPageIndex == 1 && self.tableView.scrollDirection == TableViewScrollDirecton_up) {
                [self requestLastChapterForTableView];
            } else if (self.tableView.scrollDirection == TableViewScrollDirecton_down && self.currentPageIndex == (int)[self pageArrayFromCache:self.currentChapterIndex].count) {
                [self requestNextChapterForTableView];
            }
        }
    }
    
    if (self.firstIntoReader) {
        self.firstIntoReader = NO;
        self.currentPageIndex = MAX(1, pageIndex);
        [self updateChapterIndex:chapter.chapterIndex];
        [self loadPage:self.currentPageIndex];
        if (self.delegate && [self.delegate respondsToSelector:@selector(reader:readerProgressUpdatedCurrentChapter:curPage:totalPages:)]) {
            int totalPages = (int)[self pageArrayFromCache:self.currentChapterIndex].count;
            [self.delegate reader:self readerProgressUpdatedCurrentChapter:self.currentChapterIndex curPage:self.currentPageIndex totalPages:totalPages];
        }
    }
    if (self.isReCutPage) {
        self.isReCutPage = NO;
        __block int newIndex = 1;
        [pageArray enumerateObjectsUsingBlock:^(DUAPageModel * _Nonnull item, NSUInteger index, BOOL * _Nonnull stop) {
            if (self.prePageStartLocation > item.range.location && self.prePageStartLocation <= (item.range.location + item.range.length)) {
                newIndex = (int)index;
            }
        }];
        self.currentPageIndex = newIndex;
        [self loadPage:self.currentPageIndex];
        
        /// 触发预缓存
        [self forwardCacheIfNeed:true];
        [self forwardCacheIfNeed:NO];
    }
    
    if (self.successSwitchChapter != 0) {
        [self readChapterByIndex:self.successSwitchChapter pageIndex:1];
    }
}


- (void)postReaderStateNotification:(DUAReaderState)state {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(reader:readerStateChanged:)]) {
            [self.delegate reader:self readerStateChanged:state];
        }
    });
}

/**
 加载页面

 @param pageIndex 第几页
 */
- (void)loadPage:(int)pageIndex {
    switch (self.config.scrollType) {
        case DUAReaderScrollType_curl:
        {
            DUAPageViewController *page = [self getPageVCWithPageIndex:pageIndex chapterIndex:self.currentChapterIndex];
            if (page == nil) {
                return;
            }
            [self.pageVC setViewControllers:@[page] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];

            [self updateStatusBar];
        }
            break;
        case DUAReaderScrollType_vertical:
        {
            NSLog(@"load table view page: %d", pageIndex);
            [self.tableView.dataArray removeAllObjects];
            self.tableView.dataArray = [NSMutableArray arrayWithArray:[self pageArrayFromCache:self.currentChapterIndex]];
            self.tableView.cellIndex = pageIndex - 1;
            if (self.tableView.dataArray.count == 0) {
                return;
            }
            self.tableView.isReloading = YES;
            [self.tableView reloadData];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.tableView.cellIndex inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            self.tableView.isReloading = NO;

            [self updateStatusBar];

            /// 当加载的页码为最后一页，需要手动触发一次下一章的请求
            int totalPage = (int)[self pageArrayFromCache:self.currentChapterIndex].count;
            if (self.currentPageIndex == totalPage - 1) {
                [self requestNextChapterForTableView];
            }
        }
            break;
        case DUAReaderScrollType_horizontal:
        case DUAReaderScrollType_none:
        {
            
            DUAPageViewController *pageVC = [self getPageVCWithPageIndex:pageIndex chapterIndex:self.currentChapterIndex];
            if (pageVC == nil) {
                return;
            }
            [self.translationVC setViewController:pageVC direction:TranslationControllerNavigationDirection_left animated:NO completionHandler:nil];

            [self updateStatusBar];
        }
            break;
        default:
            break;
    }
}

/**
 加载背景图片
 */
- (void)loadBackgroundImage {
    DUAPageViewController *curPage = nil;
    if (self.config.scrollType == DUAReaderScrollType_curl) {
        if (self.pageVC.viewControllers.count > 0 && [self.pageVC.viewControllers.firstObject isKindOfClass:[DUAPageViewController class]]) {
            curPage = self.pageVC.viewControllers.firstObject;
        }
    } else if (self.config.scrollType == DUAReaderScrollType_horizontal || self.config.scrollType == DUAReaderScrollType_none) {
        if (self.translationVC.childViewControllers.count > 0 && [self.translationVC.childViewControllers.firstObject isKindOfClass:[DUAPageViewController class]]) {
            curPage = self.translationVC.childViewControllers.firstObject;
        }
    } else {
        if (self.bgImgView == nil) {
            self.bgImgView = [[UIImageView alloc] initWithFrame:self.view.frame];
            [self.view insertSubview:self.bgImgView atIndex:0];
        }
        self.bgImgView.image = self.config.backgroundImage;
    }
    
    if (curPage != nil && curPage.view.subviews.count > 0 && [curPage.view.subviews.firstObject isKindOfClass:[UIImageView class]]) {
        UIImageView *imageView = curPage.view.subviews.firstObject;
        imageView.image = self.config.backgroundImage;
    }
}
    

/**
 添加底部页面索引

 @param view 页面
 */
- (void)addStatusBarToView:(UIView *)view {
    CGFloat safeAreaBottomHeight = UI_IS_IPHONEX ? 34.0 : 0.0;
    CGRect rect = CGRectMake(self.config.contentFrame.origin.x, Screen_Height - 30 - safeAreaBottomHeight, self.config.contentFrame.size.width, 20.0);
    
    if (self.pageStatuBar == nil) {
        self.pageStatuBar = [[DUAStatusBar alloc] init];
    }
    
    if (self.pageStatuBar.superview != view) {
        [self.pageStatuBar removeFromSuperview];
        [view addSubview:self.pageStatuBar];
    }

    self.pageStatuBar.frame = rect;
    [view bringSubviewToFront:self.pageStatuBar];
}


/**
 更新底部页面索引
 */
- (void)updateStatusBar {
    [self.pageStatuBar updateLabelWithChapter:self.currentChapterIndex currentPageIndex:self.currentPageIndex totalPageCounts:(int)[self pageArrayFromCache:self.currentChapterIndex].count];
}

- (void)clearReaderViewIfNeed {
    if (self.pageVC != nil) {
        [self.pageVC.view removeFromSuperview];
        [self.pageVC willMoveToParentViewController:nil];
        [self.pageVC removeFromParentViewController];
    }
    
    if (self.tableView != nil) {
        for (UIView *aView in self.view.subviews) {
            [aView removeFromSuperview];
        }
    }
    
    if (self.translationVC != nil) {
        [self.translationVC.view removeFromSuperview];
        [self.translationVC willMoveToParentViewController:nil];
        [self.translationVC removeFromParentViewController];
    }
}


#pragma mark - 数据处理

/**
 获取某章某页的页面VC （仿真、平移、无动画翻页模式使用page）

 @param pageIndex 页面索引
 @param chapterIndex 章节索引
 @return 某页的页面VC
 */
- (DUAPageViewController *)getPageVCWithPageIndex:(int)pageIndex chapterIndex:(int)chapterIndex {
    NSLog(@"getPageVCWithPageIndex chapter:%d page:%d", chapterIndex, pageIndex);
    DUAPageViewController *page = [[DUAPageViewController alloc] init];
    page.index = pageIndex;
    page.chapterBelong = chapterIndex;
    if (self.config.backgroundImage != nil) {
        page.backgroundImage = self.config.backgroundImage;
    }
    
    page.dtLabel.frame = CGRectMake(0, self.config.contentFrame.origin.y, self.view.width, self.config.contentFrame.size.height);
    page.dtLabel.edgeInsets = UIEdgeInsetsMake(0, self.config.contentFrame.origin.x, 0, self.config.contentFrame.origin.x);

    NSArray *pageArray = [self pageArrayFromCache:chapterIndex];
    if (pageArray.count == 0 || pageArray.count < pageIndex || pageIndex < 1) {
        return nil;
    }

    DUAPageModel *pageModel = [pageArray objectAtIndex:pageIndex - 1];
    page.dtLabel.attributedString = pageModel.attributedString;
    
    [self addStatusBarToView:page.view];
    NSLog(@"getPageVCWithPageIndex chapter:%d page:%d %@", chapterIndex, pageIndex, page);
    return page;
}


/**
 获取某章节的缓存页面数据

 @param chapterIndex 章节
 @return 缓存的所有页面数据
 */
- (NSArray<DUAPageModel *> *)pageArrayFromCache:(int)chapterIndex {
    NSArray<DUAPageModel *> *pageArray = [self.chapterCaches objectForKey:[NSString stringWithFormat:@"%d", chapterIndex]];
    if (pageArray == nil) {
        pageArray = [NSArray array];
    }
    
    NSLog(@"pageArrayFromCache chapter:%d count:%lu", chapterIndex, (unsigned long)pageArray.count);
    return pageArray;
}


#pragma mark - 属性观察器


/**
 添加回调
 */
- (void)addObserverForConfiguration {
    __weak typeof(self) weakSelf = self;
    self.config.didFontNameChanged = ^(NSString * _Nonnull fontName) {
        [weakSelf reloadReader];
    };
    
    self.config.didFontSizeChanged = ^(CGFloat fontSize) {
        [weakSelf reloadReader];
    };
    
    self.config.didLineHeightChanged = ^(CGFloat lineHeightMutiplier) {
        [weakSelf reloadReader];
    };
    
    self.config.didBackgroundImageChanged = ^(DUAReaderBgType bgType) {
        [weakSelf loadBackgroundImage];
    };
    
    self.config.didScrollTypeChanged = ^(DUAReaderScrollType type) {
        [weakSelf loadReaderView];
        [weakSelf loadPage:weakSelf.currentPageIndex];
    };
}


/**
 重新加载读书
 */
- (void)reloadReader {
    self.isReCutPage = YES;
    if (self.prePageStartLocation == -1) {
        NSArray<DUAPageModel *> *pageArray = [self pageArrayFromCache:self.currentChapterIndex];
        self.prePageStartLocation = (int)[pageArray objectAtIndex:self.currentPageIndex - 1].range.location;
    }
    DUAChapterModel *chapter = [self.chapterModels objectForKey:[NSString stringWithFormat:@"%d", self.currentChapterIndex]];
    
    [self readWithChapter:chapter pageIndex:self.currentPageIndex];
}

#pragma mark - 数据请求

/**
 缓存某章节的page model

 @param pageModels 页面模型
 @param chapterIndex 章节
 */
- (void)cachePageArray:(NSMutableArray<DUAPageModel *> *)pageModels chapterIndex:(int)chapterIndex {
    if (pageModels == nil) {
        pageModels = [NSMutableArray array];
    }
    NSLog(@"cachePageArray chapter:%d pageCount:%ld", chapterIndex, pageModels.count);
    [self.chapterCaches setObject:pageModels forKey:[NSString stringWithFormat:@"%d", chapterIndex]];
}


/**
 读取某章节

 @param chapterIndex 章节
 */
- (void)requestChapterWithIndex:(int)chapterIndex {
    BOOL isEmpty = [self pageArrayFromCache:chapterIndex].count == 0;
    if (!isEmpty) {
        NSLog(@"requestChapterWithIndex has cache! chapter:%d", chapterIndex);
        return;
    }
    
    NSLog(@"requestChapterWithIndex request chapter:%d", chapterIndex);
    /// 这里在书籍解析后直接保存了所有章节model，故直接取即可
    
    /// 对于分章节阅读的情况，每个章节可能需要通过网络请求获取，完成后调用readWithchapter方法即可
    if ((chapterIndex - 1) < self.totalChapterModels.count) {
        DUAChapterModel *chapter = [self.totalChapterModels objectAtIndex:chapterIndex - 1];
        [self readWithChapter:chapter pageIndex:1];
    }
}


/**
 更新当前的章节索引，并进行预缓存

 @param chapterIndex 章节索引
 */
- (void)updateChapterIndex:(int)chapterIndex {
    if (self.currentChapterIndex == chapterIndex) {
        return;
    }

    NSLog(@"updateChapterIndex 进入第 \%d 章", chapterIndex);
    BOOL forward = self.currentChapterIndex < chapterIndex;
    self.currentChapterIndex = chapterIndex;
    
    /// 每当章节切换时触发预缓存
    [self forwardCacheIfNeed:forward];
}


#pragma mark - 预缓存


/// 为何要预缓存？
/// 本阅读器是按照逐个章节的方式阅读的（便于分章阅读，例如连载小说等），如果当前章节阅读结束时请求下一章数据
/// 那么章节解析分页均会耗时（当然你可以不等分页全部完成就直接展示已经分好的页面，以减少用户等待，那是另一套
/// 逻辑了）。因此每当用户跨入新的一章，程序自动触发当前章下一章的请求，提前准备好数据，以实现章节无缝切换
///
/// - Parameter forward: 向前缓存还是向后缓存 YES:往后缓存 NO：往前缓存
- (void)forwardCacheIfNeed:(BOOL)forward {
    int predictIndex = forward ? self.currentChapterIndex + 1 : self.currentChapterIndex - 1;
    if (predictIndex <= 0 || predictIndex > self.totalChapterModels.count) {
        return;
    }
    
    dispatch_async(self.cacheQueue, ^{
        NSArray *nextPageArray = [self pageArrayFromCache:predictIndex];
        if (nextPageArray.count == 0) {
            NSLog(@"执行预缓存 章节 %d", predictIndex);
            [self requestChapterWithIndex:predictIndex];
        }
    });
}

//预缓存上下章节
- (void)forwardCacheWith:(DUAChapterModel *)chapter {
    NSMutableArray<DUAPageModel *> *pageArray = [NSMutableArray array];
    NSMutableAttributedString *attrString = [self.dataParser attributedStringFromChapterModel:chapter config:self.config];
    [self.dataParser cutChapterPageAtIndex:chapter.chapterIndex attrString:attrString config:self.config completeHandler:^(int count, DUAPageModel * _Nonnull pageModel, BOOL completed) {
        [pageArray addObject:pageModel];
        if (completed) {
            NSLog(@"cutChapterPageAtIndex chapter2:%d pageModelChapter%d:", chapter.chapterIndex, pageModel.chapterBlong);
            [self cachePageArray:pageArray chapterIndex:chapter.chapterIndex];
            if (self.pageHunger) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self postReaderStateNotification:DUAReaderState_busy];
                    self.pageHunger = NO;
                    if (self.pageVC != nil) {
                        [self loadPage:self.currentPageIndex];
                    } else if (self.tableView != nil) {
                        if (self.tableView.scrollDirection == TableViewScrollDirecton_up && self.currentPageIndex == 1) {
                            [self requestLastChapterForTableView];
                        } else if (self.tableView.scrollDirection == TableViewScrollDirecton_down && self.currentPageIndex == [self pageArrayFromCache:self.currentChapterIndex].count) {
                            [self requestNextChapterForTableView];
                        }
                    }
                });
            }
        }
    }];
}

#pragma mark - tableView 章节请求

/// 请求上个章节 for tableview
- (void)requestLastChapterForTableView {
    self.tableView.scrollDirection = TableViewScrollDirecton_up;
    
    int lastChapterIndex = self.currentChapterIndex - 1;
    //到达第一章时不处理
    if (lastChapterIndex < 1) {
        NSLog(@"requestLastChapterForTableView 到达第一章");
        return;
    }
    
    [self requestChapterWithIndex:lastChapterIndex];

    NSArray<DUAPageModel *> *lastPages = [self pageArrayFromCache:lastChapterIndex];
    if (lastPages.count == 0) {
        /// 页面饥饿
        self.pageHunger = YES;
        [self postReaderStateNotification:DUAReaderState_busy];
        return;
    }
    
    __block NSMutableArray<NSIndexPath *> *indexPathsToInsert = [NSMutableArray array];
    [lastPages enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
        [indexPathsToInsert addObject:indexPath];
    }];
    
    NSMutableArray *newDataArray = [NSMutableArray arrayWithArray:lastPages];
    [newDataArray addObjectsFromArray:self.tableView.dataArray];
    
    self.tableView.dataArray = newDataArray;
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationTop];
    [self.tableView endUpdates];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.tableView.cellIndex += (int)lastPages.count;
        CGPoint offset = CGPointMake(0, (CGFloat)(lastPages.count) * self.config.contentFrame.size.height);
        [self.tableView setContentOffset:offset animated:NO];
    });
}

/// 请求下个章节 for tableview
- (void) requestNextChapterForTableView {
    self.tableView.scrollDirection = TableViewScrollDirecton_down;
    if (self.currentChapterIndex + 1 > self.totalChapterModels.count) {
        //到达最后一章
        return;
    }
    
    [self requestChapterWithIndex:self.currentChapterIndex + 1];
    NSArray *nextPages = [self pageArrayFromCache:self.currentChapterIndex + 1];
    if (nextPages.count == 0) {
        /// 页面饥饿
        self.pageHunger = YES;
        [self postReaderStateNotification:DUAReaderState_busy];
        return;
    }
    
    __block NSMutableArray<NSIndexPath *> *indexPathsToInsert = [NSMutableArray array];
    [nextPages enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.tableView.dataArray.count + idx inSection:0];
        [indexPathsToInsert addObject:indexPath];
    }];
    
    [self.tableView.dataArray addObjectsFromArray:nextPages];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

#pragma mark - PageVC Delegate

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSLog(@"page 向前翻页 chapter:%d page:%d", self.currentChapterIndex, self.currentPageIndex);

    static BOOL FirstPageArrived = NO;
    if ([viewController isKindOfClass:[DUAPageViewController class]]) {
        DUAPageViewController *page = (DUAPageViewController *)viewController;
        DUABackViewController *backPage = [[DUABackViewController alloc] init];
        
        int nextIndex = page.index - 1;
        //已经在章节第一页
        if (nextIndex <= 0) {
            int lastChapterIndex = self.currentChapterIndex - 1;
            if (lastChapterIndex < 1) {
                //已到达最开始位置
                NSLog(@"page 已经在最开始位置！");
                return nil;
            } else {
                //到达本章第一页，请求上一章节最后一页
                NSLog(@"page 已经在章节第一页 %d！", self.currentChapterIndex);
                FirstPageArrived = YES;
                self.pageVC.willStepIntoLastChapter = YES;
                [self requestChapterWithIndex:lastChapterIndex];
                nextIndex = (int)[self pageArrayFromCache:lastChapterIndex].count;
                DUAPageViewController *nextPage = [self getPageVCWithPageIndex:nextIndex chapterIndex:lastChapterIndex];
                //需要的页面并没有准备好，此时出现页面饥饿
                if (nextPage == nil) {
                    [self postReaderStateNotification:DUAReaderState_busy];
                    self.pageHunger = YES;
                    return nil;
                } else {
                    [backPage grabViewController:nextPage];
                    return backPage;
                }
            }
        } else {
            [backPage grabViewController:[self getPageVCWithPageIndex:nextIndex chapterIndex:page.chapterBelong]];
            return backPage;
        }
    } else {
        DUABackViewController *back = (DUABackViewController *)viewController;
        if (FirstPageArrived) {
            FirstPageArrived = NO;
            return [self getPageVCWithPageIndex:back.index chapterIndex:back.chapterBelong];
        } else {
            return [self getPageVCWithPageIndex:back.index chapterIndex:back.chapterBelong];
        }
    }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSLog(@"page 向后翻页 chapter:%d page:%d", self.currentChapterIndex, self.currentPageIndex);
    static BOOL LastPageArrived = NO;
    int nextIndex;
    NSArray *pageArray = [self pageArrayFromCache:self.currentChapterIndex];
    if ([viewController isKindOfClass:[DUAPageViewController class]]) {
        DUAPageViewController *page = (DUAPageViewController *)viewController;
        nextIndex = page.index + 1;
        if (nextIndex > pageArray.count) {
            LastPageArrived = YES;
        }
        DUABackViewController *backPage = [[DUABackViewController alloc] init];
        [backPage grabViewController:page];
        return backPage;
    } else if (LastPageArrived) {
        //到达最后一页 需要请求下一章节
        LastPageArrived = NO;
        //到达最后一章节
        if (self.currentChapterIndex >= self.totalChapterModels.count) {
            NSLog(@"page 到达最后一章!");
            return nil;
        }
        
        NSLog(@"page 已经在章节最后页！chapter:%d", self.currentChapterIndex);
        self.pageVC.willStepIntoNextChapter = YES;
        [self requestChapterWithIndex:self.currentChapterIndex + 1];
        DUAPageViewController *nextPage = [self getPageVCWithPageIndex:1 chapterIndex:self.currentChapterIndex + 1];
        ///         需要的页面并没有准备好，此时出现页面饥饿
        if (nextPage == nil) {
            [self postReaderStateNotification:DUAReaderState_busy];
            self.pageHunger = YES;
        }
        return nextPage;
    }
    
    DUABackViewController *back = (DUABackViewController *)viewController;
    DUAPageViewController *nextPage = [self getPageVCWithPageIndex:back.index + 1  chapterIndex:back.chapterBelong];
    NSLog(@"page 向后翻页 chapter:%d page:%d", nextPage.chapterBelong, nextPage.index);
    return nextPage;
}


- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    NSLog(@"page didFinishAnimating");
    [self containerControllerWithScrollType:0 currentController:pageViewController.viewControllers.firstObject didFinishedTransition:completed previousController:previousViewControllers.firstObject];
}



- (void)containerControllerWithScrollType:(int)scrollType currentController:(UIViewController *)currentController didFinishedTransition:(BOOL)finished previousController:(UIViewController *)previousController {
    self.prePageStartLocation = -1;
    DUAPageViewController *curPage = (DUAPageViewController *)currentController;
    DUAPageViewController *previousPage = (DUAPageViewController *)previousController;
    NSLog(@"container 当前页面所在章节 %d 先前页面所在章节 %d", curPage.chapterBelong, previousPage.chapterBelong);

    self.currentPageIndex = curPage.index;

    BOOL didStepIntoLastChapter = NO;
    BOOL didStepIntoNextChapter = NO;
    if (scrollType == 0) {
        didStepIntoLastChapter = self.pageVC.willStepIntoLastChapter && curPage.chapterBelong < previousPage.chapterBelong;
        didStepIntoNextChapter = self.pageVC.willStepIntoNextChapter && curPage.chapterBelong > previousPage.chapterBelong;
    } else {
        didStepIntoLastChapter = self.translationVC.willStepIntoLastChapter && curPage.chapterBelong < previousPage.chapterBelong;
        didStepIntoNextChapter = self.translationVC.willStepIntoNextChapter && curPage.chapterBelong > previousPage.chapterBelong;
    }
    
    if (didStepIntoNextChapter) {
        NSLog(@"container 进入下一章");
        [self updateChapterIndex:self.currentChapterIndex + 1];
        if (scrollType == 0) {
            self.pageVC.willStepIntoLastChapter = YES;
            self.pageVC.willStepIntoNextChapter = NO;
        } else {
            self.translationVC.willStepIntoLastChapter = YES;
            self.translationVC.willStepIntoNextChapter = NO;
        }
    }
    if (didStepIntoLastChapter) {
        NSLog(@"container 进入上一章");
        [self updateChapterIndex:self.currentChapterIndex - 1];
        if (scrollType == 0) {
            self.pageVC.willStepIntoLastChapter = NO;
            self.pageVC.willStepIntoNextChapter = YES;
        } else {
            self.translationVC.willStepIntoLastChapter = NO;
            self.translationVC.willStepIntoNextChapter = YES;
        }
    }
    
    if (self.currentPageIndex != 1) {
        if (scrollType == 0) {
            self.pageVC.willStepIntoLastChapter = NO;
        } else {
            self.translationVC.willStepIntoLastChapter = NO;
        }
    }
    
    int totalPages = (int)[self pageArrayFromCache:self.currentChapterIndex].count;
    if (self.currentPageIndex != totalPages) {
        if (scrollType == 0) {
            self.pageVC.willStepIntoNextChapter = NO;
        } else {
            self.translationVC.willStepIntoNextChapter = NO;
        }
    }
    [self updateStatusBar];

    ///     进度信息必要时可以通过delegate回调出去
    NSLog(@"container 当前阅读进度 章节:%d 页数:%d/%d", self.currentChapterIndex, self.currentPageIndex, totalPages);

    if (self.delegate && [self.delegate respondsToSelector:@selector(reader:readerProgressUpdatedCurrentChapter:curPage:totalPages:)]) {
        [self.delegate reader:self readerProgressUpdatedCurrentChapter:self.currentChapterIndex curPage:self.currentPageIndex totalPages:totalPages];
    }
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.config.contentFrame.size.height;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableView.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reusableIdentifier = @"dua.reader.cell";
    DUATableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
    if (cell == nil) {
        cell = [[DUATableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reusableIdentifier];
    }

    DUAPageModel *pageModel = [self.tableView.dataArray objectAtIndex:indexPath.row];
    [cell configCellWithPageModel:pageModel config:self.config];
    
//    NSLog(@"tableview cell indexRow:%ld page:%d tableData:%ld", (long)indexPath.row, pageModel.pageIndex, self.tableView.dataArray.count);
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.tableView.isReloading) {
        return;
    }
    if (scrollView.contentOffset.y <= 0) {
        scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, 0);
        //当tableview的 需要请求上一章
        if (!self.tableView.arrivedZeroOffset) {
            [self requestLastChapterForTableView];
        }
        self.tableView.arrivedZeroOffset = YES;
    } else {
        self.tableView.arrivedZeroOffset = NO;
    }
    
    CGPoint basePoint = CGPointMake(self.config.contentFrame.size.width / 2.0, scrollView.contentOffset.y + self.config.contentFrame.size.height / 2.0);
    NSIndexPath *majorIndexPath = [self.tableView indexPathForRowAtPoint:basePoint];
    if (majorIndexPath.row > self.tableView.cellIndex) {
        // 向后翻页
        self.prePageStartLocation = -1;
        self.tableView.cellIndex = (int)majorIndexPath.row;
        self.currentPageIndex = [self.tableView.dataArray objectAtIndex:self.tableView.cellIndex].pageIndex;
        NSLog(@"scroll 进入下一页 currentPage:%d", self.currentPageIndex);
        if (self.currentPageIndex == 1) {
            NSLog(@"scroll 跳入下一章，从 %d 到 %d", self.currentChapterIndex, self.currentChapterIndex + 1);
            [self updateChapterIndex:self.currentChapterIndex + 1];
        }
        
        [self updateStatusBar];

        // 到达本章节最后一页，请求下一章
        if (self.tableView.cellIndex == self.tableView.dataArray.count - 1) {
            [self requestNextChapterForTableView];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(reader:readerProgressUpdatedCurrentChapter:curPage:totalPages:)]) {
            NSArray *totalPages = [self pageArrayFromCache:self.currentChapterIndex];
            [self.delegate reader:self readerProgressUpdatedCurrentChapter:self.currentChapterIndex curPage:self.currentPageIndex totalPages:(int)totalPages.count];
        }
    } else if (majorIndexPath.row < self.tableView.cellIndex) {
        //向前翻页
        self.prePageStartLocation = -1;
        self.tableView.cellIndex = (int)majorIndexPath.row;
        DUAPageModel *currentPageModel = [self.tableView.dataArray objectAtIndex:self.tableView.cellIndex];
        self.currentPageIndex = currentPageModel.pageIndex;
        NSLog(@"scroll 进入上一页 页码 %d %d", self.currentChapterIndex, self.currentPageIndex);
    
        int currentChapterBlong = currentPageModel.chapterBlong;
        int previousChapterBlong = [self.tableView.dataArray objectAtIndex:self.tableView.cellIndex + 1].chapterBlong;
        BOOL isChapterLast = self.currentPageIndex == [self pageArrayFromCache:self.currentChapterIndex - 1].count;
        if (isChapterLast && previousChapterBlong != currentChapterBlong) {
            NSLog(@"scroll 跳入上一章，从%d到%d", self.currentChapterIndex, self.currentChapterIndex - 1);
            [self updateChapterIndex:self.currentChapterIndex - 1];
        }
    
        [self updateStatusBar];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(reader:readerProgressUpdatedCurrentChapter:curPage:totalPages:)]) {
            NSArray *totalPages = [self pageArrayFromCache:self.currentChapterIndex];
            [self.delegate reader:self readerProgressUpdatedCurrentChapter:self.currentChapterIndex curPage:self.currentPageIndex totalPages:(int)totalPages.count];
        }
    }
}


#pragma mark - DUATranslationController Delegate

- (UIViewController *)translationController:(DUAtranslationController *)translationController controllerAfter:(UIViewController *)controller {
    NSLog(@"translation 向后翻页");
    int nextIndex;
    DUAPageViewController *nextPage = nil;
    NSArray *pageArray = [self pageArrayFromCache:self.currentChapterIndex];
    if ([controller isKindOfClass:[DUAPageViewController class]]) {
        DUAPageViewController *page = (DUAPageViewController *)controller;
        nextIndex = page.index + 1;
        
        if (nextIndex > pageArray.count) {
            //本章最后一节
            if (self.currentChapterIndex >= self.totalChapterModels.count) {
                //已到最后一章
                NSLog(@"translation 到达最后一章!");
                return nil;
            }
            self.translationVC.willStepIntoNextChapter = YES;
            [self requestChapterWithIndex:self.currentChapterIndex + 1];
            nextPage = [self getPageVCWithPageIndex:1 chapterIndex:self.currentChapterIndex + 1];
            // 需要的页面并没有准备好，此时出现页面饥饿
            if (nextPage == nil) {
                self.pageHunger = YES;
                [self postReaderStateNotification:DUAReaderState_busy];
                return nil;
            }
        } else {
            nextPage = [self getPageVCWithPageIndex:nextIndex chapterIndex:page.chapterBelong];
        }
    }
    return nextPage;
}

- (UIViewController *)translationController:(DUAtranslationController *)translationController controllerBefore:(UIViewController *)controller {
    NSLog(@"translation 向前翻页");
    DUAPageViewController *nextpage = nil;
    if ([controller isKindOfClass:[DUAPageViewController class]]) {
        DUAPageViewController *page = (DUAPageViewController *)controller;
        int nextIndex = page.index - 1;
        if (nextIndex < 1) {
            //需要进入上一章节
            if (self.currentChapterIndex <= 1) {
                //当前章节已经是第一章节
                NSLog(@"translation 已经在最开始位置！");
                return nil;
            }
            self.translationVC.willStepIntoLastChapter = YES;
            [self requestChapterWithIndex:self.currentChapterIndex - 1];
            //获取上一章的最后一页
            nextIndex = (int)[self pageArrayFromCache:self.currentChapterIndex - 1].count;
            nextpage = [self getPageVCWithPageIndex:nextIndex chapterIndex:self.currentChapterIndex - 1];
            ///         需要的页面并没有准备好，此时出现页面饥饿
            if (nextpage == nil) {
                self.pageHunger = YES;
                [self postReaderStateNotification:DUAReaderState_busy];
                return nil;
            }
        } else {
            nextpage = [self getPageVCWithPageIndex:nextIndex chapterIndex:page.chapterBelong];
        }
    }
    return nextpage;
}

- (void)translationController:(DUAtranslationController *)translationController willTransitionTo:(UIViewController *)controller {
    NSLog(@"translationController willTransitionTo");
}

- (void)translationController:(DUAtranslationController *)translationController didFinishAnimating:(BOOL)finished previousController:(nonnull UIViewController *)previousController transitionCompleted:(BOOL)completed {
    [self containerControllerWithScrollType:1 currentController:translationController.childViewControllers.firstObject didFinishedTransition:completed previousController:previousController];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
