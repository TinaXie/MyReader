//
//  DUAUtils.m
//  MyReader
//
//  Created by xiejc on 2018/11/13.
//  Copyright © 2018 xiejc. All rights reserved.
//

#import "DUAUtils.h"
#import <ZipArchive/ZipArchive.h>
#import <TouchXML/TouchXML.h>

#define URL_NCX @"http://www.daisy.org/z3986/2005/ncx/"
#define URL_OPF @"http://www.idpf.org/2007/opf"

@implementation DUAUtils


+ (NSString *)unzipWithFilePath:(NSString *)filePath {
    ZipArchive *zipHandler = [[ZipArchive alloc] init];
    NSString *newPath = [filePath copy];
    NSString *fileName = [[newPath lastPathComponent] componentsSeparatedByString:@"."].firstObject;
    if ([zipHandler UnzipOpenFile:filePath]) {
        NSString *zipDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
        zipDir = [zipDir stringByAppendingFormat:@"/%@", fileName];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:zipDir]) {
            NSError *error;
            [fileManager removeItemAtPath:zipDir error:&error];
            if (error) {
                NSLog(@"unzipWithFilePath remove path error!!\npath%@\nerror:%@", zipDir, error.localizedDescription);
                return @"";
            }
        }
        if ([zipHandler UnzipFileTo:zipDir overWrite:true]) {
            return zipDir;
        }
    }
    NSLog(@"unzipWithFilePath failed!");
    return @"";
}


/// 获取OPF文件路径
///
/// - Parameter epubPath: epub解压后目录
/// - Returns: OPF文件路径
+ (NSString *)OPFPathFromEpubPath:(NSString *)epubPath {
    NSString *containerPath = [epubPath stringByAppendingString:@"/META-INF/container.xml"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:containerPath]) {
        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:containerPath];
        NSError *error;
        CXMLDocument *document = [[CXMLDocument alloc] initWithContentsOfURL:fileURL options:0 error:&error];
        if (error) {
            NSLog(@"create CXMLDocument error!!\npath%@\nerror:%@", containerPath, error.localizedDescription);
            return @"";
        }
        
        NSArray *opfPathNodes = [document nodesForXPath:@"//@full-path" error:&error];
        if (error) {
            NSLog(@"create CXMLNode error!!\npath%@\nerror:%@", containerPath, error.localizedDescription);
            return @"";
        }
        
        CXMLNode *opfPathNode = opfPathNodes.firstObject;
        NSString *opfObselutePath = [epubPath stringByAppendingFormat:@"/%@", [opfPathNode stringValue]];
        return opfObselutePath;
    }
    return @"";
}

