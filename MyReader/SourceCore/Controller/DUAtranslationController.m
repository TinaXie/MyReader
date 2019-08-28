//
//  DUAtranslationController.m
//  MyReader
//
//  Created by xiejc on 2018/11/19.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import "DUAtranslationController.h"

@interface DUAtranslationController () <UIGestureRecognizerDelegate>

@end

@implementation DUAtranslationController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor lightGrayColor];
    if (self.allowAnimating) {
        UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGes:)];
        [self.view addGestureRecognizer:panGes];
    }
    
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGes:)];
    [self.view addGestureRecognizer:tapGes];
    tapGes.delegate = self;
}

- (void)handlePanGes:(UIPanGestureRecognizer *)gesture {
    NSLog(@"===handlePanGes");
    CGPoint basePoint = [gesture translationInView:gesture.view];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.currentController = self.childViewControllers.firstObject;
        self.startPoint = [gesture locationInView:gesture.view];
        self.isPanning = YES;
        self.allowRequestNewController = YES;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        if (basePoint.x > 0) {
            if (self.scrollDirection == 0) {
                self.scrollDirection = 1;
            } else if (self.scrollDirection == -1) {
                self.scrollDirection = 1;
                [self removeController:self.pendingController];
                self.allowRequestNewController = YES;
            }
            
            // go to right
            if (self.allowRequestNewController) {
                self.allowRequestNewController = NO;
                self.pendingController = [self.delegate translationController:self controllerBefore:self.currentController];
                self.pendingController.view.transform = CGAffineTransformMakeTranslation(-Screen_Width, 0);
                if (self.pendingController != nil) {
                    [self.delegate translationController:self willTransitionTo:self.pendingController];
                    [self addController:self.pendingController];
                }
            }
        } else if (basePoint.x < 0) {
            if (self.scrollDirection == 0) {
                self.scrollDirection = -1;
            } else if (self.scrollDirection == 1) {
                self.scrollDirection = -1;
                [self removeController:self.pendingController];
                self.allowRequestNewController = YES;
            }
            
            // go to left
            if (self.allowRequestNewController) {
                self.allowRequestNewController = NO;
                self.pendingController = [self.delegate translationController:self controllerAfter:self.currentController];
                self.pendingController.view.transform = CGAffineTransformMakeTranslation(Screen_Width, 0);
                
                if (self.pendingController != nil) {
                    [self.delegate translationController:self willTransitionTo:self.pendingController];
                    [self addController:self.pendingController];
                }
            }
        }
        if (self.pendingController == nil) {
            return;
        }
        
        CGPoint walkingPoint = [gesture locationInView:gesture.view];
        CGFloat offsetX = walkingPoint.x - self.startPoint.x;
        self.currentController.view.transform = CGAffineTransformMakeTranslation(offsetX, 0);
        self.pendingController.view.transform = offsetX < 0 ? CGAffineTransformMakeTranslation(Screen_Width + offsetX, 0) : CGAffineTransformMakeTranslation(-Screen_Width + offsetX, 0);
    } else {
        self.isPanning = NO;
        self.allowRequestNewController = NO;
        self.scrollDirection = 0;
        if (self.pendingController == nil) {
            return;
        }
    
        CGPoint endPoint = [gesture locationInView:gesture.view];
        CGFloat finalOffsetRate = (endPoint.x - self.startPoint.x) / Screen_Width;
        CGAffineTransform currentEndTransform = CGAffineTransformIdentity;
        CGAffineTransform pendingEndTransform = CGAffineTransformIdentity;
        UIViewController *removeController = nil;
        BOOL transitionFinished = NO;
        if (finalOffsetRate >= limitRate) {
            transitionFinished = YES;
            currentEndTransform = CGAffineTransformMakeTranslation(Screen_Width, 0);
            removeController = self.currentController;
        } else if (finalOffsetRate < limitRate && finalOffsetRate >= 0) {
            pendingEndTransform = CGAffineTransformMakeTranslation(-Screen_Width, 0);
            removeController = self.pendingController;
        } else {
            transitionFinished = YES;
            currentEndTransform = CGAffineTransformMakeTranslation(-Screen_Width, 0);
            removeController = self.currentController;
        }
        
        [UIView animateWithDuration:animationDuration animations:^{
            self.pendingController.view.transform = pendingEndTransform;
            self.currentController.view.transform = currentEndTransform;
        } completion:^(BOOL finished) {
            if (finished) {
                [self removeController:removeController];
            }
            [self.delegate translationController:self didFinishAnimating:finished previousController:self.currentController transitionCompleted:transitionFinished];
        }];
    }
}

