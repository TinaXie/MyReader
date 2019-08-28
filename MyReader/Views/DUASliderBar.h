//
//  DUASliderBar.h
//  MyReader
//
//  Created by xiejc on 2018/11/22.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DUASliderBarDelgate <NSObject>

- (void)sliderBarDidClickBookAtChapterIndex:(int)chapterIndex pageIndex:(int)pageIndex;

@end

@interface DUASliderBar : UIView

@property (nonatomic, assign) id<DUASliderBarDelgate> delegate;

@property (nonatomic, strong) NSArray *chapterTitles;
@property (nonatomic, strong) NSDictionary *marksArray;
@property (nonatomic, strong) NSString *curBookName;

- (void)onDirBtnClicked;

- (void)onMarkBtnClicked;

@end

NS_ASSUME_NONNULL_END
