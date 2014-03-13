//
//  FSMovieView.m
//  FS
//
//  Created by wangduan on 14-3-3.
//  Copyright (c) 2014年 wxcp. All rights reserved.
//

#import "FSMovieView.h"
#import "CommonCameraTool.h"
#import "FileUtil.h"
#import "UIView+Addition.h"
#import "UIImageView+DispatchLoad.h"
#import "NSString+Addition.h"
#import "FSMovieView.h"
#import "FSPlayer.h"

#define MAX_RetryCount 1

@interface FSMovieView()
{
    BOOL _shouldPlay;
    UIView * _contentView;
    UIImageView * _imageView;
    int _retryCount;
}

@end
static BOOL shouldAllPause = NO;
@implementation FSMovieView
@synthesize addViewCountIDs = _addViewCountIDs;
@synthesize imageView = _imageView;
@synthesize tempImageId = _tempImageId;
@synthesize movieURL;
@synthesize playProgress;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        if([self respondsToSelector:@selector(setTranslatesAutoresizingMaskIntoConstraints:)])
            [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        _shouldPlay = NO;
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self addSubview:_imageView];
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.userInteractionEnabled = YES;
        _supportTouch = YES;
        
        //        if ([[LBFileClient sharedInstance] getNetworkingType] == 1) {
        //            //3G == 1 wu ==0 wifi ==2
        //
        //        }else{
        //            _hud = [[MBProgressHUD alloc] initWithView:self];
        //            _hud.color = [UIColor clearColor];
        //            [self addSubview:_hud];
        //        }
        
    }
    return self;
}

// 开始加入进度条并显示进度
- (void)startShowProgress{
    if (!playProgress) {
        //    UIView *progressBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 300 - 33, self.width, 33)];
        //    progressBgView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
        playProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        //    playProgress.frame = CGRectMake(0, 11 , progressBgView.width, 22);
        playProgress.frame = CGRectMake(0, 300 - 33, self.width, 33);
        [playProgress setProgressTintColor:[UIColor blackColor]];
        [playProgress setProgress:0];
        [playProgress setTrackTintColor:[UIColor grayColor]];
        //    [progressBgView addSubview:playProgress];
        [self addSubview:playProgress];
    }
    playProgress.hidden = NO;
    
    //
    double interval = .1f;
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        //            return;
    }
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        CGFloat width = CGRectGetWidth([playProgress bounds]);
        interval = 0.5f * duration / width;
    }
    AVPlayer * avPlayer = [FSPlayer sharedPlayer];
    [avPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        //获取当前时间
        [self syncScrubber];
    }];
}

// 重置进度条
- (void)resetShowProgress{
    [playProgress setProgress:0];
}

//隐藏进度条
- (void)hideProgress{
    playProgress.hidden = YES;
}

- (CMTime)playerItemDuration
{
    AVPlayer * avPlayer = [FSPlayer sharedPlayer];
	AVPlayerItem *playerItem = [avPlayer currentItem];
	if (playerItem.status == AVPlayerItemStatusReadyToPlay)
	{
        /*
         NOTE:
         Because of the dynamic nature of HTTP Live Streaming Media, the best practice
         for obtaining the duration of an AVPlayerItem object has changed in iOS 4.3.
         Prior to iOS 4.3, you would obtain the duration of a player item by fetching
         the value of the duration property of its associated AVAsset object. However,
         note that for HTTP Live Streaming Media the duration of a player item during
         any particular playback session may differ from the duration of its asset. For
         this reason a new key-value observable duration property has been defined on
         AVPlayerItem.
         
         See the AV Foundation Release Notes for iOS 4.3 for more information.
         */
        
		return([playerItem duration]);
	}
	
	return(kCMTimeInvalid);
}

