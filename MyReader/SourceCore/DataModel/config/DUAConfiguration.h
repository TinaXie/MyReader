//
//  DUAConfiguration.h
//  MyReader
//
//  Created by xiejc on 2018/11/13.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    DUAReaderScrollType_curl,
    DUAReaderScrollType_horizontal,
    DUAReaderScrollType_vertical,
    DUAReaderScrollType_none
} DUAReaderScrollType;

typedef enum  {
    DUAReaderBookType_txt,
    DUAReaderBookType_epub
} DUAReaderBookType;

typedef enum {
    DUAReaderBgType_Pure,
    DUAReaderBgType_Flower,
    DUAReaderBgType_Leaf,
} DUAReaderBgType;


@interface DUAConfiguration : NSObject


@property (nonatomic, assign) CGRect contentFrame;
@property (nonatomic, assign) CGFloat lineHeightMutiplier;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, copy) NSString *fontName;
@property (nonatomic, assign) DUAReaderBgType bgType;

@property (nonatomic, assign) DUAReaderScrollType scrollType;
@property (nonatomic, assign) DUAReaderBookType bookType;

@property (nonatomic, copy) void(^didFontSizeChanged)(CGFloat fontSize);
@property (nonatomic, copy) void(^didFontNameChanged)(NSString *fontName);

@property (nonatomic, copy) void(^didBackgroundImageChanged)(DUAReaderBgType bgType);
@property (nonatomic, copy) void(^didLineHeightChanged)(CGFloat lineHeightMutiplier);
@property (nonatomic, copy) void(^didScrollTypeChanged)(DUAReaderScrollType type);



/**
 根据类型获取文件类型后缀

 @param type 书格式类型
 @return 类型后缀字符串
 */
+ (NSString *)getTypeStringByType:(DUAReaderBookType)type;

+ (DUAReaderBookType) getTypeByTypeString:(NSString *)typeString;

- (UIImage *)backgroundImage;

@end

NS_ASSUME_NONNULL_END
