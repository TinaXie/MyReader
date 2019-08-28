//
//  DUABackViewController.h
//  MyReader
//
//  Created by xiejc on 2018/11/19.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DUAPageViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface DUABackViewController : UIViewController

@property (nonatomic, assign) int index;
@property (nonatomic, assign) int chapterBelong;
@property (nonatomic, strong) UIImage *backImage;


- (void)grabViewController:(DUAPageViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
