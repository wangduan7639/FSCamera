//
//  FSMovieWriter.h
//  FS
//
//  Created by wangduan on 14-2-19.
//  Copyright (c) 2014年 wxcp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol FSMovieWriterDelegate;
#define FRAME_PER_S 100.0

@interface FSMovieWriter : NSObject<AVAudioRecorderDelegate>
@property(readonly) double writedDuration;
@property(nonatomic,readonly) BOOL isFinished;
@property(nonatomic,assign) id<FSMovieWriterDelegate> delegate;
@property(nonatomic,assign) BOOL isFrontDevice;
- (id)initWithPath:(NSString *)path;

- (void)start;

- (void)pause;

- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer;

- (void)processVideoBuffer:(CMSampleBufferRef)videoBuffer;

- (void)end;

- (void)deleteFile;

- (void)cancel;

+ (UIImage *)getThumbImageWithPath:(NSString *)path;
@end


@protocol FSMovieWriterDelegate <NSObject>

@optional

- (void)movieWriterDidFinishWrite:(FSMovieWriter *)movieWriter;

@end