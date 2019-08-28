//
//  DUAEpubDataParser.m
//  MyReader
//
//  Created by xiejc on 2018/11/15.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import "DUAEpubDataParser.h"
#import "DUAUtils.h"

@implementation DUAEpubDataParser

- (void)parseChapterFromBook:(NSString *)path completeHandler:(nonnull void (^)(NSMutableArray<NSString *> * _Nonnull, NSMutableArray<DUAChapterModel *> * _Nonnull))completeHandler {
    NSString *epubZippedPath = [DUAUtils unzipWithFilePath:path];
    NSString *opfPath = [DUAUtils OPFPathFromEpubPath:epubZippedPath];
    NSArray<NSDictionary *> *chapterInfoArray = [DUAUtils parseOPF:opfPath];
    NSMutableArray<NSString *> *titleArray = [NSMutableArray array];
    NSMutableArray<DUAChapterModel *> *models = [NSMutableArray array];

    BOOL chapterIndexOffset = NO;
    NSInteger firstIndex = [[chapterInfoArray.firstObject objectForKey:@"chapterIndex"] intValue];
    if (firstIndex != 0) {
        chapterIndexOffset = YES;
    }
    
    for (NSDictionary *item in chapterInfoArray) {
        [titleArray addObject:[item objectForKey:@"chapterTitle"]];

        DUAChapterModel *chapter = [[DUAChapterModel alloc] init];
        int chapterIndex = [[item objectForKey:@"chapterIndex"] intValue];
        chapter.chapterIndex = chapterIndexOffset ? chapterIndex + 2 : chapterIndex + 1;
        chapter.path = [item objectForKey:@"chapterPath"];
        chapter.title = [item objectForKey:@"chapterIndex"];
        [models addObject:chapter];
    }
    
    if (completeHandler) {
        completeHandler(titleArray, models);
    }
}

- (NSMutableAttributedString *)attributedStringFromChapterModel:(DUAChapterModel *)chapter config:(DUAConfiguration *)config {
    NSData *htmlData = [NSData dataWithContentsOfFile:chapter.path];
    if (htmlData == nil) {
        return nil;
    }
    NSDictionary *options = @{
                              DTDefaultFontFamily : @"Times New Roman",
                              DTDefaultLinkColor  : @"purple",
                              NSTextSizeMultiplierDocumentOption : @(1.0),
                              DTDefaultFontSize   : @(config.fontSize),
                              DTDefaultLineHeightMultiplier : @(config.lineHeightMutiplier),
                              DTDefaultTextAlignment : @"0",
                              DTDefaultHeadIndent : @"0.0",
                              NSBaseURLDocumentOption : [NSURL fileURLWithPath:chapter.path],
                              DTMaxImageSize : @(config.contentFrame.size),
                              };
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithHTMLData:htmlData options:options documentAttributes:nil];
    return attrStr;
}



@end