- (void)syncScrubber
{
	CMTime playerDuration = [self playerItemDuration];
	if (CMTIME_IS_INVALID(playerDuration))
	{
		playProgress.progress = 0.0;
		return;
	}
    
	double duration = CMTimeGetSeconds(playerDuration);
	if (isfinite(duration))
	{
        //		float minValue = [playProgress minimumValue];
        //		float maxValue = [playProgress maximumValue];
        //		double time = CMTimeGetSeconds([mPlayer currentTime]);
		
        CMTime currentTime = ((AVPlayer *)[FSPlayer sharedPlayer]).currentItem.currentTime;
        CMTime durationTime = ((AVPlayer *)[FSPlayer sharedPlayer]).currentItem.duration;
        //转成秒数
        CGFloat currentPlayTime = (CGFloat)currentTime.value/currentTime.timescale;
        CGFloat duration = (CGFloat)durationTime.value/durationTime.timescale;
        //        NSLog(@"%f , %f ,%f ", currentPlayTime , duration ,currentPlayTime/duration);
        [playProgress setProgress:currentPlayTime/duration ];
        
	}
}


- (void)tapViewClicked:(UITapGestureRecognizer *)tapGesture{
    if(_supportTouch)
    {
        if([self isPlaying])
            [self pause];
        else
            [self play];
    }
}

- (void)hudShowWithIndeterminateStyle
{
    //    _hud.mode = MBProgressHUDModeIndeterminate;
    //    _hud.labelText = nil;
    //    if([_hud isHidden] == NO)
    //    {
    //        [_hud show:YES];
    //    }
}

- (void)hudShowWithDeterminateStyle
{
    //    if(_hud.mode != MBProgressHUDModeDeterminate)
    //    {
    //        _hud.mode = MBProgressHUDModeDeterminate;
    //        _hud.labelText = @"下载中...";
    //        _hud.progress = 0;
    //    }
    //    if([_hud isHidden] == NO)
    //    {
    //        [_hud show:YES];
    //    }
}

- (void)dealloc
{
    [self stop];
    [self crearViews];
}

- (void)crearViews{
    self.imageView = nil;
    _contentView = nil;
    self.addViewCountIDs = nil;
    self.playProgress = nil;
}

- (NSString *)getFinalPath:(NSString *)path
{
    if (path.length > 0 && [[path substringToIndex:4] isEqualToString:@"http"]) {
        return path;
    } else
        return nil;
    //        return [[Global getServerBaseUrl] stringByAppendingString:path];
}

- (void)setImageId:(NSString *)imageId
{
    self.tempImageId = imageId;
    if(imageId)
    {
        _imageView.image = nil;
        //        NSString * realUrl = [self getFinalPath:imageId];
        //        [_imageView setImageWithURL:[NSURL URLWithString:realUrl]];
    }
    else
    {
        _imageView.image = nil;
    }
}

- (void)setImageIdFroCache:(NSString *)imageId
{
    self.tempImageId = imageId;
    if(imageId)
    {
        _imageView.image = nil;
        //        NSString * realUrl = [self getFinalPath:imageId];
        //        [_imageView setImageWithURL:[NSURL URLWithString:realUrl]];
    }
    else
    {
        _imageView.image = nil;
    }
}

- (void)setImageFromUrl:(NSString *)imageId
{
    self.tempImageId = imageId;
    if ([imageId isEqualToString:@""]) {
        _imageView.image = nil;
        return;
    }
    if(imageId)
    {
        if(_imageView.image)
        {
            return;
        }
        _imageView.image = nil;
        NSString * realUrl = nil;
        if (imageId.length > 0 && [[imageId substringToIndex:4] isEqualToString:@"http"]) {
            realUrl = imageId;
        }else
            realUrl = [self getFinalPath:imageId];
        //[_imageView setImageWithURL1:[NSURL URLWithString:realUrl]];
        
        NSString *str = [FileUtil getCachePicPath] ;
        NSString *aa = [str stringByAppendingFormat:@"/%@",[realUrl md5Value]];
        UIImage *avatarImage = nil;
        NSData *data = [NSData dataWithContentsOfFile:aa];
        
        if(data)
        {
            avatarImage = [UIImage imageWithData:data];
            _imageView.image = avatarImage;
        }
        else
            [_imageView setImageFromUrl:realUrl
                             completion:^(void) {
                                 
                             }
             ];
    }
    else
    {
        _imageView.image = nil;
    }
}

