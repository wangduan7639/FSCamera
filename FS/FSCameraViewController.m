//
//  FSCameraViewController.m
//  FS
//
//  Created by wangduan on 14-2-19.
//  Copyright (c) 2014年 wxcp. All rights reserved.
//

#import "FSCameraViewController.h"
#import "UIImage+rotate.h"
#import "FSCamera.h"
#import "FSMovieWriter.h"
#import "UIColor+Addition.h"
#import "CommonCameraTool.h"
#import "FSProgressBar.h"
#import "FSMovieView.h"

@interface FSCameraViewController ()<FSCameraDelegate>
{
    FSCamera        * _camera;
    FSMovieView   * _movieView;
    UIImageView     * _mainView;
    UIImageView     * _bottomView;
    AVCaptureDevice * _device;
    UIButton        * _lightButton;
    UIButton        * _backButton;
    NSDate          * _startDate;
    double            _recordTime;
    BOOL              _isFinished;
    BOOL              _isLoading;
    
    BOOL              _hasWritedData;
    BOOL              _isChangingLens;
    BOOL              _isLighOn;
    FSProgressBar   * _progress;
}
@property(nonatomic,retain) NSTimer * timer;
@property(nonatomic,assign)UIBackgroundTaskIdentifier bgTask;
@end

@implementation FSCameraViewController

@synthesize bgTask;

- (void)clearViews
{
    //    _movieView = nil;
    _mainView = nil;
    _bottomView = nil;
    
    _device = nil;
    _lightButton = nil;
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self clearViews];
    self.timer = nil;
    if(self.bgTask)
    {
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }

}
#pragma mark NSNotification

- (void)willEnterForground
{
    if(self.bgTask)
    {
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }

}

- (void)willResignActive{
    _isLighOn = NO;//闪光灯关掉
    [_lightButton setSelected:_isLighOn];
    [self turnOffLed:YES];
}

