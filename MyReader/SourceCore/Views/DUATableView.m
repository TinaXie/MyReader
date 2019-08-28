//
//  DUATableView.m
//  MyReader
//
//  Created by xiejc on 2018/11/16.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import "DUATableView.h"

@implementation DUATableView

- (instancetype)init {
    if (self = [super init]) {
        self.dataArray = [NSMutableArray array];
        self.cellIndex = 0;
        self.isReloading = NO;
        self.arrivedZeroOffset = NO;
        self.scrollDirection = TableViewScrollDirecton_unknown;
    }

    return self;
}


@end
