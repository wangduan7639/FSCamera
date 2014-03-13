//
//  FSPlayer.h
//  FS
//
//  Created by wangduan on 14-3-3.
//  Copyright (c) 2014年 wxcp. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "FSLayoutLayer.h"
@interface FSPlayer : AVPlayer
{
    NSURL * _url;
    AVPlayerLayer * _playerLayer;
}
@property(nonatomic,readonly) NSURL * url;
@property(nonatomic,readonly) FSLayoutLayer * layer;

+ (id)sharedPlayer;

- (id)initWithURL:(NSURL *)url;

- (void)setURL:(NSURL *)url;

- (void)stop;
@end

