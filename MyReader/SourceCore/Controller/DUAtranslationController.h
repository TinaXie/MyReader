//
//  DUAtranslationController.h
//  MyReader
//
//  Created by xiejc on 2018/11/19.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define animationDuration 0.2
#define limitRate 0.5

typedef enum {
    TranslationControllerNavigationDirection_left,
    TranslationControllerNavigationDirection_right,
} TranslationControllerNavigationDirection;


NS_ASSUME_NONNULL_BEGIN

@class DUAtranslationController;

@protocol DUATranslationProtocol <NSObject>

- (UIViewController *)translationController:(DUAtranslationController *)translationController controllerAfter:(UIViewController *)controller;

- (UIViewController *)translationController:(DUAtranslationController *)translationController controllerBefore:(UIViewController *)controller;

- (void)translationController:(DUAtranslationController *)translationController willTransitionTo:(UIViewController *)controller;


- (void)translationController:(DUAtranslationController *)translationController didFinishAnimating:(BOOL)finished previousController:(UIViewController *)previousController transitionCompleted:(BOOL)completed;


@end


@interface DUAtranslationController : UIViewController

@property (nonatomic, weak) id<DUATranslationProtocol> delegate;
@property (nonatomic, strong) UIViewController *pendingController;
@property (nonatomic, strong) UIViewController *currentController;

@property (nonatomic, assign) CGPoint startPoint;


// 0 is unknown, 1 is right, -1 is left
@property (nonatomic, assign) int scrollDirection;
@property (nonatomic, assign) BOOL allowRequestNewController;
@property (nonatomic, assign) BOOL isPanning;
@property (nonatomic, assign) BOOL allowAnimating;



/**
 设置VC滚动方向

 @param viewController vc
 @param direction 方向
 @param animated 是否需要动画
 @param completionHandler 滚动结束回调
 */
- (void)setViewController:(UIViewController *)viewController direction:(TranslationControllerNavigationDirection)direction animated:(BOOL)animated completionHandler:(void(^ __nullable)(BOOL completed))completionHandler;

@end

NS_ASSUME_NONNULL_END
