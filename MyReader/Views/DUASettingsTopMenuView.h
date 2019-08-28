//
//  DUASettingsTopMenuView.h
//  MyReader
//
//  Created by xiejc on 2018/11/22.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BookMarkButton.h"


NS_ASSUME_NONNULL_BEGIN

@interface DUASettingsTopMenuView : UIView

@property (nonatomic, weak) IBOutlet BookMarkButton *markBtn;
@property (nonatomic, weak) IBOutlet UIButton *backBtn;

@end

NS_ASSUME_NONNULL_END