- (void)setMovieId:(NSString *)movieId
{
    if(![_movieId isEqualToString:movieId])
    {
        [self stop];
        _retryCount = MAX_RetryCount;
        _movieId = [movieId copy];
        self.movieURL = nil;
        if(_movieId == nil)
        {
            //            [_hud hide:YES];
            //            LBMovieDownloader * downloader = [LBMovieDownloader sharedInstance];
            //            [downloader cancelAllWaitingOperation];
            //[_activity stopAnimating];
        }
        else
        {
            //            LBMovieDownloader * downloader = [LBMovieDownloader sharedInstance];
            //            if([Global canAutoDownLoad])
            //            {
            //                NSLog(@"[Global canAutoDownLoad]");
            //                [self hudShowWithIndeterminateStyle];
            //                //[downloader addMoviePath:movieId delegate:self];
            //            }
            //            if([[downloader dowloadingPath] isEqualToString:movieId] && [downloader isDownloading])
            //            {
            //                [self hudShowWithDeterminateStyle];
            //                _hud.progress = downloader.downloadPercent;
            //                [downloader setProgressDelegate:self];
            //            }
            //            else if(downloader.progressDelegate == self)
            //            {
            //                downloader.progressDelegate = nil;
            //                [_hud hide:NO];
            //            }
            //[_activity startAnimating];
        }
    }
}

- (void)setPlayerURL:(NSURL *)url
{
    self.movieURL = url;
}

- (void)layoutSubviews
{
    FSPlayer * player = [FSPlayer sharedPlayer];
    if(player.url == self.movieURL)
    {
        player.layer.frame = _imageView.bounds;
    }
    _imageView.frame = self.bounds;
    //_activity.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
}

- (void)play
{
    NSLog(@"movieview play");
    shouldAllPause = NO;
    _shouldPlay = YES;
    FSPlayer * player = [FSPlayer sharedPlayer];
    if(player.layer.superlayer != _imageView.layer)
    {
        [_imageView.layer addSublayer:player.layer];
        player.layer.frame = _imageView.bounds;
    }
    if([player.url isEqual:self.movieURL] && player.rate!=0)
        return;
    ;
    
    
    //NSString * baseString = [Global getServerUrl2];
    //NSString * realPath = [baseString stringByAppendingString:self.movieId];
    //    [player setURL:[NSURL URLWithString:@"https://s3.amazonaws.com/houston_city_dev/video/h264-original/1/haku.mp4"]];
    //    [player play];
    //    NSLog(@"LBPlayer duration:%f",CMTimeGetSeconds(player.currentItem.duration));
    //    return;
    
    BOOL flag  = [[NSFileManager defaultManager] fileExistsAtPath:[CommonCameraTool getCachePathForRemotePath:[self.movieId lastPathComponent]]];
    BOOL flag1 =  [[NSFileManager defaultManager] fileExistsAtPath:[self.movieURL path]];
    NSLog(@"%@", [CommonCameraTool getCachePathForRemotePath:[self.movieId lastPathComponent]]);
    if (flag) {
        if (![[self.movieURL path] isEqualToString:self.movieId]) {
            [player stop];
        }
        self.movieURL = [NSURL URLWithString:self.movieId];
    }
    //NSLog(@"is file exist:%d path:%@",flag,self.movieId);
    if(self.movieURL && (flag || flag1))
    {
        //        [_hud removeFromSuperview];
        //        [_imageView setImage:nil];
        //        [MobClick event:@"11" label:@"播放"];
        NSLog(@"播放缓存");
        [player setURL:self.movieURL];
        [player play];
        //double duration = CMTimeGetSeconds(player.currentItem.duration);
        //        if(duration == 0)
        //        {
        //            [[NSFileManager defaultManager] removeItemAtPath:[self.movieURL path] error:nil];
        //            if(--_retryCount >= 0)
        //            {
        //                [self play];
        //            }
        //        }
        
        /* 超过6秒视频加入状态条
         CMTime durationTime = ((AVPlayer *)[LBPlayer sharedPlayer]).currentItem.duration;
         CGFloat duration = (CGFloat)durationTime.value/durationTime.timescale;
         if (duration > 6) {
         [self startShowProgress];
         }
         */
        
    }
    else if(_movieId)
    {
        //         [self hideProgress];
        [player stop];
        
        //        if (!_hud) {
        //            _hud = [[MBProgressHUD alloc] initWithView:self];
        //            _hud.color = [UIColor clearColor];
        //            [self addSubview:_hud];
        //        }
        //        if (!_hud.superview) {
        //            [self addSubview:_hud];
        //        }
        //        LBMovieDownloader * downloader = [LBMovieDownloader sharedInstance];
        //        [downloader addMoviePath:_movieId delegate:self];
        //
        //        NSLog(@"%d  %d ",[[downloader dowloadingPath] isEqualToString:_movieId],[downloader isDownloading]);
        //        if([[downloader dowloadingPath] isEqualToString:_movieId] && [downloader isDownloading])
        //        {
        //            [self hudShowWithDeterminateStyle];
        //            _hud.progress = downloader.downloadPercent;
        //            _hud.labelText = [NSString stringWithFormat:@"%d%%",(int)(_hud.progress*100)];
        //            [downloader setProgressDelegate:self];
        //            NSLog(@"下载视频");
        //            if ([_addViewCountIDs count] == 2) {
        //                [[LBFileClient sharedInstance] addViewCount:_addViewCountIDs cachePolicy:NSURLRequestReloadIgnoringLocalCacheData delegate:nil selector:nil selectorError:nil];
        //            }
        //        }
        //        else if(downloader.progressDelegate == self)
        //        {
        //            downloader.progressDelegate = nil;
        //        }
        //
        //[_activity startAnimating];
    }
    else
    {
        [player stop];
        NSLog(@"play stop");
    }
}

