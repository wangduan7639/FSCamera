//
//  FSCamera.m
//  FS
//
//  Created by wangduan on 14-2-19.
//  Copyright (c) 2014年 wxcp. All rights reserved.
//

#import "FSCamera.h"
#import "CommonCameraTool.h"
#import "UIImage+rotate.h"
#import "UIDevice+Hardware.h"
#import "FSMovieWriter.h"
@interface FSCamera ()<FSMovieWriterDelegate>
{
    AVCaptureSession * _session;
    AVCaptureVideoPreviewLayer * _layer;
    AVCaptureDeviceInput * _videoInput;
    BOOL _shouldRecord;
    BOOL _shouldCapture;
    FSMovieWriter * _movieWriter;
}
@end
@implementation FSCamera
@dynamic cameraPosition;
@dynamic writedDuration;
@synthesize waterImage;
- (id)init{
    
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy_MM_dd_hh_mm_ss"];
    NSDate * now = [NSDate date];
    NSString * dateString = [dateFormatter stringFromDate:now];
    NSString * path = [[CommonCameraTool videoPathWithName:dateString] stringByAppendingString:@".mp4"];
    
    if ([self initWithFilePath:path]) {
        
    }
    
    return self;
}

- (id)initWithFilePath:(NSString *)filePath
{
    self = [super init];
    if(self)
    {
        NSFileManager * fm = [NSFileManager defaultManager];
        if([fm fileExistsAtPath:filePath])
        {
            NSError * removeError = nil;
            [fm removeItemAtPath:filePath error:&removeError];
            if(removeError)
            {
                NSLog(@"remove error :%@",removeError);
            }
        }
        _shouldCapture = NO;
        _shouldRecord = NO;
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        
        //        _movieWriter = [[LBMovieWriter alloc] initWithPath:filePath];
        //        _movieWriter.delegate = self;
        [self performSelectorInBackground:@selector(writeCapture:) withObject:filePath];
        _videoPath = [filePath copy];
        if([self initialSession])
        {
        
        }
    }
    return self;
}
//录像的路径
- (void)writeCapture:(NSString *)filePath{
    _movieWriter = [[FSMovieWriter alloc] initWithPath:filePath];
    _movieWriter.delegate = self;
}
- (BOOL)shouldAlwaysDiscardsLateVideoFrames
{
    NSInteger cpuCount = [[UIDevice currentDevice] cpuCount];
    NSLog(@"cpuCount:%ld",(long)cpuCount);
    if(cpuCount>1)
        return NO;
    else
        return YES;
}
//视频输入设置
- (void)configInputVideoDevice:(AVCaptureDevice *)videoDevice
{
    //视频输入设置
    [videoDevice lockForConfiguration:nil];
    //自动对焦
    if([videoDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
        videoDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    else if([videoDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus])
        videoDevice.focusMode = AVCaptureFocusModeAutoFocus;
    if([videoDevice isFocusPointOfInterestSupported])
        [videoDevice setFocusPointOfInterest:CGPointMake(.5, .5)];
    //曝光
    if([videoDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
        videoDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    else if([videoDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose])
        videoDevice.exposureMode = AVCaptureExposureModeAutoExpose;
    if([videoDevice isExposurePointOfInterestSupported])
        [videoDevice setExposurePointOfInterest:CGPointMake(.5, .5)];
    //白平衡
    if([videoDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
        videoDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
    else if([videoDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance])
        videoDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeAutoWhiteBalance;
    //
    
    if([videoDevice respondsToSelector:@selector(isLowLightBoostSupported)])
    {
        if(videoDevice.lowLightBoostSupported == YES)
            videoDevice.automaticallyEnablesLowLightBoostWhenAvailable = YES;
    }
    [videoDevice unlockForConfiguration];
}
- (void)handleError:(NSError *)error
{
    NSLog(@"capture error:%@",[error localizedDescription]);
}
- (BOOL)initialSession
{
    _session = [[AVCaptureSession alloc] init];
    [_session beginConfiguration];
    if([self shouldAlwaysDiscardsLateVideoFrames] == NO)
        _session.sessionPreset = AVCaptureSessionPreset640x480;
    _layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    _layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _layer.contentsScale = [[UIScreen mainScreen] scale];
    //[_session addObserver:self forKeyPath:@"interrupted" options:NSKeyValueObservingOptionNew context:nil];
    
    _cameraView = [[FSPreview alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
    _cameraView.backgroundColor = [UIColor blackColor];
    [_cameraView.layer addSublayer:_layer];
    _cameraView.delegate = self;
    
    AVCaptureDevice * videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    [self configInputVideoDevice:videoDevice];
    
    _videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if(error)
    {
        [self handleError:error];
        return NO;
    }
    
    //    AVCaptureDevice * audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    //    AVCaptureDeviceInput * audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    //    if(error)
    //    {
    //        [self handleError:error];
    //        return NO;
    //    }
    [_session addInput:_videoInput];
    //[_session addInput:audioInput];
    
    AVCaptureVideoDataOutput * videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    {
        //视频输出设置
        [videoOutput setAlwaysDiscardsLateVideoFrames:[self shouldAlwaysDiscardsLateVideoFrames]];
        AVCaptureConnection *videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
        if (videoConnection.supportsVideoMinFrameDuration)
            videoConnection.videoMinFrameDuration = CMTimeMake(1,100);
        if (videoConnection.supportsVideoMaxFrameDuration)
            videoConnection.videoMaxFrameDuration = CMTimeMake(1,100);
        if ([videoConnection isVideoOrientationSupported])
        {
            AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortrait;
            [videoConnection setVideoOrientation:orientation];
        }
        if ([videoConnection respondsToSelector:@selector(setEnablesVideoStabilizationWhenAvailable:)])
            [videoConnection setEnablesVideoStabilizationWhenAvailable:YES];
        
        //        BOOL supportsFullYUVRange = NO;
        //        NSArray *supportedPixelFormats = videoOutput.availableVideoCVPixelFormatTypes;
        //        for (NSNumber *currentPixelFormat in supportedPixelFormats)
        //        {
        //            if ([currentPixelFormat intValue] == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        //            {
        //                supportsFullYUVRange = YES;
        //                break;
        //            }
        //        }
        //        if (supportsFullYUVRange)
        //        {
        //            [videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        //        }
        //        else
        //        {
        //            [videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        //        }
        [videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        
    }
    dispatch_queue_t videoProcessingQueue = dispatch_queue_create(nil, NULL);
    [videoOutput setSampleBufferDelegate:self queue:videoProcessingQueue];
    [_session addOutput:videoOutput];
    //[videoOutput release];
    
    //    AVCaptureAudioDataOutput * audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    //    [audioOutput setSampleBufferDelegate:self queue:videoProcessingQueue];
    //    [_session addOutput:audioOutput];
    //[audioOutput release];
    //    dispatch_release(videoProcessingQueue);
    
    //[self reConfigPreset];
    [_session commitConfiguration];
    return YES;
}
- (void)startCapture
{
    _shouldCapture = YES;
    if(![_session isRunning])
    {
        [_session startRunning];
        //        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //            [_session startRunning];;
        //        });
    }
}

- (void)endCapture
{
    _shouldCapture = NO;
    [self pauseRecord];
    if(_session.running)
        [_session stopRunning];
}

- (void)startRecord
{
    NSLog(@"camera start");
    
    _shouldRecord = YES;
    
    [_movieWriter start];
    
}

- (void)pauseRecord
{
    NSLog(@"camera pause");
    _shouldRecord = NO;
    [_movieWriter pause];
}

- (void)endRecord
{
    _shouldRecord = NO;
    [_movieWriter end];
}

- (void)clearFile
{
    [_movieWriter deleteFile];
}

- (void)cancel
{
    [self endCapture];
    _shouldRecord = NO;
    [_movieWriter cancel];
}

- (BOOL)isSessionRunning
{
    return [_session isRunning];
}
- (double)writedDuration
{
    return [_movieWriter writedDuration];
}

- (void)dealloc
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    _movieWriter.delegate = nil;
    [self clearSession];
}
- (void)clearSession
{
    //[_session removeObserver:self forKeyPath:@"interrupted"];
}

- (void)setCameraPosition:(AVCaptureDevicePosition)cameraPosition
{
    if(cameraPosition != self.cameraPosition)
    {
        [self endCapture];
        [_session beginConfiguration];
        [_session removeInput:_videoInput];
        AVCaptureDevice * device = nil;
        NSArray * devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for(AVCaptureDevice * temp in devices)
        {
            if(temp.position == cameraPosition)
            {
                device = temp;
                break;
            }
        }
        [self configInputVideoDevice:device];
        NSError *error = nil;
        _videoInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        [_session addInput:_videoInput];
        //[self reConfigPreset];
        [_session commitConfiguration];
        [_session performSelector:@selector(startRunning) withObject:nil afterDelay:0.2f];
        
        NSLog(@"did start record");
    }
}

- (AVCaptureDevicePosition)cameraPosition
{
    return _videoInput.device.position;
}

- (void)reConfigPreset
{
    [_session beginConfiguration];
    NSArray * presets = @[AVCaptureSessionPreset1920x1080,AVCaptureSessionPreset1280x720,AVCaptureSessionPreset640x480,AVCaptureSessionPresetMedium,AVCaptureSessionPresetLow];
    for(NSString * preset in presets)
    {
        if([_session canSetSessionPreset:preset])
        {
            _session.sessionPreset = preset;
            NSLog(@"当前输入画质:%@",preset);
            break;
        }
    }
    [_session commitConfiguration];
}

#pragma mark KVO
//处理被电话中断事件
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(object == _session)
    {
        if([keyPath isEqualToString:@"interrupted"])
        {
            NSNumber * newNum = change[NSKeyValueChangeNewKey];
            BOOL interrupted = [newNum boolValue];
            if(interrupted )
            {
                [self pauseRecord];
            }
            else if(!interrupted && _shouldCapture)
            {
                if(![_session isRunning])
                {
                    [_session startRunning];
                }
            }
        }
    }
}

#pragma mark AVCaptureFileOutputRecordingDelegate

- (void)processPixelBufferBlue: (CVImageBufferRef)pixelBuffer
{
	CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
	
	int bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
	int bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
	unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    UInt8 tmpByte = 0;
    
	for( int row = 0; row < bufferHeight; row++ ) {
		for( int column = 0; column < bufferWidth / 2; column+= 4 ) {
            for(int k = 0; k < 4; k++)
            {
                tmpByte = pixel[column + k];
                pixel[column + k] = pixel[(bufferWidth - column) + k];
                pixel[(bufferWidth - column + k)] = tmpByte;
            }
            
		}
	}
	
	CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
}

- (CGImageRef) CreateARGBImageWithABGRImage: (CGImageRef) abgrImageRef {
	// the data retrieved from the image ref has 4 bytes per pixel (ABGR).
	CFDataRef abgrData = CGDataProviderCopyData(CGImageGetDataProvider(abgrImageRef));
	UInt8 *pixelData = (UInt8 *) CFDataGetBytePtr(abgrData);
	int length = CFDataGetLength(abgrData);
    
	// abgr to rgba
	// swap the      blue and red components for each pixel...
	UInt8 tmpByte = 0;
	for (int index = 0; index < length; index+= 4) {
		tmpByte = pixelData[index + 1];
		pixelData[index + 1] = pixelData[index + 3];
		pixelData[index + 3] = tmpByte;
	}
	
	// grab the bgra image info
	size_t width = CGImageGetWidth(abgrImageRef);
	size_t height = CGImageGetHeight(abgrImageRef);
	size_t bitsPerComponent = CGImageGetBitsPerComponent(abgrImageRef);
	size_t bitsPerPixel = CGImageGetBitsPerPixel(abgrImageRef);
	size_t bytesPerRow = CGImageGetBytesPerRow(abgrImageRef);
	CGColorSpaceRef colorspace = CGImageGetColorSpace(abgrImageRef);
	CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(abgrImageRef);
	
	// create the argb image
	CFDataRef argbData = CFDataCreate(NULL, pixelData, length);
	CGDataProviderRef provider = CGDataProviderCreateWithCFData(argbData);
	CGImageRef argbImageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow,
                                            colorspace, bitmapInfo, provider, NULL, true, kCGRenderingIntentDefault);
	
	// release what we can
	CFRelease(abgrData);
	CFRelease(argbData);
	CGDataProviderRelease(provider);
	
	// return the pretty new image
	return argbImageRef;
}


- (void)processPixelBuffer: (CMSampleBufferRef)sampleBuffer
{
    
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    int bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
    int bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
    unsigned char * pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    CGContextRef context = CGBitmapContextCreate(pixel,
                                                 bufferWidth,
                                                 bufferHeight,
                                                 8,
                                                 bufferWidth*4,
                                                 colorSpace,
                                                 CGImageGetBitmapInfo(self.waterImage.CGImage));
    UIGraphicsPushContext(context);
    CGContextSaveGState(context);
    //    CGContextTranslateCTM(context, 0.1f, bufferHeight);
    //    CGContextScaleCTM(context, 1.0f, -1.0f);
    //    CGContextDrawImage(context,CGRectMake (100, 0, 140, 140),[UIImage imageNamed:@"watermark_branana.png"].CGImage);
    CGContextDrawImage(context, CGRectMake (bufferHeight - self.waterImage.size.height, 0, (int)self.waterImage.size.height*1.5, (int)self.waterImage.size.width*1.5), self.waterImage.CGImage);
    CGContextRestoreGState(context);
    UIGraphicsPopContext();
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
}
- (void)processPixelBuffer111: (CMSampleBufferRef)sampleBuffer
{
    
    UIImage *imag = [UIImage imageNamed:@"btn_fans_icon.png"];
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    int bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
    int bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
    unsigned char * pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    CGContextRef context = CGBitmapContextCreate(pixel,
                                                 bufferWidth,        /* size_t width */
                                                 bufferHeight,       /* size_t height */
                                                 8,      /* bits per component 32/4 */
                                                 bufferWidth * 4,  /* bytes per row 每行字节数,每一个位图像素的代表是4个字节 */
                                                 CGImageGetColorSpace(imag.CGImage),            /* CGColorSpaceRef */
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
    CGFloat components[] = {1.0, 1.0, 1.0, 1.0};//颜色元素
    CGColorRef color=CGColorCreate(colorSpace,components);//这两行创建颜色
    CGContextSetStrokeColorWithColor(context, color);//使用刚才创建好的颜色为上下文设置颜色
    
    
    CGContextSetLineWidth(context, 2.0);
    CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
    CGRect rectangle = CGRectMake(60,170,200,80);
    CGContextAddRect(context, rectangle);
    CGContextStrokePath(context);
    CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
    CGContextFillRect(context, rectangle);
    
    UIGraphicsPushContext(context);
    
    CGContextTranslateCTM(context, 0, bufferHeight);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, CGRectMake (bufferHeight - self.waterImage.size.height + 100., 0, self.waterImage.size.height *1., self.waterImage.size.width*1.), imag.CGImage);
    //[imag drawInRect:CGRectMake(300, -100, self.waterImage.size.height *2, self.waterImage.size.width*2)];
    UIGraphicsPopContext();
    //CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    //    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    //    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    //    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    //    int bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
    //    int bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
    //    unsigned char * pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    //
    //    CGContextRef context = CGBitmapContextCreate(pixel,
    //                                                 bufferWidth,
    //                                                 bufferHeight,
    //                                                 8,
    //                                                 bufferWidth*4,
    //                                                 colorSpace,
    //                                                  kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    //
    //    CGContextDrawImage(context, CGRectMake (bufferHeight - self.waterImage.size.height  *2 + 160., 0, self.waterImage.size.height  *2, self.waterImage.size.width*2), self.waterImage.CGImage);
    //    CGColorSpaceRelease(colorSpace);
    //    CGContextRelease(context);
    //    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
}
//
//- (void)changePreviewOrientation:(UIInterfaceOrientation)interfaceOrientation{
//    [CATransaction begin];
//    if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
//        //self.imageOrientation = UIImageOrientationRight;
//        self.preview.orientation = AVCaptureVideoOrientationLandscapeRight;
//    }else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft){
//        //self.imageOrientation = UIImageOrientationLeft;
//        self.preview.orientation = AVCaptureVideoOrientationLandscapeLeft;
//    }
//
//    [CATransaction commit];
//}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if(!_shouldRecord)
    {
        return;
    }
    //javachip_beauty_magic(sampleBuffer, 640, 480, "", "", "", "");
    //[self processPixelBuffer:sampleBuffer];
    
    
    if([captureOutput isKindOfClass:[AVCaptureAudioDataOutput class]])
    {
        [_movieWriter  processAudioBuffer:sampleBuffer];
    }
    else if([captureOutput isKindOfClass:[AVCaptureVideoDataOutput class]])
    {
        
        if(self.cameraPosition == AVCaptureDevicePositionFront)
        {
            //[self processPixelBufferBlue:CMSampleBufferGetImageBuffer(sampleBuffer)];
            [_movieWriter  processVideoBuffer:sampleBuffer];
        }
        else
        {
            [_movieWriter  processVideoBuffer:sampleBuffer];
            [_movieWriter  setIsFrontDevice:NO];
        }
    }
    else
    {
        NSLog(@"not Video audio");
    }
}

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // 释放context和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // 用Quartz image创建一个UIImage对象image
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1 orientation:UIImageOrientationLeftMirrored];
    
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    
    //[image rotateImage:UIImageOrientationLeftMirrored];
    
    UIImageWriteToSavedPhotosAlbum(image,nil,nil,nil);
    return (image);
}

- (UIImage*) getGLScreenshot {
    NSInteger myDataLength = 320 * 480 * 4;   // allocate array and read pixels into it.
    GLubyte *buffer = (GLubyte *) malloc(myDataLength);
    glReadPixels(0, 0, 320, 480, GL_RGBA, GL_UNSIGNED_BYTE, buffer);   // gl renders "upside down" so swap top to bottom into new array. // there's gotta be a better way, but this works.
    GLubyte *buffer2 = (GLubyte *) malloc(myDataLength); for(int y = 0; y <480; y++) { for(int x = 0; x <320 * 4; x++) { buffer2[(479 - y) * 320 * 4 + x] = buffer[y * 4 * 320 + x]; } }   // make data provider with data.
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL,
                                                              buffer2, myDataLength, NULL);   // prep the ingredients
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * 320;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB(); CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault; CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;   // make the cgimage
    CGImageRef imageRef = CGImageCreate(320, 480, bitsPerComponent,
                                        bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider,
                                        NULL, NO, renderingIntent);   // then make the uiimage from that
    UIImage *myImage = [UIImage imageWithCGImage:imageRef]; return myImage; }   - (void)saveGLScreenshotToPhotosAlbum { UIImageWriteToSavedPhotosAlbum([self getGLScreenshot], nil,
                                                                                                                                                       nil, nil);
    }

-(void)encodeVideoFrame2:(UIImage*)image time:(CMSampleBufferRef) tm
{
    NSData *data = UIImagePNGRepresentation(image);
    
    CMBlockBufferRef videoBlockBuffer = NULL;
    CMFormatDescriptionRef videoFormat = NULL;
    CMSampleBufferRef videoSampleBuffer = NULL;
    CMItemCount numberOfSampleTimeEntries = 1;
    CMItemCount numberOfSamples = 1;
    
    CMVideoFormatDescriptionCreate(kCFAllocatorDefault, kCMVideoCodecType_MPEG4Video, image.size.width, image.size.height, NULL, &videoFormat);
    OSStatus result;
    result = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault, NULL, data.length, kCFAllocatorDefault, NULL, 0, data.length, kCMBlockBufferAssureMemoryNowFlag, &videoBlockBuffer);
    result = CMBlockBufferReplaceDataBytes(data.bytes, videoBlockBuffer, 0, data.length);
    
    //CMSampleTimingInfo timingInfo = {CMSampleBufferGetDuration(tm),CMSampleBufferGetPresentationTimeStamp(tm),CMSampleBufferGetDecodeTimeStamp(tm)};
    CMSampleTimingInfo timingInfo = { 1001/30000, 12012/30000, 10010/30000 };
    
    size_t sampleSizeArray[1];
    sampleSizeArray[0]=data.length;
    
    result=CMSampleBufferCreate(kCFAllocatorDefault, videoBlockBuffer, TRUE, NULL, NULL, videoFormat, numberOfSamples, numberOfSampleTimeEntries, &timingInfo, 1, sampleSizeArray, &videoSampleBuffer);
    
    
    result = CMSampleBufferMakeDataReady(videoSampleBuffer);
    [_movieWriter  processVideoBuffer:videoSampleBuffer];
    
}


//+ (UIImage *)image:(UIImage *)image rotation:(UIImageOrientation)orientation
//{
//    long double rotate = 0.0;
//    CGRect rect;
//    float translateX = 0;
//    float translateY = 0;
//    float scaleX = 1.0;
//    float scaleY = 1.0;
//
//    switch (orientation) {
//        case UIImageOrientationLeft:
//            rotate = M_PI_2;
//            rect = CGRectMake(0, 0, image.size.height, image.size.width);
//            translateX = 0;
//            translateY = -rect.size.width;
//            scaleY = rect.size.width/rect.size.height;
//            scaleX = rect.size.height/rect.size.width;
//            break;
//        case UIImageOrientationRight:
//            rotate = 3 * M_PI_2;
//            rect = CGRectMake(0, 0, image.size.height, image.size.width);
//            translateX = -rect.size.height;
//            translateY = 0;
//            scaleY = rect.size.width/rect.size.height;
//            scaleX = rect.size.height/rect.size.width;
//            break;
//        case UIImageOrientationDown:
//            rotate = M_PI;
//            rect = CGRectMake(0, 0, image.size.width, image.size.height);
//            translateX = -rect.size.width;
//            translateY = -rect.size.height;
//            break;
//        default:
//            rotate = 0.0;
//            rect = CGRectMake(0, 0, image.size.width, image.size.height);
//            translateX = 0;
//            translateY = 0;
//            break;
//    }
//
//    UIGraphicsBeginImageContext(rect.size);
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    //做CTM变换
//    CGContextTranslateCTM(context, 0.0, rect.size.height);
//    CGContextScaleCTM(context, 1.0, -1.0);
//    CGContextRotateCTM(context, rotate);
//    CGContextTranslateCTM(context, translateX, translateY);
//
//    CGContextScaleCTM(context, scaleX, scaleY);
//    //绘制图片
//    CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), image.CGImage);
//
//    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
//
//    return newPic;
//}

//sigma 参数表示模糊程度, radius 参数表示图像质量.
int gaussBlur(int *data, int width, int height, double sigma, int radius)
{
    double *gaussMatrix, gaussSum = 0.0, _2sigma2 = 2 * sigma * sigma;
    int x, y, xx, yy, xxx, yyy;
    double *pdbl, a, r, g, b, d;
    unsigned char *bbb, *pout, *poutb;
    pout = poutb = (unsigned char *)malloc( width * height * 4);
    if (!pout) return 0;
    gaussMatrix = pdbl = (double *)malloc( (radius * 2 + 1) * (radius * 2 + 1) * sizeof(double));
    if (!gaussMatrix) {
        free(pout);
        return 0;
    }
    for (y = -radius; y <= radius; y++) {
        for (x = -radius; x <= radius; x++) {
            a = exp(-(double)(x * x + y * y) / _2sigma2);
            *pdbl++ = a;
            gaussSum += a;
        }
    }
    pdbl = gaussMatrix;
    for (y = -radius; y <= radius; y++) {
        for (x = -radius; x <= radius; x++) {
            *pdbl++ /= gaussSum;
        }
    }
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            a = r = g = b = 0.0;
            pdbl = gaussMatrix;
            for (yy = -radius; yy <= radius; yy++) {
                yyy = y + yy;
                if (yyy >= 0 && yyy < height) {
                    for (xx = -radius; xx <= radius; xx++) {
                        xxx = x + xx;
                        if (xxx >= 0 && xxx < width) {
                            bbb = (unsigned char *)&data[xxx + yyy * width];
                            d = *pdbl;
                            b += d * bbb[0];
                            g += d * bbb[1];
                            r += d * bbb[2];
                            a += d * bbb[3];
                        }
                        pdbl++;
                    }
                } else {
                    pdbl += (radius * 2 + 1);
                }
            }
            *pout++ = (unsigned char)b;
            *pout++ = (unsigned char)g;
            *pout++ = (unsigned char)r;
            *pout++ = (unsigned char)a;
        }
    }
    memmove(data, poutb, width * height * 4);
    free(gaussMatrix);
    free(poutb);
    return 1;
}
#pragma mark LBMovieWriterDelegate

- (void)movieWriterDidFinishWrite:(FSMovieWriter *)movieWriter
{
    if([self.delegate respondsToSelector:@selector(didFinishExport:withSuccess:)])
    {
        [self.delegate didFinishExport:self withSuccess:YES];
    }
}


#pragma mark LBCameraDelegate

- (void)didLayoutSubviews:(UIView *)view
{
    _layer.frame = view.bounds;
}

@end
