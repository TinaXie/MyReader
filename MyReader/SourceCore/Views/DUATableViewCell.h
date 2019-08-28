//
//  DUATableViewCell.h
//  MyReader
//
//  Created by xiejc on 2018/11/16.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import "DUAPageModel.h"
#import "DUAConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface DUATableViewCell : UITableViewCell

@property (nonatomic, strong) DTAttributedLabel *dtLabel;

- (void)configCellWithPageModel:(DUAPageModel *)pageModel config:(DUAConfiguration *)config;

@end

NS_ASSUME_NONNULL_END
