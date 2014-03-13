//
//  FSLayoutLayer.h
//  FS
//
//  Created by wangduan on 14-3-3.
//  Copyright (c) 2014年 wxcp. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface FSLayoutLayer : CALayer
{
    SEL _layoutMethod;
}
@property(nonatomic,assign) id layoutDelegate;

- (void)setLayoutMethod: (SEL)method; //- (void)layoutSublayersWithLayer:(CALayer *)layer

@end
