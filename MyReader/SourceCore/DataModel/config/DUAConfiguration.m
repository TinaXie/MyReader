//
//  DUAConfiguration.m
//  MyReader
//
//  Created by xiejc on 2018/11/13.
//  Copyright © 2018 xiejc. All rights reserved.
//

#define ConfigCacheKey @"readerConfigStyle"

#import "DUAConfiguration.h"

@implementation DUAConfiguration

- (instancetype)init {
    if (self = [super init]) {
        NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:ConfigCacheKey];
        if (dict == nil || dict.count == 0) {
            self.lineHeightMutiplier = 2.0;
            self.scrollType = DUAReaderScrollType_curl;
            self.bookType = DUAReaderBookType_txt;
            self.bgType = DUAReaderBgType_Pure;

            self.fontSize = 14.0;
            UIFont *font = [UIFont systemFontOfSize:self.fontSize];
            self.fontName = font.fontName;
            [self saveCacheConfig];
        } else {
            [self loadByDict:dict];
        }
        
        
        CGFloat safeAreaTopHeight = UI_IS_IPHONEX ? 24 : 0;
        CGFloat safeAreaBottomHeight = UI_IS_IPHONEX ? 34 : 0;
        CGFloat margin = 60.0;
    
        self.contentFrame = CGRectMake(margin * 0.5, margin * 0.5 + safeAreaTopHeight, Screen_Width - margin, Screen_Height -  margin - safeAreaTopHeight - safeAreaBottomHeight);
    }
    return self;
}

- (void)loadByDict:(NSDictionary *)dict {
    self.lineHeightMutiplier = [[dict objectForKey:@"lineHeightMutiplier"] floatValue];
    self.fontSize = [[dict objectForKey:@"fontSize"] floatValue];
    self.fontName = [dict objectForKey:@"fontName"];
    self.bookType = [[dict objectForKey:@"bookType"] intValue];
    self.bgType = [[dict objectForKey:@"bgType"] intValue];
    self.scrollType = [[dict objectForKey:@"scrollType"] intValue];
}

- (void)saveCacheConfig {
    NSDictionary *dict = @{
                           @"lineHeightMutiplier":@(self.lineHeightMutiplier),
                           @"fontName":StringWithDefaultValue(self.fontName, @""),
                           @"fontSize":@(self.fontSize),
                           @"bookType":@(self.bookType),
                           @"scrollType":@(self.scrollType),
                           @"bgType":@(self.bgType),
                           };
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:ConfigCacheKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setLineHeightMutiplier:(CGFloat)lineHeightMutiplier {
    if (_lineHeightMutiplier == lineHeightMutiplier) {
        return;
    }

    _lineHeightMutiplier = lineHeightMutiplier;
    if (self.didLineHeightChanged) {
        self.didLineHeightChanged(self.lineHeightMutiplier);
    }
    [self saveCacheConfig];

}

- (void)setFontSize:(CGFloat)fontSize {
    if (_fontSize == fontSize) {
        return;
    }
    _fontSize = fontSize;
    if (self.didFontSizeChanged) {
        self.didFontSizeChanged(self.fontSize);
    }
    [self saveCacheConfig];
}

- (void)setFontName:(NSString *)fontName {
    if ([_fontName isEqualToString:fontName]) {
        return;
    }
    _fontName = fontName;
    if (self.didFontSizeChanged) {
        self.didFontNameChanged(self.fontName);
    }
    [self saveCacheConfig];
}

- (void)setBgType:(DUAReaderBgType)bgType {
    if (_bgType == bgType) {
        return;
    }
    
    _bgType = bgType;

    if (self.didBackgroundImageChanged) {
        self.didBackgroundImageChanged(self.bgType);
    }
    [self saveCacheConfig];
}

- (void)setScrollType:(DUAReaderScrollType)scrollType {
    if (_scrollType == scrollType) {
        return;
    }
    _scrollType = scrollType;
    if (self.didScrollTypeChanged) {
        self.didScrollTypeChanged(self.scrollType);
    }
    [self saveCacheConfig];
}


+ (NSString *)getTypeStringByType:(DUAReaderBookType)type {
    NSString *typeStr = @"txt";
    switch (type) {
        case DUAReaderBookType_txt:
            typeStr = @"txt";
            break;
        case DUAReaderBookType_epub:
            typeStr = @"epub";
        default:
            break;
    }
    return typeStr;
}

+ (DUAReaderBookType) getTypeByTypeString:(NSString *)typeString {
    if ([typeString isEqualToString:@"txt"]) {
        return DUAReaderBookType_txt;
    } else if ([typeString isEqualToString:@"epub"]) {
        return DUAReaderBookType_epub;
    }
    return DUAReaderBookType_txt;
}


- (UIImage *)backgroundImage {
    NSString *imgName = @"backImg";
    switch (self.bgType) {
        case DUAReaderBgType_Pure:
            imgName = @"backImg";
            break;
        case DUAReaderBgType_Leaf:
            imgName = @"backImg2";
            break;
        case DUAReaderBgType_Flower:
            imgName = @"backImg1";
            break;
        default:
            break;
    }
    UIImage *backgroundImage = [UIImage imageNamed:imgName];
    return backgroundImage;
}


@end
