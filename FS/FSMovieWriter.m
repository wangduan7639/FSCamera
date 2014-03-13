//
//  FSMovieWriter.m
//  FS
//
//  Created by wangduan on 14-2-19.
//  Copyright (c) 2014年 wxcp. All rights reserved.
//

#import "FSMovieWriter.h"
#import "CommonCameraTool.h"
#import <CoreVideo/CoreVideo.h>
@interface FSMovieWriter ()
{
    NSString * _filePath;
    NSString * _tmpPath;
    NSString * _tmpAudioPath;
    AVAssetWriter * _assetWriter;
	AVAssetWriterInput * _assetWriterVideoInput;
    AVAssetWriterInputPixelBufferAdaptor * _assetWriterPixelBufferInput;
    AVAssetExportSession * _exportSession;
    CGSize _videoSize;
    AVAudioRecorder * _audioRecorder;
    BOOL _pause;
    BOOL _isCancel;
    double _writedDuration;
}
@property (nonatomic, assign) CMTime frameDuration;
@property (nonatomic, assign) CMTime nextPTS;
@property (nonatomic, assign) CMTime startTime;
@property (nonatomic, assign) NSInteger currentFrame;
@end
@implementation FSMovieWriter
@synthesize isFinished = _isFinished;
- (id)initWithPath:(NSString *)path
{
    self = [super init];
    if(self)
    {
        // 24 fps - taking 25 pictures will equal 1 second of video
        // = CMTimeMakeWithSeconds(1.0, FRAME_PER_S); CMTimeMakeWithSeconds(1./FRAME_PER_S, 90000);
        
        self.isFrontDevice = YES;
        self.frameDuration = CMTimeMakeWithSeconds(1./FRAME_PER_S, FRAME_PER_S);
        self.nextPTS = kCMTimeInvalid;
        _writedDuration = 0;
        
        _pause = NO;
        _filePath = [path copy];
        _tmpPath = [[CommonCameraTool getTempPathFromFormalPath:_filePath] copy];
        NSLog(@"_tmpPath = %@",_tmpPath);
        
        _videoSize = CGSizeMake(Movie_Width, Movie_Width);
        _assetWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:_tmpPath] fileType:AVFileTypeMPEG4 error:nil];
        _assetWriter.movieFragmentInterval =  self.frameDuration;//CMTimeMakeWithSeconds(1.0, 1000000000);
        _assetWriter.movieTimeScale = FRAME_PER_S;
        _assetWriter.shouldOptimizeForNetworkUse = NO;
        [self initializeMovieWriter];
        [self initializeAudioWriter];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initializeMovieWriter
{
    NSMutableDictionary * outputSettings = [NSMutableDictionary dictionaryWithCapacity:3];
    [outputSettings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
    [outputSettings setObject:[NSNumber numberWithInt:_videoSize.width] forKey:AVVideoWidthKey];
    [outputSettings setObject:[NSNumber numberWithInt:_videoSize.height] forKey:AVVideoHeightKey];
    [outputSettings setObject:AVVideoScalingModeResizeAspectFill forKey:AVVideoScalingModeKey];
    _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI_2);
    
    NSDictionary *videoCleanApertureSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSNumber numberWithInt:Movie_Width], AVVideoCleanApertureWidthKey,
                                                [NSNumber numberWithInt:Movie_Width], AVVideoCleanApertureHeightKey,
                                                [NSNumber numberWithInt:10], AVVideoCleanApertureHorizontalOffsetKey,
                                                [NSNumber numberWithInt:10], AVVideoCleanApertureVerticalOffsetKey,
                                                nil];
    
    
    NSDictionary* videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithDouble:_videoSize.width * _videoSize.height], AVVideoAverageBitRateKey,
                                           [NSNumber numberWithInt:1],AVVideoMaxKeyFrameIntervalKey,
                                           videoCleanApertureSettings, AVVideoCleanApertureKey,
                                           //AVVideoProfileLevelH264Baseline31,AVVideoProfileLevelKey,
                                           nil ];
    //kCVPixelFormatType_32BGRA
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [NSNumber numberWithInt:kCVPixelFormatType_32BGRA],  kCVPixelBufferPixelFormatTypeKey,
                                                           [NSNumber numberWithInt:_videoSize.width], kCVPixelBufferWidthKey,
                                                           [NSNumber numberWithInt:_videoSize.height],kCVPixelBufferHeightKey,
                                                           videoCompressionProps, AVVideoCompressionPropertiesKey,
                                                           nil];
    
    _assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_assetWriterVideoInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    [_assetWriter addInput:_assetWriterVideoInput];
}

