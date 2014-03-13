//
//  FileUtil.h
//  mcare-ui
//
//  Created by sam on 12-9-7.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileUtil : NSObject

+ (BOOL)isExist:(NSString *)file;
+ (NSString *)getPicPath;
+ (NSString *)getAudioPath;
+ (NSString *)getInquiryAudioPath;
+ (NSString *)getPhotoPath;
+ (NSString *)getMoviePath;
+ (NSString *)getMovieTempPath;
+ (NSString *)getMovieCachePath;
+ (NSString *)getCachePicPath;

+ (NSString *)getFileName:(NSString *)path;
+ (NSString *)getFilePart:(NSString *)name idx:(NSInteger)idx;
+ (NSString *)getFileName:(NSString *)path suffix:(NSString *)suffix;
+ (NSString *)getBasePath;
+ (BOOL)isLocalFile:(NSString *)path;
+ (BOOL)clearDir:(NSString *)path;
+ (BOOL)clearFile:(NSString *)path;
+ (void)createDir:(NSString *)dirPath;

+ (void)clearCache;
@end
