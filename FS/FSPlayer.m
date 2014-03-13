//
//  FSPlayer.m
//  FS
//
//  Created by wangduan on 14-3-3.
//  Copyright (c) 2014年 wxcp. All rights reserved.
//

#import "FSPlayer.h"
@interface FSPlayer()
{
    float _rateFlag; //用于记录退出前播放状态
}

@end

@implementation FSPlayer
+ (id)sharedPlayer
{
    static FSPlayer *sharedInstance = nil;
    static dispatch_once_t predicate = 0;
    dispatch_once(&predicate, ^{
        sharedInstance = [[self alloc] initWithURL:nil];
    });
    
    return sharedInstance;
}

- (AVPlayerLayer *)createLayer
{
    AVPlayerLayer * layer = [AVPlayerLayer playerLayerWithPlayer:self];
    layer.backgroundColor = [UIColor clearColor].CGColor;
    layer.contentsScale = [[UIScreen mainScreen] scale];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.frame = _layer.bounds;
    NSDictionary *newActions = [[NSDictionary alloc] initWithObjectsAndKeys:
                                [NSNull null], @"onOrderIn",
                                [NSNull null], @"onOrderOut",
                                [NSNull null], @"sublayers",
                                [NSNull null], @"contents",
                                [NSNull null], @"bounds",
                                nil];
    layer.actions = newActions;
    layer.hidden = YES;
    
    return layer;
}

- (void)getFreeLayer
{
    
}

- (id)initWithURL:(NSURL *)url;
{
    self = [super initWithURL:url];
    if(self)
    {
        _url = [url copy];
        _layer = [FSLayoutLayer layer];
        _layer.layoutDelegate = self;
        [_layer setLayoutMethod:@selector(layoutSublayersWithLayer:)];
        _layer.backgroundColor = [UIColor clearColor].CGColor;
        
        //_playerLayer = [self createLayer];
        _playerLayer =  nil;
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self];
        //[_layer addSublayer:_playerLayer];
        NSDictionary *newActions = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    [NSNull null], @"onOrderIn",
                                    [NSNull null], @"onOrderOut",
                                    [NSNull null], @"sublayers",
                                    [NSNull null], @"contents",
                                    [NSNull null], @"bounds",
                                    nil];
        _layer.actions = newActions;
        _layer.contentsScale = [[UIScreen mainScreen] scale];
        //        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        //        [_playerLayer addObserver:self forKeyPath:@"readyForDisplay" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"currentItem.status" options:NSKeyValueObservingOptionNew context:nil];
        self.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidNotReachEnd:)
                                                     name:AVPlayerItemFailedToPlayToEndTimeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"currentItem.status"])
    {
        NSNumber * newValue = change[NSKeyValueChangeNewKey];
        if ([newValue isKindOfClass:[NSNull class]]) {
            return;
        }
        
        if( [newValue integerValue] == AVPlayerStatusReadyToPlay)
        {
            _playerLayer.player = self;
            _playerLayer.hidden = NO;
        }
        
    }
    else  if([keyPath isEqualToString:@"readyForDisplay"])
    {
        NSLog(@"change:%@",change);
        NSNumber * newValue = change[NSKeyValueChangeNewKey];
        if([newValue boolValue] == YES)
        {
            NSLog(@"readyForDisplay == YES");
            _playerLayer.hidden = NO;
        }
        else
        {
            NSLog(@"readyForDisplay == NO");
            //_playerLayer.hidden = YES;
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)layoutSublayersWithLayer:(CALayer *)layer
{
    _playerLayer.frame = _layer.bounds;
    
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"currentItem.status"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setURL:(NSURL *)url
{
    if(![_url isEqual:url] && url!=_url)
    {
        _url = [url copy];
        _playerLayer.hidden = YES;
        _playerLayer.player = nil;
        AVPlayerItem * item = [AVPlayerItem playerItemWithURL:url];
        [self replaceCurrentItemWithPlayerItem:item];
        //        AVPlayerLayer * newLayer = [self createLayer];
        //
        //        [_layer addSublayer:newLayer];
        //        [_playerLayer removeFromSuperlayer];
        //        _playerLayer = newLayer;
        
    }
}

- (NSURL *)url
{
    return _url;
}

- (void)playerItemDidReachEnd:(NSNotification *)sender
{
    AVPlayerItem * item = sender.object;
    if(item == self.currentItem)
    {
        [self seekToTime:kCMTimeZero];
    }
}

- (void)playerItemDidNotReachEnd:(NSNotification *)sender
{
    //这个函数没有实现引发崩溃  : unrecognized selector sent to instance 0x2103ccb0
    //libc++abi.dylib: handler threw exception
}

- (void)stop
{
    [self pause];
    //[self seekToTime:kCMTimeZero];
    [_playerLayer removeFromSuperlayer];
    //_playerLayer.hidden = YES;
}



- (void)play
{
    if(self.layer.superlayer != nil)
    {
        if(_playerLayer.superlayer != _layer)
        {
            [_layer addSublayer:_playerLayer];
        }
        [super play];
        NSLog(@"LBPlayer duration:%f",CMTimeGetSeconds(self.currentItem.duration));
        //[_playerLayer performSelector:@selector(setHidden:) withObject:@NO afterDelay:1];
        //_playerLayer.hidden = NO;
    }
}

- (void)willResignActive
{
    _rateFlag = self.rate;
}

- (void)willEnterForeground
{
    self.rate = _rateFlag;
}
@end
