//
//  DUABackViewController.m
//  MyReader
//
//  Created by xiejc on 2018/11/19.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import "DUABackViewController.h"
#import <UMCommon/UMCommon.h>
#import <UMAnalytics/MobClick.h>

@interface DUABackViewController ()

@end

@implementation DUABackViewController

- (instancetype)init {
    if (self = [super init]) {
        self.index = -1;
        self.chapterBelong = -1;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height)];
    imageView.image = self.backImage;
    [self.view addSubview:imageView];
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


- (void)grabViewController:(DUAPageViewController *)viewController {
    self.index = viewController.index;
    self.chapterBelong = viewController.chapterBelong;
    CGRect rect = viewController.view.bounds;

    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGAffineTransform transform = CGAffineTransformMake(-1.0, 0.0, 0.0, 1.0, rect.size.width, 0.0);
    CGContextConcatCTM(context, transform);
    [viewController.view.layer renderInContext:context];
    self.backImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
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