- (void)initializeAudioWriter
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    [audioSession setMode:AVAudioSessionModeVideoRecording error:nil];
    //[audioSession setActive:YES error:nil];
    _tmpAudioPath = [_tmpPath stringByAppendingFormat:@".caf"];
    NSError * error = nil;
    _audioRecorder  = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:_tmpAudioPath] settings:[self recordingSettings] error:&error];
    if(error)
    {
        NSLog(@"_audioRecorder init error:%@",error);
    }
    _audioRecorder.delegate = self;
    [_audioRecorder prepareToRecord];
    return;
}

-(NSDictionary *)recordingSettings
{
    return nil;
    //    NSMutableDictionary * recordSettings = [NSMutableDictionary dictionaryWithCapacity:6];
    //    [recordSettings setObject:@(kAudioFormatMPEG4AAC) forKey: AVFormatIDKey];
    //    [recordSettings setObject:[NSNumber numberWithFloat:44100.0] forKey: AVSampleRateKey];
    //    [recordSettings setObject:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
    //    [recordSettings setObject:[NSNumber numberWithInt:12800] forKey:AVEncoderBitRateKey];
    //    [recordSettings setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    //    [recordSettings setObject:[NSNumber numberWithInt: AVAudioQualityHigh] forKey: AVEncoderAudioQualityKey];
    //    return recordSettings;
    
    double preferredHardwareSampleRate = [[AVAudioSession sharedInstance] currentHardwareSampleRate];
    AudioChannelLayout acl;
    bzero( &acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
            [ NSNumber numberWithInt: 2 ], AVNumberOfChannelsKey,
            [ NSNumber numberWithFloat: preferredHardwareSampleRate ], AVSampleRateKey,
            //[ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
            [ NSNumber numberWithInt:AVAudioQualityMax], AVEncoderAudioQualityKey,
            //[ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
            nil];
}

- (void)start
{
    //if(!isFinished)
    //[assetWriter startWriting];
    //[assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    [audioSession setMode:AVAudioSessionModeVideoRecording error:nil];
    if(![_audioRecorder isRecording] && !_isCancel)
        [_audioRecorder record];
}

- (void)pause
{
    [_audioRecorder pause];
    _pause = YES;
}

- (void)cancel
{
    _isCancel = YES;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    NSLog(@"assetWriter.status:%d",_assetWriter.status);
    if(_assetWriter.status == AVAssetWriterStatusWriting)
    {
        [_assetWriterVideoInput markAsFinished];
        [_assetWriter cancelWriting];
    }
    
    [_audioRecorder stop];
    [_exportSession cancelExport];
    //[self deleteTempFile];
    [self deleteFile];
}

- (void)end
{
    if(_isFinished == YES)
        return;
    _isFinished = YES;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    if(_assetWriter.status == AVAssetWriterStatusFailed)
    {
        UIAlertView *mAlertView = [[UIAlertView alloc] initWithTitle:@"视频合成失败" message:@"请退出重试" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        mAlertView.delegate = self;
        mAlertView.tag = 101;
        [mAlertView show];
        //        [[UIAlertView alertViewWithTitle:@"视频合成失败" message:@"请退出重试" cancelButtonTitle:@"确定" otherButtonTitles:nil onDismiss:^(int buttonIndex) {
        //
        //        } onCancel:^{
        //            [self cancel];
        //            [[[UIApplication sharedApplication] keyWindow].rootViewController dismissModalViewControllerAnimated:YES];
        //        } ] show];
        return;
    }
    [_assetWriterVideoInput markAsFinished];
    
    [_audioRecorder pause];
    NSLog(@"finishWriting");
    
    if([_assetWriter respondsToSelector:@selector(finishWritingWithCompletionHandler:)])
    {
        [_assetWriter finishWritingWithCompletionHandler:^{
            [_audioRecorder stop];
            NSLog(@"合成成功，大小为:%lldk",[self getFileSize:_tmpPath]/1000);
        }];
    }
    else
    {
        [_assetWriter finishWriting];
        [_audioRecorder stop];
        NSLog(@"合成成功，大小为:%lldk",[self getFileSize:_tmpPath]/1000);
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 101) {
        [self cancel];
        [[[UIApplication sharedApplication] keyWindow].rootViewController dismissModalViewControllerAnimated:YES];
        
    }
}

- (void)deleteFile
{
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString * outPutPath = _filePath;
    if([fileManager fileExistsAtPath:outPutPath])
    {
        [fileManager removeItemAtPath:outPutPath error:nil];
    }
}

- (void)deleteTempFile
{
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:_tmpPath])
    {
        [fileManager removeItemAtPath:_tmpPath error:nil];
    }
    [_audioRecorder deleteRecording];
    //    if([fileManager fileExistsAtPath:_tmpAudioPath])
    //    {
    //        [fileManager removeItemAtPath:_tmpAudioPath error:nil];
    //    }
}

- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer
{
    
}

- (void)processVideoBuffer:(CMSampleBufferRef)videoBuffer
{
    static int vCount = 0;
    vCount++;
    NSLog(@"vCount:%d",vCount);
    CMTime frameTime = CMSampleBufferGetPresentationTimeStamp(videoBuffer);
    if (((CMTIME_IS_INVALID(frameTime)) || (CMTIME_IS_INDEFINITE(frameTime))) && !_isCancel)
    {
        NSLog(@" reused buffer");
        return;
    }
    
    
    if ( _assetWriter.status == AVAssetWriterStatusUnknown)
    {
        if ([_assetWriter startWriting])
        {
			[_assetWriter startSessionAtSourceTime:frameTime];
            self.startTime = frameTime;
            self.nextPTS = self.startTime;
        }
		else
			[self showError:[_assetWriter error]];
	}
	if ( _assetWriter.status == AVAssetWriterStatusWriting)
    {
        if (_assetWriterVideoInput.readyForMoreMediaData)
        {
            if(CMTIME_IS_INVALID(self.nextPTS))
            {
                self.nextPTS = self.startTime;
            }
            
            //            CMSampleTimingInfo timingInfo;
            //            CMSampleBufferGetSampleTimingInfo (videoBuffer, 0, &timingInfo );
            //
            //            CMTime pts = timingInfo.presentationTimeStamp;
            //            timingInfo.duration = CMTimeMake(pts.timescale/FRAME_PER_S, pts.timescale);
            //            timingInfo.presentationTimeStamp = self.nextPTS;
            
            CMSampleTimingInfo timingInfo = kCMTimingInfoInvalid;
            timingInfo.duration = self.frameDuration;
            timingInfo.presentationTimeStamp = self.nextPTS;
            CMSampleBufferRef sbufWithNewTiming = NULL;
            
            OSStatus err = CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault,
                                                                 videoBuffer,
                                                                 1, // numSampleTimingEntries
                                                                 &timingInfo,
                                                                 &sbufWithNewTiming);
            if (err) {
                NSLog(@"CMSampleBufferCreateCopyWithNewTiming error");
                return;
            }
            
            if ([_assetWriterVideoInput appendSampleBuffer:sbufWithNewTiming])
            {
                self.nextPTS = CMTimeAdd(timingInfo.duration, self.nextPTS);
            }
            else
            {
                //NSError *error = [_assetWriter error];
                //NSLog(@"failed to append sbuf: %@", error);
            }
            CFRelease(sbufWithNewTiming);
            //            @synchronized(self)
            //            {
            //                _writedDuration = self.currentFrame/FRAME_PER_S;
            //            }
        }
        else
        {
            NSLog(@"not ready");
        }
        self.currentFrame++;
    }
    else if( _assetWriter.status == AVAssetWriterStatusFailed )
    {
        NSLog(@"error:%@",_assetWriter.error);
        //        _isCancel = YES;
        //
        //        UIAlertView * alert = [UIAlertView alertViewWithTitle:@"视频合成失败" message:@"请退出重试" cancelButtonTitle:@"确定"  otherButtonTitles:nil onDismiss:^(int buttonIndex) {
        //        } onCancel:^{
        //            [self cancel];
        //            [[[UIApplication sharedApplication] keyWindow].rootViewController dismissModalViewControllerAnimated:YES];
        //        }];
        //        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
        //        return;
    }
}
#define DegreesToRadians(degrees) (degrees * M_PI / 180)
#define degreesToRadians(x) (M_PI * (x) / 180.0)
- (void)composition
{
    AVMutableComposition *avMutableComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack * avMutableCompositionTrack = [avMutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack * auMutableCompositionTrack = [avMutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    //音频轨
    NSFileManager * fm = [NSFileManager defaultManager];
    if([fm fileExistsAtPath:_tmpAudioPath])
    {
        NSLog(@"has audio");
    }
    else
    {
        NSLog(@"no audio");
    }
    AVURLAsset *auAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:_tmpAudioPath]];
    CMTime auAssetTime = [auAsset duration];
    double auDuration = CMTimeGetSeconds(auAssetTime);
    NSLog(@"音频时长 %f\n",auDuration);
    
    AVAsset *avAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:_tmpPath]];
    CMTime avAssetTime = [avAsset duration];
    //double avDuration = CMTimeGetSeconds(avAssetTime);
    //NSLog(@"视频时长 %f\n",avDuration);
    
    double duration = auDuration;//MIN(MAX(auDuration, avDuration), 6.0);
    CMTime newTime = CMTimeMakeWithSeconds(duration, avMutableCompositionTrack.naturalTimeScale);
    
    
    AVAssetTrack * auAssetTrack = [[auAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    [auMutableCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, auAssetTime)
                                       ofTrack:auAssetTrack
                                        atTime:kCMTimeZero
                                         error:nil];
    [auMutableCompositionTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, auAssetTime) toDuration:newTime];
    
    //视频轨
    AVAssetTrack *avAssetTrack = [[avAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    [avMutableCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, avAssetTime)
                                       ofTrack:avAssetTrack
                                        atTime:kCMTimeZero
                                         error:nil];
    //avMutableCompositionTrack.preferredTransform = CGAffineTransformMakeRotation(M_PI_2);
    [avMutableCompositionTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, avAssetTime) toDuration:newTime];
    
    AVMutableVideoCompositionLayerInstruction *instruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:avAssetTrack];
    CGAffineTransform rotationTransform;
    CGAffineTransform rotateTranslate;
    if(!self.isFrontDevice)
    {
        rotationTransform = CGAffineTransformMakeRotation(M_PI_2);
        rotateTranslate = CGAffineTransformTranslate(rotationTransform,0,-Movie_Width);
    }
    else
    {
        rotationTransform = CGAffineTransformMakeRotation(M_PI*3/2);
        rotateTranslate = CGAffineTransformScale(rotationTransform, -1, 1);
    }
    
    //    CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(M_PI_2);
    //    CGAffineTransform rotateTranslate = CGAffineTransformTranslate(rotationTransform,0,-Movie_Width);
    //
    
    //    CGAffineTransform rotationTransform1 = CGAffineTransformMakeRotation(M_PI*3/2);
    //    CGAffineTransform  transform = CGAffineTransformScale(rotationTransform1, -1, 1);
    
    
    
    [instruction setTransform:rotateTranslate atTime:kCMTimeZero];
    
    // create the composition instructions for the range of this clip
    AVMutableVideoCompositionInstruction * videoTrackInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    //videoTrackInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, auAssetTime);
    videoTrackInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, newTime);
    videoTrackInstruction.layerInstructions = @[instruction];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.instructions = @[videoTrackInstruction];
    videoComposition.frameDuration = CMTimeMake(1,avMutableCompositionTrack.naturalTimeScale);
    videoComposition.renderSize = CGSizeMake(Movie_Width, Movie_Width);
    
    
    
    NSString * outputFile = _filePath;
    if ([fm fileExistsAtPath:outputFile])
    {
        NSLog(@"video is have. then delete that");
        if ([fm removeItemAtPath:outputFile error:nil]){
            NSLog(@"delete is ok");
        }
        else{
            NSLog(@"delete is no error");
        }
    }
    
    [self compressWithAsset:avMutableComposition videoComposition:videoComposition];
}