+ (NSArray <NSDictionary *> *)parseOPF:(NSString *)opfPath {
    NSError *error;
    CXMLDocument *document = [[CXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:opfPath] options:0 error:&error];
    if (error) {
        NSLog(@"parseOPF document error!\nerror:%@\npath:%@", error.localizedDescription, opfPath);
        return nil;
    }
    
    NSArray<CXMLElement *> *itemArray = [document nodesForXPath:@"//opf:item" namespaceMappings:@{@"opf":URL_OPF} error:&error];
    if (error) {
        NSLog(@"parseOPF document node error!\nerror:%@\npath:%@", error.localizedDescription, opfPath);
        return nil;
    }
    
    NSString *ncxFileName = @"";
    NSMutableDictionary *itemDict = [NSMutableDictionary dictionary];
    for (CXMLElement *item in itemArray) {
        NSString *name = [[item attributeForName:@"id"] stringValue];
        NSString *value = [[item attributeForName:@"href"] stringValue];
        [itemDict setObject:value forKey:name];
        
        NSString *mediaType = [[item attributeForName:@"media-type"] stringValue];
        if ([mediaType isEqualToString:@"application/x-dtbncx+xml"]) {
            ncxFileName = [[item attributeForName:@"href"] stringValue];
        }
    }
    NSString *opfParentPath = [self getparentPathFromPath:opfPath];
    NSString *ncxFilePath = [opfParentPath stringByAppendingFormat:@"/%@", ncxFileName];
    CXMLDocument *ncxDocument = [[CXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:ncxFilePath] options:0 error:&error];
    if (error) {
        NSLog(@"parseOPF ncxdocument node error!\nerror:%@\npath:%@", error.localizedDescription, ncxFilePath);
        return nil;
    }
    
    NSMutableDictionary *titleDict = [NSMutableDictionary dictionary];
    for (CXMLElement *item in itemArray) {
        NSString *href = [[item attributeForName:@"href"] stringValue];
        NSString *xpath = [NSString stringWithFormat:@"//ncx:content[@src='%@']/../ncx:navLabel/ncx:text", href];
        NSArray *navPoints = [ncxDocument nodesForXPath:xpath namespaceMappings: @{@"ncx":URL_NCX} error:&error];
        if (error) {
            NSLog(@"parseOPF ncxdocument item nodes error!\nerror:%@\npath:%@", error.localizedDescription, xpath);
        }
        if (navPoints.count != 0) {
            NSArray *contents = [ncxDocument nodesForXPath:@"//ncx:content" namespaceMappings: @{@"ncx":URL_NCX} error:&error];
            if (error) {
                NSLog(@"parseOPF ncxdocument item contents error!\nerror:%@\npath:%@", error.localizedDescription, xpath);
            }
            
            for (CXMLElement *contentElement in contents) {
                NSString *src = [[contentElement attributeForName:@"src"] stringValue];
                if ([src hasPrefix:href]) {
                    xpath = [NSString stringWithFormat:@"//ncx:content[@src='\%@']/../ncx:navLabel/ncx:text", src];
                    navPoints = [ncxDocument nodesForXPath:xpath namespaceMappings:@{@"ncx":URL_NCX} error:&error];
                    
                    if (error) {
                        NSLog(@"parseOPF ncxdocument item contents error!\nerror:%@\npath:%@", error.localizedDescription, xpath);
                    }
                    break;
                }
            }
        }
        
        if (navPoints.count != 0) {
            CXMLElement *titleElement = navPoints[0];
            [titleDict setObject:[titleElement stringValue] forKey:href];
        }
    }
    
    NSArray *itemRefArray = [document nodesForXPath:@"//opf:itemref" namespaceMappings:@{@"opf":URL_OPF} error:&error];
    if (error) {
        NSLog(@"parseOPF opf document error!\nerror:%@\n", error.localizedDescription);
    }
    
    NSMutableArray<NSDictionary *> *chapterArray = [NSMutableArray array];
    [itemRefArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CXMLElement *itemRef = obj;
        NSString *idref = [[itemRef attributeForName:@"idref"] stringValue];
        NSString *chapterRef = [itemDict objectForKey:idref];
        NSString *chapterPath = [self getparentPathFromPath:opfPath];
        chapterPath = [chapterPath stringByAppendingFormat:@"/%@", chapterRef];

        NSMutableDictionary *chapterDict = [NSMutableDictionary dictionary];
        [chapterDict setObject:IntToString((int)idx) forKey:@"chapterIndex"];
        NSString *chapterTitle = [titleDict objectForKey:chapterRef];
        if (chapterTitle == nil) {
            chapterTitle = @"";
        }
        [chapterDict setObject:chapterTitle forKey:@"chapterTitle"];
        [chapterDict setObject:chapterPath forKey:@"chapterPath"];

        [chapterArray addObject:chapterDict];
    }];
    
    return chapterArray;
}


+ (NSString *)getparentPathFromPath:(NSString *)path {
    NSArray *components = [path componentsSeparatedByString:@"/"];
    if (components.count > 1) {
        components = [components subarrayWithRange:NSMakeRange(0, components.count - 1)];
    }

    NSMutableString *parentPath = [NSMutableString stringWithString:@""];
    for (NSString *component in components) {
        [parentPath appendString:@"/"];
        [parentPath appendString:component];
    }
    return parentPath;
}


@end
