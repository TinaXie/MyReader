//
//  DUATableView.h
//  MyReader
//
//  Created by xiejc on 2018/11/16.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DUAPageModel.h"

typedef enum {
    TableViewScrollDirecton_up,
    TableViewScrollDirecton_down,
    TableViewScrollDirecton_unknown
} TableViewScrollDirecton;


NS_ASSUME_NONNULL_BEGIN

@interface DUATableView : UITableView

@property (nonatomic, strong) NSMutableArray<DUAPageModel *> *dataArray;
//从0 开始
@property (nonatomic, assign) int cellIndex;
@property (nonatomic, assign) BOOL isReloading;
@property (nonatomic, assign) BOOL arrivedZeroOffset;
@property (nonatomic, assign) TableViewScrollDirecton scrollDirection;

@end

NS_ASSUME_NONNULL_END