- (BOOL)isPlaying
{
    FSPlayer * player = [FSPlayer sharedPlayer];
    
    if([player.url isEqual:self.movieURL] && player.rate!=0)
        return YES;
    else
        return NO;
}

- (void)pause
{
    _shouldPlay = NO;
    FSPlayer * player = [FSPlayer sharedPlayer];
    if([player.url isEqual:self.movieURL])
    {
        [player pause];
    }
}

- (void)stop
{
    _shouldPlay = NO;
    FSPlayer * player = [FSPlayer sharedPlayer];
    if([player.url isEqual:self.movieURL] && player.layer.superlayer == _imageView.layer )
    {
        [player stop];
    }
}

+ (void)pauseAll
{
    NSLog(@"pauseAll");
    shouldAllPause = YES;
    FSPlayer * player = [FSPlayer sharedPlayer];
    [player stop];
    //    [[LBMovieDownloader sharedInstance] cancelAllWaitingOperation];
    //[player setURL:nil];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    if(_supportTouch)
    {
        if([self isPlaying])
            [self pause];
        else
            [self play];
    }
}

- (UIView *)contentView
{
    if(!_contentView)
    {
        _contentView = [[UIView alloc] initWithFrame:self.bounds];
        [self addSubview:_contentView];
        _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _contentView;
}

#pragma mark LbMovieDownloaderDelegate
- (void)movieDownloaderDidStart:(NSString *)path
{
    NSLog(@"movieDownloaderDidStart");
    //if([path isEqualToString: self.movieId])
    //{
    [self hudShowWithDeterminateStyle];
    //}
}

- (void)movieDownloaderDidFinished:(NSString *)path
{
    //    [_hud hide:YES];
    if([path isEqualToString:self.movieId])
    {
        
        //BOOL flag = [[NSFileManager defaultManager] fileExistsAtPath:[LBCameraTool getCachePathForRemotePath:path]];
        //NSLog(@"file exsist:%d,%@",flag,[LBCameraTool getCachePathForRemotePath:path]);
        self.movieURL = [NSURL fileURLWithPath:[CommonCameraTool getCachePathForRemotePath:path]];
        if(_shouldPlay && !shouldAllPause)
        {
            [self play];
        }
    }
}

- (void)movieDownloaderDidFailed:(NSString *)path
{
    //if([path isEqualToString: self.movieId])
    {
        //        [_hud hide:YES];
    }
}

- (void)movieDownloaderProgress:(NSNumber *)percent
{
    //    _hud.progress = [percent floatValue];
    //    _hud.labelText = [NSString stringWithFormat:@"%d%%",(int)(_hud.progress*100)];
    //
    //    if((int)(_hud.progress*100) > 99)
    //    {
    //        [_hud setHidden:YES];
}

@end