/**
 处理点击收拾

 @param gesture 点击手势识别器
 */
- (void)handleTapGes:(UITapGestureRecognizer *)gesture {
    CGPoint hitPoint = [gesture locationInView:gesture.view];
    UIViewController *curController = self.childViewControllers.firstObject;
    
    __weak typeof(self) weakSelf = self;
    
    if (hitPoint.x < gesture.view.width / 3) {
        NSLog(@"translation handleTapGes 滑向上一个页面");
        //滑向上一个controller
        UIViewController *lastController = [self.delegate  translationController:self controllerBefore:curController];
        if (lastController != nil) {
            [self.delegate translationController:self willTransitionTo:lastController];
            
            [self setViewController:lastController direction:TranslationControllerNavigationDirection_right animated:self.allowAnimating completionHandler:^(BOOL completed) {
                __strong typeof(self) strongSelf = weakSelf;
                [strongSelf.delegate translationController:strongSelf didFinishAnimating:completed previousController:curController transitionCompleted:completed];
            }];
            
        }
    } else if (hitPoint.x >= gesture.view.width * 2 / 3) {
        NSLog(@"====translation handleTapGes 滑向下一个页面");
        //滑向下一个controller
        UIViewController *nexController = [self.delegate translationController:self controllerAfter:self.childViewControllers.firstObject];
        if (nexController != nil) {
            [self.delegate translationController:self willTransitionTo:nexController];
            [self setViewController:nexController direction:TranslationControllerNavigationDirection_left animated:self.allowAnimating completionHandler:^(BOOL completed) {
                __strong typeof(self) strongSelf = weakSelf;
                [strongSelf.delegate translationController:strongSelf didFinishAnimating:completed previousController:curController transitionCompleted:completed];
            }];
        }
    }
}


- (void)setViewController:(UIViewController *)viewController direction:(TranslationControllerNavigationDirection)direction animated:(BOOL)animated completionHandler:(void(^)(BOOL completed))completionHandler {
    if (animated) {
        UIViewController *oldController = self.childViewControllers.firstObject;
        [self addController:viewController];
        
        CGAffineTransform newVCEndTransform;
        CGAffineTransform oldVCEndTransform;
        
        viewController.view.transform = CGAffineTransformIdentity;
        if (direction == TranslationControllerNavigationDirection_left) {
            viewController.view.transform = CGAffineTransformMakeTranslation(Screen_Width, 0);
            newVCEndTransform = CGAffineTransformIdentity;
            oldController.view.transform = CGAffineTransformIdentity;
            oldVCEndTransform = CGAffineTransformMakeTranslation(-Screen_Width, 0);
        } else {
            viewController.view.transform = CGAffineTransformMakeTranslation(-Screen_Width, 0);
            newVCEndTransform = CGAffineTransformIdentity;
            oldController.view.transform = CGAffineTransformIdentity;
            oldVCEndTransform = CGAffineTransformMakeTranslation(Screen_Width, 0);
        }
        
        [UIView animateWithDuration:animationDuration animations:^{
            oldController.view.transform = oldVCEndTransform;
            viewController.view.transform = newVCEndTransform;
        } completion:^(BOOL finished) {
            if (finished) {
                [self removeController:oldController];
            }
            if (completionHandler != nil) {
                completionHandler(finished);
            }
        }];
        
    } else {
        for (UIViewController *controller in self.childViewControllers) {
            [self removeController:controller];
        }
        
        [self addController:viewController];
        if (completionHandler) {
            completionHandler(YES);
        }
    }
}

//添加删除controller
- (void)addController:(UIViewController *)controller {
    [self addChildViewController:controller];
    [controller didMoveToParentViewController:self];
    [self.view addSubview:controller.view];
}

- (void)removeController:(UIViewController *)controller {
    [controller.view removeFromSuperview];
    [controller willMoveToParentViewController:nil];
    [controller removeFromParentViewController];
}

#pragma mark - gesture delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer {
    CGFloat tempWidth = Screen_Width / 3;
    CGPoint hitPoint = [gestureRecognizer locationInView:gestureRecognizer.view];
    if (hitPoint.x > tempWidth && hitPoint.x < (Screen_Width - tempWidth)) {
        return YES;
    }
    return NO;
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
