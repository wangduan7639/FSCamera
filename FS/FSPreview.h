//
//  FSPreview.h
//  FS
//
//  Created by wangduan on 14-2-19.
//  Copyright (c) 2014年 wxcp. All rights reserved.
//
// 录像预览视图
#import <UIKit/UIKit.h>

@protocol FSPreviewDelegate <NSObject>

@optional
- (void)didLayoutSubviews:(UIView *)view;
- (void)drawView:(UIView *)view;

@end

@interface FSPreview : UIView

@property(nonatomic,assign)id<FSPreviewDelegate> delegate;
@property(nonatomic,retain)UIView * contentView;
@end