- (void)didEnterBackground
{
    if (self.timer.isValid)
        [self.timer invalidate];
    if(self.bgTask)
    {
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }
    self.bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if(!_isFinished)
        {
            [self stopRecord];
            [_camera cancel];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }];

}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _hasWritedData = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForground) name:UIApplicationWillEnterForegroundNotification object:nil];
        
    }
    return self;
}
- (void)viewWillAppear:(BOOL)animated
{
    [UIApplication sharedApplication].statusBarHidden = YES;
//    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
     self.navigationController.navigationBarHidden = YES;
}
//iOS7的方法，隐藏状态条。
- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (void)loadView
{
    [super loadView];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self initialCamera];
    self.view.backgroundColor =  [UIColor colorWithRed:58.0/255 green:58.0/255 blue:58.0/255 alpha:1.0];;
    self.view.userInteractionEnabled = YES;
    [self createTopBar];
    [self createMainView];
    [self createBottomView];
    //AVCaptureDevice代表抽象的硬件设备
    // 找到一个合适的AVCaptureDevice
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (![_device hasTorch]) {//判断是否有闪光灯
        _lightButton.hidden = YES;
    }
    _isLighOn = NO;
    [self performSelector:@selector(start) withObject:nil afterDelay:0.5];
}
- (void)start
{
    //开始扑捉头像
    [_camera startCapture];
}
/////////////////////////////////////////////
- (void)createTopBar
{
    UIView * topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, 50)];
    topBar.userInteractionEnabled = YES;
    topBar.backgroundColor = [UIColor clearColor];
    // 取消录制按钮
    UIButton * leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftButton addTarget:self action:@selector(didClickClose) forControlEvents:UIControlEventTouchUpInside];
    
    [leftButton setFrame:CGRectMake(30, 10, 30, 30)];
    [leftButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [leftButton setTitle:@"返回" forState:UIControlStateNormal];
//    leftButton.center =  CGPointMake(30, topBar.frame.size.height/2);
    [topBar addSubview:leftButton];
    
    UIButton * endButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [endButton addTarget:self action:@selector(didClickEnd:) forControlEvents:UIControlEventTouchUpInside];
    [endButton setFrame:CGRectMake(100, 10, 30, 30)];
    [endButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [endButton setTitle:@"结束" forState:UIControlStateNormal];
    [topBar addSubview:endButton];
    
    //开手电筒按钮
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([_device hasTorch]) {//判断是否有闪光灯
        _lightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _lightButton.frame = CGRectMake(210, 10, 30, 30);
        [_lightButton setTitle:@"打开" forState:UIControlStateNormal];
        [_lightButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [_lightButton setShowsTouchWhenHighlighted:YES];
        
        [_lightButton addTarget:self action:@selector(lightClicked:) forControlEvents:UIControlEventTouchUpInside];
        [topBar addSubview:_lightButton];
        if ( _camera.cameraPosition == AVCaptureDevicePositionFront) {
            _lightButton.hidden = YES;
        }
    }
    
    //切换前后摄像头
    UIButton * rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rightButton.frame = CGRectMake(self.view.frame.size.width - 40, 10, 30, 30);
    [rightButton setShowsTouchWhenHighlighted:YES];
    [rightButton addTarget:self action:@selector(didClickChangeLens:) forControlEvents:UIControlEventTouchUpInside];
    //[rightButton setImage:Image(@"camera_btn_lens_select") forState:UIControlStateHighlighted];
    [rightButton setTitle:@"后置" forState:UIControlStateNormal];
    [rightButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [topBar addSubview:rightButton];

    [self.view addSubview:topBar];
}
//摄像头前后置
- (void)didClickChangeLens:(id)button
{
    if(_camera.cameraPosition == AVCaptureDevicePositionUnspecified || _camera.cameraPosition == AVCaptureDevicePositionBack)
    {
        _lightButton.hidden = YES;
        [self willResignActive];
        _camera.cameraPosition = AVCaptureDevicePositionFront;
//        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DevicePositionFont"];
    }
    else
    {
        _lightButton.hidden = NO;
//        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"DevicePositionFont"];
        _camera.cameraPosition = AVCaptureDevicePositionBack;
    }

}
//闪光灯按钮被按
- (void)lightClicked:(UIButton *)sender{
    _isLighOn = !_isLighOn;
    [_lightButton setSelected:_isLighOn];
    if (_isLighOn) {
        [self turnOnLed:YES];
    }else{
        [self turnOffLed:YES];
    }
}

//打开手电筒
-(void) turnOnLed:(bool)update
{
    [_device lockForConfiguration:nil];
    [_device setTorchMode:AVCaptureTorchModeOn];
    [_device unlockForConfiguration];
}

//关闭手电筒
-(void) turnOffLed:(bool)update
{
    if (![_device hasTorch]) {//判断是否有闪光灯
        return;
    }
    [_device lockForConfiguration:nil];
    [_device setTorchMode: AVCaptureTorchModeOff];
    [_device unlockForConfiguration];
}
//结束录制
- (void)didClickEnd:(id)button
{
    [button setHidden:YES];
   
    [self didFinishCapture];
}
//返回
- (void)didClickClose
{
    [_camera cancel];
    [self dismissViewControllerAnimated:YES completion:nil];
}

////////////////////////////////////////

- (void)createMainView
{
    _mainView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 70, self.view.frame.size.width, 330)];
    _mainView.userInteractionEnabled = YES;
    _mainView.backgroundColor = [UIColor colorWithRed:58.0/255 green:58.0/255 blue:58.0/255 alpha:1.0];
    _progress = [[FSProgressBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 8)];
    UIImage * progress_bg = [UIImage imageNamed:@"camera_progress_bg.png"];
    progress_bg = [progress_bg stretchableImageWithLeftCapWidth:2 topCapHeight:2];
    [_progress setBackgroundImage:progress_bg];
    UIImage * progress_fg = [UIImage imageNamed:@"camera_progress_fg.png"];
    progress_fg = [progress_fg stretchableImageWithLeftCapWidth:2 topCapHeight:2];
    [_progress setProgressImage:progress_fg];
    [_mainView addSubview:_progress];
    
    CALayer * topLine = [CALayer layer];
    topLine.frame = CGRectMake(0, _progress.bottom, _mainView.width, 1);
    topLine.backgroundColor = [UIColor blackColor].CGColor;
    [_mainView.layer addSublayer:topLine];
    
    _movieView = [[FSMovieView alloc] initWithFrame:CGRectMake(0, 9, 320, 320)];
    [_mainView addSubview:_movieView];
    [_mainView addSubview:_camera.cameraView];
    _camera.cameraView.frame = _movieView.frame;
    CALayer * bottomLine = [CALayer layer];
    bottomLine.frame = CGRectMake(0, _movieView.bottom, _mainView.width, 1);
    bottomLine.backgroundColor = [UIColor blackColor].CGColor;
    [_mainView.layer addSublayer:bottomLine];
    [self.view addSubview:_mainView];
}
//底部view
- (void)createBottomView
{
    UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, _mainView.bottom, self.view.width, self.view.height-_mainView.bottom)];
    imageView.backgroundColor =  [UIColor colorWithRed:58.0/255 green:58.0/255 blue:58.0/255 alpha:1.0];;
    imageView.userInteractionEnabled = YES;
    [self.view addSubview:imageView];
    _bottomView = imageView;
}
- (void)initialCamera
{
    //    [LBMovieView pauseAll];
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy_MM_dd_hh_mm_ss"];
    NSDate * now = [NSDate date];
    NSString * dateString = [dateFormatter stringFromDate:now];
    NSString * path = [[CommonCameraTool videoPathWithName:dateString] stringByAppendingString:@".mp4"];
    
    _camera = [[FSCamera alloc] initWithFilePath:path];
    BOOL devicePositionFont = [[NSUserDefaults standardUserDefaults] boolForKey:@"DevicePositionFont"];
    if(devicePositionFont){
        _camera.cameraPosition = AVCaptureDevicePositionFront;
    }
    _camera.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark FSCameraDelegate;
- (void)didFinishExport:(FSCamera *)camera withSuccess:(BOOL)success
{
    [self playCapture];
}

#pragma mark Touch

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self startRecord];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    double endFloat = [[NSDate date] timeIntervalSinceDate:_startDate];
    if(endFloat<.05f)
    {
        [self performSelector:@selector(touchEnd) withObject:nil afterDelay:.05f-endFloat];
    }
    else
    {
        [self touchEnd];
    }
}
- (void)touchEnd
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];
    [self stopRecord];
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    double endFloat = [[NSDate date] timeIntervalSinceDate:_startDate];
    if(endFloat < .05f)
    {
        [self performSelector:@selector(touchEnd) withObject:nil afterDelay:.05f-endFloat];
    }
    else
    {
        [self touchEnd];
    }
    //_shouldContinue = NO;
    //[self stopRecord];
}
- (void)playCapture
{
    if(_isFinished)
    {
        [_mainView bringSubviewToFront:_movieView];
        NSString * path = [_camera videoPath];
        if([CommonCameraTool fileExist:path])
        {
            [_movieView setPlayerURL:[NSURL fileURLWithPath:path]];
            [_movieView play];
        }
        else
        {
            NSLog(@"no player path in playCapture");
        }
    }
}

