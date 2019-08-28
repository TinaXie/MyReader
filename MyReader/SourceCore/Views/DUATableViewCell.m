//
//  DUATableViewCell.m
//  MyReader
//
//  Created by xiejc on 2018/11/16.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import "DUATableViewCell.h"

@implementation DUATableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self == [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)configCellWithPageModel:(DUAPageModel *)pageModel config:(DUAConfiguration *)config {
    if (self.dtLabel == nil) {
        self.dtLabel = [[DTAttributedLabel alloc] init];
        self.dtLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.dtLabel];
    }

    self.dtLabel.frame = CGRectMake(0, 0, Screen_Width, config.contentFrame.size.height);
    self.dtLabel.edgeInsets = UIEdgeInsetsMake(0, config.contentFrame.origin.x, 0, config.contentFrame.origin.x);
    self.dtLabel.attributedString = pageModel.attributedString;
}


@end
