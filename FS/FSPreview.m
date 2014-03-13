//
//  FSPreview.m
//  FS
//
//  Created by wangduan on 14-2-19.
//  Copyright (c) 2014年 wxcp. All rights reserved.
//

#import "FSPreview.h"

@implementation FSPreview
@synthesize contentView = _contentView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.contentView = [[UIView alloc] initWithFrame:frame];
        [self.contentView setBackgroundColor:[UIColor blackColor]];
        [self addSubview:_contentView];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    if([self.delegate respondsToSelector:@selector(drawView:)])
        [self.delegate drawView:self];
}

- (void)layoutSubviews
{
    if([self.delegate respondsToSelector:@selector(didLayoutSubviews:)])
        [self.delegate didLayoutSubviews:self];
}

@end
