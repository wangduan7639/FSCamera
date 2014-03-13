//
//  FSCache.m
//  FS
//
//  Created by wangduan on 14-2-19.
//  Copyright (c) 2014年 wxcp. All rights reserved.
//

#import "FSCache.h"

@implementation FSCache
+ (id)sharedInstance
{
    static FSCache *sharedInstance = nil;
    static dispatch_once_t predicate = 0;
    dispatch_once(&predicate, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (UIImage *)cacheImageForPath:(NSString *)path
{
    id obj = [self objectForKey:path];
    if(!obj)
    {
        if([[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            UIImage * img = [[UIImage alloc] initWithContentsOfFile:path];
            if(img)
                [self setObject:img forKey:path];
            obj = img;
        }
    }
    return obj;
}

- (NSData *)cacheForPath:(NSString *)path
{
    id obj = [self objectForKey:path];
    if(!obj)
    {
        if([[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            NSData * data = [[NSData alloc] initWithContentsOfFile:path];
            if(data)
                [self setObject:data forKey:path];
            obj = data;
        }
    }
    return obj;
}

@end
