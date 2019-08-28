//
//  DUASettingsBottomMenuView.h
//  MyReader
//
//  Created by xiejc on 2018/11/22.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DUAConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface DUASettingsBottomMenuView : UIView

@property (weak, nonatomic) IBOutlet UIButton *lastChapterBtn;
@property (weak, nonatomic) IBOutlet UIButton *nextChapterBtn;
@property (weak, nonatomic) IBOutlet UISlider *chapterSlider;

@property (weak, nonatomic) IBOutlet UIButton *scrollCurlBtn;
@property (weak, nonatomic) IBOutlet UIButton *scrollNoneBtn;
@property (weak, nonatomic) IBOutlet UIButton *scrollVerticalBtn;
@property (weak, nonatomic) IBOutlet UIButton *scrollHorizontalBtn;

@property (weak, nonatomic) IBOutlet UIButton *backImgPureBtn;
@property (weak, nonatomic) IBOutlet UIButton *backImgLeafBtn;
@property (weak, nonatomic) IBOutlet UIButton *backImgFlowerBtn;

@property (weak, nonatomic) IBOutlet UIButton *sideBarBtn;

@property (weak, nonatomic) IBOutlet UILabel *fontSizeLabel;
@property (weak, nonatomic) IBOutlet UIButton *fontSmallBtn;
@property (weak, nonatomic) IBOutlet UIButton *fontBigBtn;


- (NSArray *)scrollTypeButtonList;

- (UIButton *)scrollTypeButtonByType:(DUAReaderScrollType)type;


- (NSArray *)bgButtonList;

- (UIButton *)bgButtonByType:(DUAReaderBgType)type;

@end

NS_ASSUME_NONNULL_END