- (void)stop
{
    [_camera endRecord];
    [_camera endCapture];
}

- (void)step
{
    double time = [_camera writedDuration];
    //double endFloat = [[NSDate date] timeIntervalSinceDate:_startDate];
    //double totalTime = _recordTime + endFloat;
    double totalTime = time;
    NSLog(@"touchTime:%f ,audiotime:%f",totalTime,time);
    _progress.progress =  totalTime/8.0f;
    if (totalTime >= 1.0f && totalTime <= 8.0f)
    {
        
        
    }
    else if(8.0f - totalTime <= 0.0f)
    {
        [self didFinishCapture];
    }

}
- (void)didFinishCapture
{
    [self.navigationItem setTitle:@"回放"];
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
    if (self.timer.isValid)
        [self.timer invalidate];
    _isFinished = YES;
    [self stop];
}

- (void)saveToMovieDirectory
{
    [CommonCameraTool moveToFormalPath:[_camera videoPath]];
    [CommonCameraTool moveToFormalPath:[CommonCameraTool getThumbPathWithPath:_camera.videoPath]];
}

- (void)startRecord
{
    if (_isFinished == YES || _isLoading == YES || ![_camera isSessionRunning])
        return;
    [_camera startRecord];
    _hasWritedData = YES;
    _startDate = [[NSDate date] copy];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1/200.0f target:self selector:@selector(step) userInfo:nil repeats:YES];
    _isLoading = YES;
    
}

- (void)stopRecord
{
    if (_isFinished == YES || _isLoading == NO)
        return;
    _isLoading = NO;
    
    if (self.timer.isValid)
    {
        [self.timer invalidate];
        [_camera pauseRecord];
        float endFloat = [[NSDate date] timeIntervalSinceDate:_startDate];
        _recordTime += endFloat;
    }
}

@end
