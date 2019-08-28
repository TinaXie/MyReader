//
//  DUAPageViewController.m
//  MyReader
//
//  Created by xiejc on 2018/11/19.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import "DUAPageViewController.h"
#import <UMCommon/UMCommon.h>
#import <UMAnalytics/MobClick.h>

@interface DUAPageViewController ()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation DUAPageViewController


- (instancetype)init {
    if (self = [super init]) {
        self.index = -1;
        self.chapterBelong = -1;
        [self initView];
    }
    return self;
}

- (void)initView {
    if (self.imageView == nil) {
        self.imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
        [self.view addSubview:self.imageView];
    }

    if (self.dtLabel == nil) {
        self.dtLabel = [[DUAAttributedView alloc] initWithFrame:CGRectMake(0, self.view.y, self.view.width, self.view.height)];
        self.dtLabel.backgroundColor = [UIColor clearColor];
        [self.view addSubview:self.dtLabel];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view sendSubviewToBack:self.imageView];
    [self updateBackgroundImage];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:NSStringFromClass([self class])];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:NSStringFromClass([self class])];
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    _backgroundImage = backgroundImage;
    [self updateBackgroundImage];
}

- (void)updateBackgroundImage {
    if (self.backgroundImage != nil) {
        self.imageView.image = self.backgroundImage;
    }
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
