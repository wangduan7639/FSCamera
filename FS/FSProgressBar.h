//
//  FSMovieView.h
//  FS
//
//  Created by wangduan on 14-3-3.
//  Copyright (c) 2014年 wxcp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIView+Addition.h"

@interface FSProgressBar : UIView
{
    UIImageView * _barView;
    UIImageView * _backgroundView;
    UILabel     * _progressLabel;
    float _progress;
}
@property(nonatomic,assign) float progress;
- (void)setBackgroundImage:(UIImage *)image;

- (void)setProgressImage:(UIImage *)image;

- (void)setBarColor:(UIColor *)color;

- (void)setBackgroundColor:(UIColor *)backgroundColor;
@end
