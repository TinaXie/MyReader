//
//  DUATextDataParser.m
//  MyReader
//
//  Created by xiejc on 2018/11/15.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import "DUATextDataParser.h"

#define TitleFontSize 19.0

@implementation DUATextDataParser

//

- (void)parseChapterFromBook:(NSString *)path completeHandler:(nonnull void (^)(NSMutableArray<NSString *> * _Nonnull, NSMutableArray<DUAChapterModel *> * _Nonnull))completeHandler {
    NSURL *url = [NSURL fileURLWithPath:path];
    NSError *error;
    NSString *content = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    NSMutableArray<DUAChapterModel *> *models = [NSMutableArray array];
    NSMutableArray<NSString *> *titles = [NSMutableArray array];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
        NSString *newPath = [path copy];
        NSString *fileName = [[newPath lastPathComponent] componentsSeparatedByString:@"."].firstObject;
        NSString *bookPath = [document stringByAppendingFormat:@"/%@",fileName];
        
        NSFileManager *defaultManager = [NSFileManager defaultManager];
        
        if (![defaultManager fileExistsAtPath:bookPath]) {
            NSError *createError;
            [defaultManager createDirectoryAtPath:bookPath withIntermediateDirectories:YES attributes:nil error:&createError];
            if (createError) {
                NSLog(@"====create directory error:\n:%@\n:%@", bookPath, createError.localizedDescription);
            }
        }
        
    
        NSArray<NSTextCheckingResult *> *results;
        NSString *titleFilePath = [bookPath stringByAppendingString:@"/chaptertitles.txt"];
        if ([defaultManager fileExistsAtPath:titleFilePath]) {
            results = [NSKeyedUnarchiver unarchiveObjectWithFile:titleFilePath];
        } else {
            results = [self doTitleMatchWith:content];
            [NSKeyedArchiver archiveRootObject:results toFile:titleFilePath];
        }
        
        if (results.count == 0) {
            DUAChapterModel *model = [[DUAChapterModel alloc] init];
            model.chapterIndex = 1;
            model.path = path;
            if (completeHandler) {
                completeHandler([NSMutableArray array], [NSMutableArray arrayWithObject:model]);
            }
        } else {
            //读取章节title，创建章节model, 将每章节写入txt
            for (int i = 0; i < results.count; i++) {
                NSTextCheckingResult *result = [results objectAtIndex:i];
                NSString *currentTitle = [content substringWithRange:result.range];
                [titles addObject:currentTitle];

                DUAChapterModel *model = [[DUAChapterModel alloc] init];
                model.chapterIndex = i + 1;
                model.title = currentTitle;
                NSString *chapterPath = [bookPath stringByAppendingFormat:@"/chapter%d.txt", model.chapterIndex];
                model.path = chapterPath;
                [models addObject:model];
                
                if ([defaultManager fileExistsAtPath:chapterPath]) {
                    NSLog(@"parseChapterFromBook haschapter:%d", model.chapterIndex);
                    continue;
                }
                
                NSInteger endLocation = 0;
                if (i == results.count - 1) {
                    endLocation = content.length - 1;
                } else {
                    endLocation = [results objectAtIndex:i + 1].range.location - 1;
                }
                
                NSInteger startLocation = result.range.location;
                NSInteger length = endLocation - startLocation - 1;
                NSString *subString = [content substringWithRange:NSMakeRange(startLocation, length)];
                
                NSError *writeError;
                [subString writeToFile:chapterPath atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
                if (writeError) {
                    NSLog(@"parseChapterFromBook write chapter %d error!\nerror:%@\npath:%@", i, error.localizedDescription, chapterPath);
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completeHandler) {
                    completeHandler(titles, models);
                }
            });
        }
        
        
    });
}

- (NSMutableAttributedString *)attributedStringFromChapterModel:(DUAChapterModel *)chapter config:(DUAConfiguration *)config {
    NSURL *tmpUrl = [NSURL fileURLWithPath:chapter.path];
    NSError *error;
    NSString *tmpString = [NSString stringWithContentsOfURL:tmpUrl encoding:NSUTF8StringEncoding error:&error];
    if (error != nil) {
        NSLog(@"read chapter error!\nerror:%@\npath:%@", error.localizedDescription, chapter.path);
        return nil;
    }
    
    if (tmpString == nil) {
        NSLog(@"read chapter null!\npath:%@", chapter.path);
        return nil;
    }
    
    NSString *textString = tmpString;
    NSArray<NSTextCheckingResult *> *results = [self doTitleMatchWith:textString];
    
    NSRange titleRange =NSMakeRange(0, 0);
    if (results.count != 0) {
        titleRange = results[0].range;
    }
    
    NSUInteger startLocation = titleRange.location;
    NSUInteger endLocation = titleRange.length - 1;
    
    NSString *titleString = [textString substringWithRange:NSMakeRange(startLocation, endLocation - startLocation + 1)];
    NSString *contentString = [textString substringFromIndex:endLocation];
    NSString *paraString = [self formatChapterString:contentString];
    
    NSMutableParagraphStyle *paragraphStyleTitle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyleTitle.alignment = NSTextAlignmentCenter;
    
    NSDictionary<NSAttributedStringKey, id> *dictTitle = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:TitleFontSize], NSParagraphStyleAttributeName:paragraphStyleTitle};
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    paragraphStyle.lineHeightMultiple = config.lineHeightMutiplier;
    UIFont *font = [UIFont fontWithName:config.fontName size:config.fontSize];
    NSDictionary<NSAttributedStringKey, id> *dict = @{NSFontAttributeName:font, NSParagraphStyleAttributeName:paragraphStyle, NSForegroundColorAttributeName:[UIColor blackColor]};
    
    NSString *newTitle = [NSString stringWithFormat:@"\n%@\n\n", titleString];
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:newTitle attributes:dictTitle];
    NSMutableAttributedString *content = [[NSMutableAttributedString alloc] initWithString:paraString attributes:dict];
    [attrString appendAttributedString:content];
    
    return attrString;
}


- (NSString *)formatChapterString:(NSString *)contentString {
    NSArray *paragraphArray = [contentString componentsSeparatedByString:@"\n"];
    NSMutableString *newParagraphString = [NSMutableString stringWithString:@""];
    [paragraphArray enumerateObjectsUsingBlock:^(NSString *paragraph, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *string0 = [paragraph stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString *string1 = [string0 stringByReplacingOccurrencesOfString:@"\t" withString:@""];
        NSString *newParagraph = [string1 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (newParagraph.length != 0) {
            newParagraph = [@"\t" stringByAppendingString:newParagraph];
            if (idx != paragraphArray.count - 1) {
                newParagraph = [newParagraph stringByAppendingString:@"\n"];
            }
            [newParagraphString appendString:newParagraph];
        }
    }];
    
    return newParagraphString;
}


- (NSArray<NSTextCheckingResult *> *)doTitleMatchWith:(NSString *)content {
    if (content == nil) {
        return nil;
    }

    NSString *pattern = @"第\\s*[0-9一二三四五六七八九十百千]*\\s*[章回节].*";
    
    NSError *error;
    NSRegularExpression *regExp = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    if (error) {
        NSLog(@"doTitleMatch error:%@", error.localizedDescription);
    }
    NSArray<NSTextCheckingResult *> *results = [regExp matchesInString:content options:NSMatchingReportCompletion range:NSMakeRange(0, content.length)];
    return results;
}

@end

