//
//  ViewController.m
//  MyReader
//
//  Created by xiejc on 2018/11/13.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import "ViewController.h"
#import "DUAReader.h"
#import "DUASliderBar.h"
#import "DUASettingsView.h"

#import <UMCommon/UMCommon.h>
#import <UMAnalytics/MobClick.h>

@interface ViewController ()
<UITableViewDelegate, UITableViewDataSource,
DUAReaderDelegate, DUASliderBarDelgate, DUASettingsViewDelgate>

@property (nonatomic, strong) DUASliderBar *slideBar;
@property (nonatomic, strong) DUASettingsView *msettingView;
@property (nonatomic, strong) DUAReader *mreader;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@property (nonatomic, weak) IBOutlet UITableView *tableView;


//图书列表
@property (nonatomic, strong) NSMutableArray *bookList;

//当前章 从1开始
@property (nonatomic, assign) int curChapter;
//当前页 从1开始
@property (nonatomic, assign) int curPage;
//当前章节总页数
@property (nonatomic, assign) int curChapterTotalPages;
//当前书名
@property (nonatomic, strong) NSString *curBookName;
//当前章节title
@property (nonatomic, strong) NSMutableArray<NSString *> *chapterTitles;

//{"bookname":{"chapterpage":["page1", "page2", ...]}}
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *> *marksArray;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.indicatorView.center = CGPointMake(0.5 * self.view.width, 0.5 * self.view.height);
    self.indicatorView.hidesWhenStopped = YES;
    
    self.chapterTitles = [NSMutableArray array];
    self.curBookName = @"";
    self.marksArray = [NSMutableDictionary dictionary];
    
    self.bookList = [NSMutableArray arrayWithObjects:
                     @"郭黄之恋.txt",
                     @"最后一个道士.txt",
                     @"每天懂一点好玩心理学.epub",
                     @"奇术之王.epub",
                     @"1.epub",
                     nil];
}

- (void)readBookByName:(NSString *)bookName {
    NSArray *strList = [bookName componentsSeparatedByString:@"."];
    NSString *typeStr = strList.lastObject;
    NSString *bookRealName = [bookName substringToIndex:bookName.length - typeStr.length - 1];
    DUAReaderBookType type = [DUAConfiguration getTypeByTypeString:typeStr];

    self.mreader = [[DUAReader alloc] init];
    DUAConfiguration *configuration = [[DUAConfiguration alloc] init];
    configuration.bookType = type;
    self.mreader.config = configuration;
    self.mreader.delegate = self;
    [self presentViewController:self.mreader animated:YES completion:nil];
    
    NSString *bookPath = [[NSBundle mainBundle] pathForResource:bookRealName ofType:typeStr];
    [self.mreader readWithFilePath:bookPath pageIndex:1];
    //        记录阅读的书，demo使用
    self.curBookName = bookName;
}


#pragma mark - DUASliderBarDelgate

- (void)sliderBarDidClickBookAtChapterIndex:(int)chapterIndex pageIndex:(int)pageIndex {
    [self.mreader readChapterByIndex:chapterIndex pageIndex:pageIndex];
    [self.slideBar removeFromSuperview];
}

#pragma mark - reader delegate

- (void)readerDidClickSettingFrame:(DUAReader *)reader {
    [self showSettingsView];
}

- (void)reader:(DUAReader *)reader readerStateChanged:(DUAReaderState)state {
    switch (state) {
        case DUAReaderState_busy:
        {
            [reader.view addSubview:self.indicatorView];
            [self.indicatorView startAnimating];
        }
            break;
        case DUAReaderState_ready:
        {
            [self.indicatorView stopAnimating];
            [self.indicatorView removeFromSuperview];
        }
        default:
            break;
    }
}

- (void)reader:(DUAReader *)reader readerProgressUpdatedCurrentChapter:(int)currentChapter curPage:(int)curPage totalPages:(int)totalPages {
    NSLog(@"reader update 当前章节:%d 页数:%d/%d", currentChapter, curPage, totalPages);
    self.curChapter = currentChapter;
    self.curPage = curPage;
    self.curChapterTotalPages = totalPages;
}

- (void)reader:(DUAReader *)reader chapterTitles:(nonnull NSMutableArray<NSString *> *)chapterTitles {
    self.chapterTitles = chapterTitles;
}

#pragma mark - DUASettingViewDelgate

///显示设置面板
- (void)showSettingsView {
    NSLog(@"showSettingsView 当前章节:%d 页数:%d/%d", self.curChapter, self.curPage, self.curChapterTotalPages);
    if (self.msettingView == nil) {
        self.msettingView = [[DUASettingsView alloc] initWithFrame:self.view.bounds];
    }

    self.msettingView.delegate = self;
    [self.msettingView updatePageSlider];
    [self settingsViewChangeScrollType:self.mreader.config.scrollType];
    UIFont *font = [UIFont fontWithName:self.mreader.config.fontName size:self.mreader.config.fontSize];
    [self.msettingView updateFontSize:font];
    [self.msettingView updateBgType:self.mreader.config.bgType];
    
    UIWindow *window = [UIApplication sharedApplication].delegate.window;
    [window addSubview:self.msettingView];
    
    self.msettingView.topMenu.frame = CGRectMake(0, -80, self.view.width, 80);
    self.msettingView.bottomMenu.frame = CGRectMake(0, self.view.height, self.view.width, 200);
    [UIView animateWithDuration:0.2 animations:^{
        self.msettingView.topMenu.frame = CGRectMake(0, 0, self.view.width, 80);
        self.msettingView.bottomMenu.frame = CGRectMake(0, self.view.height - 200, self.view.width, 200);
    }];
    
    // 查询历史书签
    BookMarkButton *btn = self.msettingView.topMenu.markBtn;
    btn.isClicked = NO;
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *marks = [self.marksArray objectForKey:self.curBookName];
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *markList;
    if (marks != nil) {
        markList = marks;
    }
    
    NSMutableArray *chapterMarks = [markList objectForKey:IntToString(self.curChapter)];
    if (chapterMarks != nil) {
        if ([chapterMarks containsObject:IntToString(self.curPage)]) {
            btn.isClicked = YES;
        }
    }
}

