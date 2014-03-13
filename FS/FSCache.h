//
//  FSCache.h
//  FS
//
//  Created by wangduan on 14-2-19.
//  Copyright (c) 2014年 wxcp. All rights reserved.
//

#import <Foundation/Foundation.h>
//基于path的cache
@interface FSCache : NSCache
+ (id)sharedInstance;

- (UIImage *)cacheImageForPath:(NSString *)path;

- (NSData *)cacheForPath:(NSString *)path;
@end
