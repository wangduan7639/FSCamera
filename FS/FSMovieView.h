//
//  FSMovieView.h
//  FS
//
//  Created by wangduan on 14-3-3.
//  Copyright (c) 2014年 wxcp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FSMovieView : UIView
// 图片的地址
@property(nonatomic,strong)     NSString    *imageId;
//
@property(nonatomic,strong)     NSString    *tempImageId;
// 图片控件载体
@property(nonatomic,strong)     UIImageView *imageView;
// 视频地址
@property(nonatomic,retain)     NSString    *movieId;
//
@property(nonatomic,retain)     NSArray     *addViewCountIDs;
// 支持触摸暂停 默认为支持
@property(nonatomic,assign)     BOOL        supportTouch;
// 视频地址URL
@property(nonatomic,copy)       NSURL       *movieURL;
// 容器，容纳图片和播放的视频
@property(nonatomic,readonly)   UIView      *contentView;
// 播放精度条
@property(nonatomic, strong)    UIProgressView *playProgress;


/**
 *  只能播放本地地址，暂时不支持下载
 *
 */

/**
 *  放入需要播放的视频的URL
 */
- (void)setPlayerURL:(NSURL *)url;

/**
 *  开始播放视频
 */
- (void)play;

/**
 *  暂停正在播放的视频，并 view 保留当前播放祯
 */
- (void)pause;

/**
 *  停掉正在播放的视频，并把view 变为透明
 */
- (void)stop;

/**
 *  暂停掉所有得播放视频，并把 view变为透明
 */
+ (void)pauseAll;

/**
 *  是否是正在播放，如果在播放返回YES 否则返回 NO
 */
- (BOOL)isPlaying;

/**
 *  给视频设置路径，
 *  param movieId 传入会后自动调用setPlayerURL:(NSURL *)url;
 */
- (void)setMovieId:(NSString *)movieId;

/**
 *  下载视频的路径
 *   param movieID
 */
//- (void)downloadNext:(NSString*)movieId;

/**
 *  设置播放界面首帧图片的地址 ，如果有缓存就用
 *  param movieId 图片的地址，NSString类型
 */
- (void)setImageIdFroCache:(NSString *)imageId;

/**
 *  设置图片下载地址
 */
- (void)setImageFromUrl:(NSString *)imageId;

/**
 *  当未播放时，播放视频
 *  当播放时，暂停视频
 */
- (void)tapViewClicked:(UITapGestureRecognizer *)tapGesture;

/**
 *  开始加入进度条并显示进度
 */
- (void)startShowProgress;


/**
 *  重置进度条
 */
- (void)resetShowProgress;

/**
 *  隐藏进度条
 */
- (void)hideProgress;
@end
