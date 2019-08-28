//
//  DUAContainerPageViewController.h
//  MyReader
//
//  Created by xiejc on 2018/11/19.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DUAContainerPageViewController : UIPageViewController

@property (nonatomic, assign) BOOL willStepIntoNextChapter;
@property (nonatomic, assign) BOOL willStepIntoLastChapter;

@end

NS_ASSUME_NONNULL_END
