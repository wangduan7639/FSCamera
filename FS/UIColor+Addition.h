//
//  UIColor+Addition.h
//  Tudou
//
//  Created by zhang jiangshan on 12-11-19.
//  Copyright (c) 2012年 Lebo.com inc. All rights reserved.
//

#import <Foundation/Foundation.h>

//颜色
#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define RGB(r,g,b) RGBA(r,g,b,1.0f)
// 用16进制直接赋值颜色
#define UIColorFromRGB(rgbValue) [UIColor \ colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \ green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \ blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface UIColor (Addition)

+ (UIColor *) cameraBg;

+ (UIColor *) homeBg;
@end
