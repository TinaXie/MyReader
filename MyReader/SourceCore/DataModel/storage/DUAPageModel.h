//
//  DUAPageModel.h
//  MyReader
//
//  Created by xiejc on 2018/11/14.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DUAPageModel : NSObject

@property (nonatomic, copy) NSAttributedString *attributedString;
@property (nonatomic, assign) NSRange range;
@property (nonatomic, assign) int pageIndex;
@property (nonatomic, assign) int chapterBlong;


@end

NS_ASSUME_NONNULL_END
