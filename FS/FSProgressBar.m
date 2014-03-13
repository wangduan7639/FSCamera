//
//  FSMovieView.m
//  FS
//
//  Created by wangduan on 14-3-3.
//  Copyright (c) 2014年 wxcp. All rights reserved.
//

#import "FSProgressBar.h"

@implementation FSProgressBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _barView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0, self.height)];
        _backgroundView = [[UIImageView alloc] initWithFrame:self.bounds];
        [_backgroundView setClipsToBounds:YES];
        _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_backgroundView];
        [_backgroundView addSubview:_barView];
        
        _progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 20)];
        _progressLabel.font = [UIFont systemFontOfSize:10.0f];
        _progressLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:_progressLabel];
        
        [self resetProgress];
    }
    return self;
}

- (void)layoutSubviews
{
    _barView.frame = CGRectMake(0, 0, _backgroundView.width*_progress, self.height);
    _progressLabel.left = _backgroundView.left + _backgroundView.right + 4;
    _progressLabel.centerY = _barView.centerY;

}

- (void)resetProgress
{
    _progress = 0.0;
    _barView.width = 0.0 * _backgroundView.width;
}

- (void)setProgress:(float)progress
{
    if (progress == 0.000000) {
        return;
    }
    _progress = progress;
    _barView.width = progress * _backgroundView.width;
    _progressLabel.text = [NSString stringWithFormat:@"%.1f%%", _progress*100];
}

- (float)progress
{
    return _progress;
}

- (void)setBackgroundImage:(UIImage *)image
{
    _backgroundView.image = image;
}

- (void)setProgressImage:(UIImage *)image
{
    _barView.image = image;
    _barView.height = image.size.height;
    _barView.centerY = _backgroundView.height/2.0;
}

- (void)setBarColor:(UIColor *)color
{
    _barView.backgroundColor = color;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    _backgroundView.backgroundColor = backgroundColor;
}
@end
