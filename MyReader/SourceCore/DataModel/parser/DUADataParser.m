//
//  DUADataParser.m
//  MyReader
//
//  Created by xiejc on 2018/11/14.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import "DUADataParser.h"

@implementation DUADataParser

- (void)parseChapterFromBook:(NSString *)path completeHandler:(void(^)(NSMutableArray<NSString *> *titles, NSMutableArray<DUAChapterModel *> *models))completeHandler {
    
}

- (NSMutableAttributedString *)attributedStringFromChapterModel:(DUAChapterModel *)chapter config:(DUAConfiguration *)config {
    return nil;
}


- (void)cutChapterPageAtIndex:(int)chapterIndex attrString:(NSAttributedString *)attrString config:(DUAConfiguration *)config completeHandler:(void (^)(int, DUAPageModel * _Nonnull, BOOL))completeHandler {
    DTCoreTextLayouter *layouter = [[DTCoreTextLayouter alloc] initWithAttributedString:attrString];
    CGRect rect = CGRectMake(config.contentFrame.origin.x, config.contentFrame.origin.y, config.contentFrame.size.width, config.contentFrame.size.height - 5);
    DTCoreTextLayoutFrame *frame = [layouter layoutFrameWithRect:rect range:NSMakeRange(0, attrString.length)];
    NSRange pageVisibleRange = [frame visibleStringRange];
    NSUInteger rangeOffset = pageVisibleRange.location + pageVisibleRange.length;
    
    int count = 1;
    while (rangeOffset <= attrString.length && rangeOffset != 0) {
        DUAPageModel *pageModel = [[DUAPageModel alloc] init];
        pageModel.attributedString = [attrString attributedSubstringFromRange:pageVisibleRange];
        pageModel.range = pageVisibleRange;
        pageModel.pageIndex = count;
        pageModel.chapterBlong = chapterIndex;
        
        frame = [layouter layoutFrameWithRect:rect range:NSMakeRange(rangeOffset, attrString.length - rangeOffset)];
        pageVisibleRange = [frame visibleStringRange];
        if (pageVisibleRange.length == 0) {
            rangeOffset = 0;
        } else {
            rangeOffset = pageVisibleRange.location + pageVisibleRange.length;
        }
        
        BOOL completed = (rangeOffset <= attrString.length && rangeOffset != 0) ? NO : YES;
        completeHandler(count, pageModel, completed);
        count += 1;
    }
}

@end
