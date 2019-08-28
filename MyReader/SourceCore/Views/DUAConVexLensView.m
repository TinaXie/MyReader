//
//  DUAConVexLensView.m
//  MyReader
//
//  Created by xiejc on 2018/11/16.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import "DUAConVexLensView.h"


@implementation DUAConVexLensView

/*
init() {
    
    super.init(frame: CGRect(x: 0, y: 0, width: 120, height: 120))
    
    self.layer.borderWidth = 3
    self.layer.borderColor = UIColor.lightGray.cgColor
    self.layer.cornerRadius = 60
    self.layer.masksToBounds = true
}
*/

- (instancetype)init {
    if (self == [super initWithFrame:CGRectMake(0, 0, 120, 120)]) {
        [self initView];
    }
    return self;
}


- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initView];
    }
    return self;
}

- (void)initView {
    self.locatePoint = CGPointZero;
    
    self.layer.borderWidth = 3;
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.layer.cornerRadius = 60;
    self.layer.masksToBounds = true;
}

- (void)setLocatePoint:(CGPoint)locatePoint {
    _locatePoint = locatePoint;
    
    self.center = CGPointMake(locatePoint.x, locatePoint.y - 80.0);
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(ctx, self.width * 0.5, self.height * 0.5);
    CGContextScaleCTM(ctx, 1.5, 1.5);
    CGContextTranslateCTM(ctx, -1 * self.locatePoint.x, -1 * (self.locatePoint.y + 20));
    [[[UIApplication sharedApplication] keyWindow].layer renderInContext:ctx];
}

@end
