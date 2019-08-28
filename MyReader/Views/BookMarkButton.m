//
//  BookMarkButton.m
//  MyReader
//
//  Created by xiejc on 2018/11/20.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import "BookMarkButton.h"

@implementation BookMarkButton

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.isClicked = NO;
    }
    return self;
}

- (void)setIsClicked:(BOOL)isClicked {
    _isClicked = isClicked;
    if (isClicked) {
        [self setImage:[UIImage imageNamed:@"bookMarked"] forState:UIControlStateNormal];
    } else {
        [self setImage:[UIImage imageNamed:@"bookMark"] forState:UIControlStateNormal];
    }
}

@end
