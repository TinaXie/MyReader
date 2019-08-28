//
//  DUASettingsView.h
//  MyReader
//
//  Created by xiejc on 2018/11/22.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DUASettingsTopMenuView.h"
#import "DUASettingsBottomMenuView.h"

NS_ASSUME_NONNULL_BEGIN


@protocol DUASettingsViewDelgate <NSObject>

- (void)settingsViewCancelCurrentBook;

- (void)saveBookMark;

- (void)settingsViewReadAtChapterIndex:(int)chapterIndex pageIndex:(int)pageIndex;

- (void)settingsViewChangeScrollType:(DUAReaderScrollType)type;

- (void)settingsViewChangeBackgroundType:(DUAReaderBgType)bgType;

- (void)settingsViewChangeFontSize:(int)fontSizeChange;

- (void)settingsViewFinishSetting;

- (void)settingsViewShowSideBar;

- (int)settingsViewCurrentPage;

- (int)settingsViewGetCurrentChapter;

- (int)settingsViewGetCurrentChapterTotalPages;

@end


@interface DUASettingsView : UIView

@property (nonatomic, weak) id<DUASettingsViewDelgate> delegate;

@property (nonatomic, strong) DUASettingsTopMenuView *topMenu;
@property (nonatomic, strong) DUASettingsBottomMenuView *bottomMenu;


- (void)updateScrollType:(DUAReaderScrollType)type;

- (void)updatePageSlider;

- (void)updateFontSize:(UIFont *)font;

- (void)updateBgType:(DUAReaderBgType)type;

@end

NS_ASSUME_NONNULL_END
