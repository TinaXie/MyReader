//
//  DUAPageViewController.h
//  MyReader
//
//  Created by xiejc on 2018/11/19.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DUAAttributedView.h"

NS_ASSUME_NONNULL_BEGIN

@interface DUAPageViewController : UIViewController

@property (nonatomic, assign) int index;
@property (nonatomic, assign) int chapterBelong;

@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, strong) DUAAttributedView *dtLabel;

@end

NS_ASSUME_NONNULL_END
