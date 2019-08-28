//
//  DUASettingsBottomMenuView.m
//  MyReader
//
//  Created by xiejc on 2018/11/22.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import "DUASettingsBottomMenuView.h"

@implementation DUASettingsBottomMenuView

- (void)awakeFromNib {
    [super awakeFromNib];

    NSArray *scrollBtnList = [self scrollTypeButtonList];
    for (UIButton *button in scrollBtnList) {
        [button setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
    }
    
    
    NSArray *bgImgBtnList = [self bgButtonList];
    for (UIButton *button in bgImgBtnList) {
        [button setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
    }
}

- (NSArray *)scrollTypeButtonList {
    NSArray *scrollBtnList = @[self.scrollCurlBtn, self.scrollVerticalBtn, self.scrollHorizontalBtn, self.scrollNoneBtn];
    return scrollBtnList;
}

- (UIButton *)scrollTypeButtonByType:(DUAReaderScrollType)type {
    UIButton *selectedBtn;
    switch (type) {
        case DUAReaderScrollType_curl:
            selectedBtn = self.scrollCurlBtn;
            break;
        case DUAReaderScrollType_vertical:
            selectedBtn = self.scrollVerticalBtn;
            break;
        case DUAReaderScrollType_horizontal:
            selectedBtn = self.scrollHorizontalBtn;
            break;
        case DUAReaderScrollType_none:
            selectedBtn = self.scrollNoneBtn;
            break;
        default:
            break;
    }
    return selectedBtn;
}

- (NSArray *)bgButtonList {
    return @[self.backImgFlowerBtn, self.backImgLeafBtn, self.backImgPureBtn];
}

- (UIButton *)bgButtonByType:(DUAReaderBgType)type {
    UIButton *bgBtn;
    switch (type) {
        case DUAReaderBgType_Pure:
            bgBtn = self.backImgPureBtn;
            break;
        case DUAReaderBgType_Flower:
            bgBtn = self.backImgFlowerBtn;
            break;
        case DUAReaderBgType_Leaf:
            bgBtn = self.backImgLeafBtn;
            break;
        default:
            break;
    }
    return bgBtn;
}

@end
