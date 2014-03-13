//
//  FSLayoutLayer.m
//  FS
//
//  Created by wangduan on 14-3-3.
//  Copyright (c) 2014年 wxcp. All rights reserved.
//

#import "FSLayoutLayer.h"

@implementation FSLayoutLayer
- (void)layoutSublayers
{
    if([self.layoutDelegate respondsToSelector:_layoutMethod])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.layoutDelegate performSelector:_layoutMethod withObject:self];
#pragma clang diagnostic pop
        
    }
}

- (void)setLayoutMethod:(SEL)method
{
    _layoutMethod = method;
}
@end

