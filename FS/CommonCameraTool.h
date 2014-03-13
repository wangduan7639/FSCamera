//
//  CommonCameraTool.h
//  FS
//
//  Created by wangduan on 14-2-19.
//  Copyright (c) 2014年 wxcp. All rights reserved.
//

#import <Foundation/Foundation.h>
#define Movie_Width 480
@interface CommonCameraTool : NSObject

+ (NSString *)getThumbPathWithPath:(NSString *)videoPath;
+ (NSString *)getFormalPathFromTempPath:(NSString *)tempPath;
+ (UIImage *)getThumbImageWithPath:(NSString *)videoPath;
+ (UIImage *)createThumbImageWithPath:(NSString *)videoPath;

+ (NSString *)videoPathWithName:(NSString *)name;
+ (NSString *)getTempPathFromFormalPath:(NSString *)formalPath;
+ (NSString *)videoTempPathWithName:(NSString *)name;
+ (NSString *)getCachePathForRemotePath:(NSString *)path;
+ (void)moveToFormalPath:(NSString *)tempPath;

/**
 * 根据地址检查是否文件地址下文件存在
 * param path 完整文件地址
 */
+ (BOOL)fileExist:(NSString *)file;
@end
