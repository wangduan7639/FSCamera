//
//  CommonCameraTool.m
//  FS
//
//  Created by wangduan on 14-2-19.
//  Copyright (c) 2014年 wxcp. All rights reserved.
//

#import "CommonCameraTool.h"
#import "FileUtil.h"
#import <AVFoundation/AVFoundation.h>
#import "NSString+Addition.h"
#import "FSCache.h"


@implementation CommonCameraTool

+ (NSString *)getThumbPathWithPath:(NSString *)videoPath
{
    if(!videoPath)
    {
        return nil;
    }
    NSString * path = [self getFormalPathFromTempPath:videoPath];
    if(!path)
    {
        return nil;
    }
    NSURL * url = [NSURL fileURLWithPath:path];
    NSString * pathExtension = [url pathExtension];
    NSRange  range = [path rangeOfString:pathExtension options:NSBackwardsSearch];
    NSString * imagePath = [path stringByReplacingCharactersInRange:range withString:@"jpg"];
    return imagePath;
}
+ (NSString *)getFormalPathFromTempPath:(NSString *)tempPath
{
    NSString * name = [tempPath lastPathComponent];
    return [self videoPathWithName:name];
}

+ (UIImage *)getThumbImageWithPath:(NSString *)videoPath
{
    NSString * imgPath = [self getThumbPathWithPath:videoPath];
    UIImage * result = [[FSCache sharedInstance] cacheImageForPath:imgPath];
    if(!result)
    {
        result = [self createThumbImageWithPath:videoPath];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData * data = UIImageJPEGRepresentation(result, 0.8);
            [data writeToFile:imgPath atomically:YES];
        });
    }
    return result;
}

+ (UIImage *)createThumbImageWithPath:(NSString *)videoPath
{
    if(!videoPath)
        return nil;
    NSError *error = nil;
    CMTime imgTime = kCMTimeZero;
    AVAsset * asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPath]];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    //generator.maximumSize = size;
    CGImageRef cgIm = [generator copyCGImageAtTime:imgTime
                                        actualTime:NULL
                                             error:&error];
    UIImage *image = [UIImage imageWithCGImage:cgIm scale:1 orientation:UIImageOrientationUp];
    CGImageRelease(cgIm);
    if (nil != error)
    {
        NSLog(@"Error making screenshot: %@", [error localizedDescription]);
        return nil;
    }
    return image;
}


+ (NSString *)videoPathWithName:(NSString *)name
{
    NSString * documentsPath = [FileUtil getMoviePath];
    return [documentsPath stringByAppendingPathComponent:name];
}
+ (NSString *)getTempPathFromFormalPath:(NSString *)formalPath
{
    NSString * name = [formalPath lastPathComponent];
    return [self videoTempPathWithName:name];
}
+ (NSString *)videoTempPathWithName:(NSString *)name
{
    NSString * documentsPath = [FileUtil getMovieTempPath];
    return [documentsPath stringByAppendingPathComponent:name];
}

+ (NSString *)getCachePathForRemotePath:(NSString *)path
{
    NSString * documentsPath = [FileUtil getMovieCachePath];
    NSString * newPath = [documentsPath stringByAppendingPathComponent:[NSString getMD5ForStr:path]];
    return [newPath stringByAppendingString:@".mp4"];
}
+ (void)moveToFormalPath:(NSString *)tempPath
{
    NSString * newPath = [self getFormalPathFromTempPath:tempPath];
    if(![newPath isEqualToString:tempPath])
    {
        NSError * error = nil;
        [[NSFileManager defaultManager] moveItemAtPath:tempPath toPath:newPath error:&error];
        if(error)
        {
            NSLog(@"moveToFormalPath error :%@",error);
        }
    }
}
+ (BOOL)fileExist:(NSString *)file
{
    return [[NSFileManager defaultManager] fileExistsAtPath:file];
}
@end