- (void)compressWithAsset:(AVAsset *)asset videoComposition:(AVVideoComposition *)videoComposition
{
    //AVAsset *avAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:_filePath]];
    AVAssetExportSession * exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    if(videoComposition)
        exportSession.videoComposition = videoComposition;
    _exportSession = exportSession;
    [exportSession setOutputURL:[NSURL fileURLWithPath:_filePath]];
    
    NSArray *supportedTypeArray=exportSession.supportedFileTypes;
    BOOL hasFileTypeMPEG = NO;
    for (NSString *str in supportedTypeArray)
    {
        if([str isEqualToString:AVFileTypeMPEG4])
            hasFileTypeMPEG = YES;
    }
    
    [exportSession setOutputFileType:hasFileTypeMPEG?AVFileTypeMPEG4:AVFileTypeQuickTimeMovie];
    [exportSession setShouldOptimizeForNetworkUse:YES];
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void)
     {
         switch (exportSession.status)
         {
             case AVAssetExportSessionStatusFailed:
                 NSLog(@"AVAssetExportSessionStatusFailed %@",[exportSession error]);
                 break;
             case AVAssetExportSessionStatusCompleted:
                 NSLog(@"AVAssetExportSessionStatusCompleted");
                 NSLog(@"压缩成功，大小为:%lldk",[self getFileSize:_filePath]/1000);
                 break;
             case AVAssetExportSessionStatusCancelled:
                 NSLog(@"AVAssetExportSessionStatusCancelled");
                 break;
         }
         [self performSelectorOnMainThread:@selector(didFinishCompress) withObject:nil waitUntilDone:NO];
     }];
    
}

