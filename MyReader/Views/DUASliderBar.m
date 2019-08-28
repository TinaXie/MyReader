//
//  DUASliderBar.m
//  MyReader
//
//  Created by xiejc on 2018/11/22.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import "DUASliderBar.h"

@interface DUASliderBar ()
<UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIButton *dirBtn;
@property (nonatomic, strong) UIButton *markBtn;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, strong) UIView *lineH;
@property (nonatomic, strong) UIView *lineV;

@property (nonatomic, strong) NSArray *dataArray;

@end

@implementation DUASliderBar

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initView];
    }
    return self;
}

- (void)initView {
    CGFloat dirBtnH = 40.0;
    self.dirBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, Screen_Width / 4, dirBtnH)];
    self.dirBtn.alpha = 0.8;
    self.dirBtn.backgroundColor = [UIColor blackColor];
    [self.dirBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.dirBtn setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
    [self.dirBtn addTarget:self action:@selector(onDirBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.dirBtn setTitle:@"目录" forState:UIControlStateNormal];
    
    self.markBtn = [[UIButton alloc] initWithFrame:CGRectMake(Screen_Width / 4, 0, Screen_Width / 4, dirBtnH)];
    self.markBtn.alpha = 0.8;
    self.markBtn.backgroundColor = [UIColor blackColor];
    [self.markBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.markBtn setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];;
    [self.markBtn setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    [self.markBtn setTitle:@"书签" forState:UIControlStateNormal];
    
    [self.markBtn addTarget:self action:@selector(onMarkBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    
    self.lineH = [[UIView alloc] initWithFrame:CGRectMake(0, dirBtnH, Screen_Width / 2, 1)];
    self.lineH.backgroundColor = [UIColor whiteColor];
    
    self.lineV = [[UIView alloc] initWithFrame:CGRectMake(0, dirBtnH, Screen_Width / 2, 1)];
    self.lineV.backgroundColor = [UIColor whiteColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, dirBtnH, self.width / 2, self.height - dirBtnH)];
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.alpha = 0.8;
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    
    [self addSubview:self.dirBtn];
    [self addSubview:self.markBtn];
    [self addSubview:self.tableView];
    [self addSubview:self.lineH];
    [self addSubview:self.lineV];
    
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSideViewClicked:)];
    self.tap.delegate = self;
    [self addGestureRecognizer:self.tap];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)onDirBtnClicked {
    [self.markBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.dirBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    self.dataArray = self.chapterTitles;
    self.tableView.tag = 0;
    [self.tableView reloadData];
}

- (void)onMarkBtnClicked {
    [self.dirBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.markBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];

    self.tableView.tag = 100;
    NSMutableArray *dataArray = [NSMutableArray array];
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *marks = [self.marksArray objectForKey:self.curBookName];
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *markList;
    if (marks != nil && marks.count > 0) {
        markList = marks;
    }
    if (markList.count > 0) {
        for (NSString *key in markList.allKeys) {
            NSMutableArray *valueList = [markList objectForKey:key];
            for (NSString *item in valueList) {
                NSString *itemString = [NSString stringWithFormat:@"第%@章 第%@页", key, item];
                [dataArray addObject:itemString];
            }
        }
    }
    
    self.dataArray = dataArray;
    [self.tableView reloadData];
}

- (void)onSideViewClicked:(UITapGestureRecognizer *)ges {
    CGFloat width = Screen_Width;
    CGFloat height = Screen_Height;
    [UIView animateWithDuration:0.2 animations:^{
        self.frame = CGRectMake(-width, 0, width, height);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:self];
    CGRect rect = CGRectMake(0, 0, self.width * 0.5, self.height);
    if (CGRectContainsPoint(rect, point)) {
        return NO;
    }
    return YES;
}



#pragma mark - table view delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellDequeueReusable = @"reader.demo.cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellDequeueReusable];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellDequeueReusable];
        cell.backgroundColor = [UIColor clearColor];
    }
    
    cell.textLabel.text = [self.dataArray objectAtIndex:indexPath.row];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int chapterIndex;
    int pageIndex;
    if (tableView.tag == 0) {
        chapterIndex = (int)indexPath.row + 1;
        pageIndex = 1;
    } else {
        NSString *cellText = [self.dataArray objectAtIndex:indexPath.row];
        NSArray *texts = [cellText componentsSeparatedByString:@" "];
        NSString *chapterStr = texts.firstObject;
        chapterIndex = [[chapterStr substringWithRange:NSMakeRange(1, 1)] intValue];
        
        NSString *pageStr = texts.lastObject;
        pageIndex = [[pageStr substringWithRange:NSMakeRange(1, 1)] intValue];
    }
    
    NSLog(@"sliderbar did click chapter:%d page:%d", chapterIndex, pageIndex);
    if (self.delegate && [self.delegate respondsToSelector:@selector(sliderBarDidClickBookAtChapterIndex:pageIndex:)]) {
        [self.delegate sliderBarDidClickBookAtChapterIndex:chapterIndex pageIndex:pageIndex];
    }
}



@end
