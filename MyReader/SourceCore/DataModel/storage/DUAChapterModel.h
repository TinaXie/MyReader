//
//  DUAChapterModel.h
//  MyReader
//
//  Created by xiejc on 2018/11/14.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DUAChapterModel : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *path;

//从1开始
@property (nonatomic, assign) int chapterIndex;

@end

NS_ASSUME_NONNULL_END
