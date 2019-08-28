//
//  DUASettingsView.m
//  MyReader
//
//  Created by xiejc on 2018/11/22.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import "DUASettingsView.h"

@interface DUASettingsView ()


@end


@implementation DUASettingsView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initView];
    }
    return self;
}

- (void)initView {
    self.topMenu = [[NSBundle mainBundle] loadNibNamed:@"DUASettingsTopMenuView" owner:nil options:nil].firstObject;
    [self.topMenu.backBtn addTarget:self action:@selector(exitReader:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.topMenu.markBtn addTarget:self action:@selector(saveBookMarks:) forControlEvents:UIControlEventTouchUpInside];
    
    self.bottomMenu = [[NSBundle mainBundle] loadNibNamed:@"DUASettingsBottomMenuView" owner:nil options:nil].firstObject;

    [self.bottomMenu.chapterSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.bottomMenu.lastChapterBtn addTarget:self action:@selector(goToLastChapter:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomMenu.nextChapterBtn addTarget:self action:@selector(goToNextChapter:) forControlEvents:UIControlEventTouchUpInside];

    [self.bottomMenu.scrollCurlBtn addTarget:self action:@selector(changeScrollTypeToCurl:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomMenu.scrollVerticalBtn addTarget:self action:@selector(changeScrollTypeToVertical:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomMenu.scrollNoneBtn addTarget:self action:@selector(changeScrollTypeToNone:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomMenu.scrollHorizontalBtn addTarget:self action:@selector(changeScrollTypeToHorizontal:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.bottomMenu.backImgPureBtn addTarget:self action:@selector(changeBackImageToPure:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomMenu.backImgLeafBtn addTarget:self action:@selector(changeBackImageToLeaf:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomMenu.backImgFlowerBtn addTarget:self action:@selector(changeBackImageToFlower:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.bottomMenu.sideBarBtn addTarget:self action:@selector(showSiderBar:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomMenu.fontBigBtn addTarget:self action:@selector(changeFontSizeBig:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomMenu.fontSmallBtn addTarget:self action:@selector(changeFontSizeSmall:) forControlEvents:UIControlEventTouchUpInside];

    
    [self addSubview:self.topMenu];
    [self addSubview:self.bottomMenu];

    //添加手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSettingViewClicked:)];
    [self addGestureRecognizer:tap];
}

- (int)currentChapter {
    int chapter = 0;
    if (self.delegate && [self.delegate respondsToSelector:@selector(settingsViewGetCurrentChapter)]) {
        chapter = [self.delegate settingsViewGetCurrentChapter];
    }
    return chapter;
}

- (void)onSettingViewClicked:(UITapGestureRecognizer *)ges {
    [self.delegate settingsViewFinishSetting];
}

///更新页面slider进度条
- (void)updatePageSlider {
    int currentPage = 1;
    int curChapterTotalPages = 1;
    if (self.delegate && [self.delegate respondsToSelector:@selector(settingsViewCurrentPage)]) {
        currentPage = [self.delegate settingsViewCurrentPage];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(settingsViewGetCurrentChapterTotalPages)]) {
        curChapterTotalPages = [self.delegate settingsViewGetCurrentChapterTotalPages];
    }
    
    CGFloat process = (float)(currentPage - 1) /(float)(curChapterTotalPages - 1);
    self.bottomMenu.chapterSlider.value = process;
}

- (void)updateScrollType:(DUAReaderScrollType)type {
    NSArray *scrollBtnList = [self.bottomMenu scrollTypeButtonList];
    for (UIButton *btn in scrollBtnList) {
        [btn setSelected:NO];
    }
    
    UIButton *selectedBtn = [self.bottomMenu scrollTypeButtonByType:type];
    if (selectedBtn) {
        [selectedBtn setSelected:YES];
    }
}


- (void)updateFontSize:(UIFont *)font {
    self.bottomMenu.fontSizeLabel.font = font;
    self.bottomMenu.fontSizeLabel.text = [NSString stringWithFormat:@"%d", (int)font.pointSize];
}

- (void)updateBgType:(DUAReaderBgType)type {
    NSArray *btnList = [self.bottomMenu bgButtonList];
    for (UIButton *btn in btnList) {
        [btn setSelected:NO];
    }
    
    UIButton *selectedBtn = [self.bottomMenu bgButtonByType:type];
    if (selectedBtn) {
        [selectedBtn setSelected:YES];
    }
    
}

// 上菜单 - cancel
- (IBAction)exitReader:(id)sender {
    NSLog(@"退出阅读器");
    [self.delegate settingsViewCancelCurrentBook];
}


// 上菜单 - mark
- (IBAction)saveBookMarks:(UIButton *)btn {
    NSLog(@"保存标签");
    [self.delegate saveBookMark];
}


//下菜单 - 页数滑动条
- (IBAction)sliderValueChanged:(UISlider *)sender {
    int curChapterTotalPages = 1;
    if (self.delegate && [self.delegate respondsToSelector:@selector(settingsViewGetCurrentChapterTotalPages)]) {
        curChapterTotalPages = [self.delegate settingsViewGetCurrentChapterTotalPages];
    }

    int pageIndex = floor(sender.value * (CGFloat)(curChapterTotalPages - 1));
    pageIndex += 1;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(settingsViewReadAtChapterIndex:pageIndex:)]) {
        [self.delegate settingsViewReadAtChapterIndex:self.currentChapter pageIndex:pageIndex];
    }
}


//下菜单 - 上一章
- (IBAction)goToLastChapter:(id)sender {
    NSLog(@"切换上一章");
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(settingsViewReadAtChapterIndex:pageIndex:)]) {
        [self.delegate settingsViewReadAtChapterIndex:self.currentChapter - 1 pageIndex:1];
    }
}

//下菜单 - 下一章
- (IBAction)goToNextChapter:(id)sender {
    NSLog(@"切换下一章");
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(settingsViewReadAtChapterIndex:pageIndex:)]) {
        [self.delegate settingsViewReadAtChapterIndex:self.currentChapter + 1 pageIndex:1];
    }
}

//下菜单 - 仿真
- (IBAction)changeScrollTypeToCurl:(id)sender {
    NSLog(@"仿真翻页");
    if (self.delegate && [self.delegate respondsToSelector:@selector(settingsViewChangeScrollType:)]) {
        [self.delegate settingsViewChangeScrollType:DUAReaderScrollType_curl];
    }
}

//下菜单 - 简约
- (IBAction)changeScrollTypeToHorizontal:(id)sender {
    NSLog(@"平移翻页");
    if (self.delegate && [self.delegate respondsToSelector:@selector(settingsViewChangeScrollType:)]) {
        [self.delegate settingsViewChangeScrollType:DUAReaderScrollType_horizontal];
    }
}

//下菜单 - 滚动
- (IBAction)changeScrollTypeToVertical:(id)sender {
    NSLog(@"竖向滚动翻页");
    if (self.delegate && [self.delegate respondsToSelector:@selector(settingsViewChangeScrollType:)]) {
        [self.delegate settingsViewChangeScrollType:DUAReaderScrollType_vertical];
    }
}

//下菜单 - 无
- (IBAction)changeScrollTypeToNone:(id)sender {
    NSLog(@"无动画翻页");
    if (self.delegate && [self.delegate respondsToSelector:@selector(settingsViewChangeScrollType:)]) {
        [self.delegate settingsViewChangeScrollType:DUAReaderScrollType_none];
    }
}

//下菜单 - 纯色
- (IBAction)changeBackImageToPure:(id)sender {
    NSLog(@"设置背景 pure");
    if (self.delegate && [self.delegate respondsToSelector:@selector(settingsViewChangeBackgroundType:)]) {
        [self.delegate settingsViewChangeBackgroundType:DUAReaderBgType_Pure];
    }
}

//下菜单 - 荷花
- (IBAction)changeBackImageToFlower:(id)sender {
    NSLog(@"设置背景 flower");
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(settingsViewChangeBackgroundType:)]) {
        [self.delegate settingsViewChangeBackgroundType:DUAReaderBgType_Flower];
    }
}

//下菜单 - 荷叶
- (IBAction)changeBackImageToLeaf:(id)sender {
    NSLog(@"设置背景 leaf");
    if (self.delegate && [self.delegate respondsToSelector:@selector(settingsViewChangeBackgroundType:)]) {
        [self.delegate settingsViewChangeBackgroundType:DUAReaderBgType_Leaf];
    }
}

//下菜单 - 章节目录
- (IBAction)showSiderBar:(id)sender {
    NSLog(@"展示章节目录");
    if (self.delegate && [self.delegate respondsToSelector:@selector(settingsViewShowSideBar)]) {
        [self.delegate settingsViewShowSideBar];
    }
}

//下菜单 - 调小字号
- (IBAction)changeFontSizeSmall:(id)sender {
    NSLog(@"调小字号");
    if (self.delegate && [self.delegate respondsToSelector:@selector(settingsViewChangeFontSize:)]) {
        [self.delegate settingsViewChangeFontSize:-1];
    }
    
}

//下菜单 - 调大字号
- (IBAction)changeFontSizeBig:(id)sender {
    NSLog(@"调大字号");
    if (self.delegate && [self.delegate respondsToSelector:@selector(settingsViewChangeFontSize:)]) {
        [self.delegate settingsViewChangeFontSize:1];
    }
}


@end