- (int)settingsViewGetCurrentChapter {
    return self.curChapter;
}

- (int)settingsViewCurrentPage {
    return self.curPage;
}

- (int)settingsViewGetCurrentChapterTotalPages {
    return self.curChapterTotalPages;
}

//侧边栏
- (void)settingsViewShowSideBar {
    CGFloat width = Screen_Width;
    CGFloat height = Screen_Height;
    [self.msettingView removeFromSuperview];
    
    if (self.slideBar == nil) {
        self.slideBar = [[DUASliderBar alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        self.slideBar.delegate = self;
    }
    
    self.slideBar.chapterTitles = self.chapterTitles;
    self.slideBar.marksArray = self.marksArray;
    self.slideBar.curBookName = self.curBookName;
    
    [self.slideBar onDirBtnClicked];
    
    UIWindow *window = [UIApplication sharedApplication].delegate.window;
    [window addSubview:self.slideBar];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.slideBar.frame = CGRectMake(0, 0, width, height);
    }];
}

- (void)settingsViewReadAtChapterIndex:(int)chapterIndex pageIndex:(int)pageIndex {
    [self.mreader readChapterByIndex:chapterIndex pageIndex:pageIndex];
    [self.msettingView updatePageSlider];
}

- (void)settingsViewChangeScrollType:(DUAReaderScrollType)type {
    self.mreader.config.scrollType = type;
    [self.msettingView updateScrollType:type];
}

- (void)settingsViewChangeBackgroundType:(DUAReaderBgType)bgType {
    self.mreader.config.bgType = bgType;
    [self.msettingView updateBgType:self.mreader.config.bgType];
}

- (void)settingsViewChangeFontSize:(int)fontSizeChange {
    self.mreader.config.fontSize += fontSizeChange;
    [self.msettingView updatePageSlider];
    UIFont *font = [UIFont fontWithName:self.mreader.config.fontName size:self.mreader.config.fontSize];
    [self.msettingView updateFontSize:font];
}

- (void)settingsViewFinishSetting {
    UIView *topMenu = self.msettingView.subviews.firstObject;
    UIView *bottomMenu = self.msettingView.subviews.lastObject;
    
    [UIView animateWithDuration:0.2 animations:^{
        topMenu.frame = CGRectMake(0, -80, self.view.width, 80);
        bottomMenu.frame = CGRectMake(0, self.view.height, self.view.width, 200);
    } completion:^(BOOL finished) {
        if (finished) {
            [self.msettingView removeFromSuperview];
        }
    }];
}

- (void)settingsViewCancelCurrentBook {
    [self.mreader dismissViewControllerAnimated:YES completion:nil];
    self.mreader = nil;
    [self.msettingView removeFromSuperview];
}

//保存书签
- (void)saveBookMark {
    BookMarkButton *bookMarkBtn = self.msettingView.topMenu.markBtn;
    bookMarkBtn.isClicked = !bookMarkBtn.isClicked;
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *marks = [self.marksArray objectForKey:self.curBookName];
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *markList;
    if (marks != nil && marks.count > 0) {
        markList = marks;
    } else {
        markList = [NSMutableDictionary dictionary];
    }
    
    if (markList.count == 0) {
        NSMutableArray *chapterMarkList = [NSMutableArray arrayWithObject:IntToString(self.curPage)];
        [markList setObject:chapterMarkList forKey:IntToString(self.curChapter)];
    } else {
        if (bookMarkBtn.isClicked) {
            //写入新书签
            for (NSString *key in markList.allKeys) {
                if ([key intValue] == self.curChapter) {
                    NSMutableArray *chapterMarkList = [markList objectForKey:key];
                    if (![chapterMarkList containsObject:IntToString(self.curPage)]) {
                        [chapterMarkList addObject:IntToString(self.curPage)];
                        break;
                    }
                }
            }
            if (![markList.allKeys containsObject:IntToString(self.curChapter)]) {
                NSMutableArray *chapterMarkList = [NSMutableArray arrayWithObject:IntToString(self.curPage)];
                [markList setObject:chapterMarkList forKey:IntToString(self.curChapter)];
            }
        } else {
            //移除旧书签
            NSMutableArray<NSString *> *chapterMarkList = [markList objectForKey:IntToString(self.curChapter)];
            [chapterMarkList removeObject:IntToString(self.curPage)];
        }
    }
    
    if(!bookMarkBtn.isClicked){
        NSMutableArray<NSString *> *chapterMarkList = [markList objectForKey:IntToString(self.curChapter)];
        if (chapterMarkList.count == 0) {
            [markList removeObjectForKey:IntToString(self.curChapter)];
        }
    }
    [self.marksArray setObject:markList forKey:self.curBookName];
}

#pragma mark - UITableViewDelegate & datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.bookList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *tableIdentify = @"booklistcell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentify];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableIdentify];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *bookName = [self.bookList objectAtIndex:indexPath.row];
    cell.textLabel.text = bookName;
    cell.textLabel.textColor = [UIColor blackColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *bookName = [self.bookList objectAtIndex:indexPath.row];
    [MobClick event:@"ReadBook" label:bookName];
    [self readBookByName:bookName];
}


@end