- (NSTimeInterval)writedDuration
{
    return _audioRecorder.currentTime;
}
#pragma mark AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    
    NSLog(@"audioRecorderDidFinishRecording:%d",flag);
    if(flag == 1)
    {
        if(_isCancel == NO)
            [self composition];
    }
    else
        [self showMsg:@"音频合成失败"];
}



- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];
    [self showMsg:@"音频录制出错"];
    
}

- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder
{
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];
    [self showMsg:@"音频录制出错"];
}


#pragma mark ThumbImage

- (void)createThumbImage
{
    UIImage * image = [CommonCameraTool  createThumbImageWithPath:_filePath];
    NSData * imageData = UIImageJPEGRepresentation(image, 0.4);
    [imageData writeToFile:[CommonCameraTool getThumbPathWithPath:_filePath] atomically:YES];
}

- (void)didFinishCompress
{
    _exportSession = nil;
    [self deleteTempFile];
    [self createThumbImage];
    NSLog(@"delete temp finished");
    if([self.delegate respondsToSelector:@selector(movieWriterDidFinishWrite:)])
    {
        [self.delegate movieWriterDidFinishWrite:self];
    }
}

+ (UIImage *)getThumbImageWithPath:(NSString *)path
{
    NSError *error = nil;
    CMTime imgTime = kCMTimeZero;
    AVAsset * asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:path]];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    //generator.maximumSize = size;
    CGImageRef cgIm = [generator copyCGImageAtTime:imgTime
                                        actualTime:NULL
                                             error:&error];
    UIImage *image = [UIImage imageWithCGImage:cgIm scale:1 orientation:UIImageOrientationRight];
    CGImageRelease(cgIm);
    if (nil != error)
    {
        NSLog(@"Error making screenshot: %@", [error localizedDescription]);
        return nil;
    }
    return image;
}
#pragma mark Error Handling

- (void)showError:(NSError *)error
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                            message:[error localizedFailureReason]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    });
}

- (void)showMsg:(NSString *)msg
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:msg
                                                            message:nil
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    });
}


- (unsigned long long)getFileSize:(NSString *)path
{
    NSDictionary * dict = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    return [dict fileSize];
}

//- (NSString *)getTempPathFromPath:(NSString *)path
//{
//    NSRange range = [path rangeOfString:@"." options:NSBackwardsSearch];
//    if (range.location == NSNotFound)
//    {
//        return [path stringByAppendingString:@".tmp"];
//    }
//    else
//    {
//        return [path stringByReplacingCharactersInRange:range withString:@"_tmp."];
//    }
//
//}

#pragma mark NSNotification

- (void)willResignActive
{
    [self pause];
}

- (void)didBecomeActive
{
    
}
@end
