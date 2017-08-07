//
//  CollectColorViewController.m
//  InhaleColor
//
//  Created by wukexiu on 17/4/22.
//  Copyright © 2017年 com.xm.InhaleColor. All rights reserved.
//

#import "CollectColorViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import "PublicFun.h"
#import "FinderPickView.h"
#import "LoupeView.h"

@interface CollectColorViewController ()<UIAlertViewDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,FingerPickViewDelegate,UIImagePickerControllerDelegate>{
    __weak IBOutlet UIButton *torchBtn;
    __weak IBOutlet UIButton *flipBtn;
    __weak IBOutlet UIButton *decreaseBtn;
    __weak IBOutlet UIButton *increaseBtn;
    __weak IBOutlet UIButton *closeBtn;
    __weak IBOutlet UIButton *saveBtn;
    __weak IBOutlet UIButton *albumBtn;
    __weak IBOutlet UIView *collectColorVw;
    __weak IBOutlet UIView *toolVw;
    
    BOOL stillImageFlag;
    BOOL videoDataFlag;
    BOOL adjustingFocus;
    
    //UIImage *largeImage;
    //UIImage *smallImage;
    //FinderPickView *finderPv;
}
@property (nonatomic, weak)IBOutlet UIImageView *livePreview;
@property (nonatomic, strong) UIImage *currentPreview;

//硬件设备
@property (nonatomic, strong) AVCaptureDevice *device;
//输入流
@property (nonatomic, strong) AVCaptureDeviceInput *input;
//协调输入输出流的数据
@property (nonatomic, strong) AVCaptureSession *session;
//预览层
//@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
//输出流
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;  //用于捕捉静态图片
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;    //原始视频帧，用于获取实时图像以及视频录制

@property (nonatomic, strong) NSMutableArray *finderPickList;//选取点 finderPickView数组
@property (nonatomic, strong) NSMutableArray *colorViewList;//颜色View数组
@property (nonatomic, strong) NSMutableArray *colorList;//颜色RGB数组

@property (nonatomic, strong) LoupeView *loupeVw;

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, assign) CGFloat accelerometerDataX;
@property (nonatomic, assign) CGFloat accelerometerDataY;
@property (nonatomic, assign) CGFloat accelerometerDataZ;

@property (nonatomic, assign)NSInteger totalNum;
@property (nonatomic, assign)NSInteger finderNum;
@end

@implementation CollectColorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSNumber *num = @"6";
    NSLog(@"-----%ld",[num integerValue]);
    collectColorVw.hidden = YES;
    self.livePreview.hidden = YES;
    self.finderPickList = [NSMutableArray array];
    self.colorViewList = [NSMutableArray array];
    self.colorList = [NSMutableArray array];
    if ([self authCamera]) {
        [self setupCamera];
        UITapGestureRecognizer *tapGesture =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self.livePreview addGestureRecognizer:tapGesture];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self setupMotionManager];
            collectColorVw.hidden = NO;
            self.livePreview.hidden = NO;
        });
    }
    [collectColorVw.layer setZPosition:3];
    [toolVw.layer setZPosition:3];
    [increaseBtn.layer setZPosition:4];
    [decreaseBtn.layer setZPosition:4];
    self.finderNum = 5;
    self.totalNum = 8;
    for (int i=0; i<self.totalNum; i++) {
        FinderPickView *finderPv = [[FinderPickView alloc] init];
        finderPv.center = CGPointMake(kScreen_Width/2.0, (kScreen_Height - 64 *2)/2.0);
        finderPv.isManual = NO;
        finderPv.delegate = self;
        finderPv.backgroundColor = [UIColor clearColor];
        finderPv.hidden = YES;
        finderPv.tag = 100 + i;
        [self.view addSubview:finderPv];
        [self.finderPickList addObject:finderPv];
        
        CGFloat temp_w = kScreen_Width * 1.0 / self.finderNum;
        UIView *colorVw = [[UIView alloc] initWithFrame:CGRectMake(temp_w * i, 0, temp_w, 64)];
        colorVw.backgroundColor = [UIColor clearColor];
        [collectColorVw addSubview:colorVw];
        [self.colorViewList addObject:colorVw];
    }
    
}

-(void)handleTap:(UITapGestureRecognizer *)sender{
    if (self.session) {
        BOOL isManual = NO;
        if ([self.session isRunning]) {
            isManual = YES;
            [self.session stopRunning];
        }else{
            isManual = NO;
            [self.session startRunning];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self ReFreshColor];
            });
        }
        for (FinderPickView *finderPv in self.finderPickList) {
            finderPv.isManual = isManual;
        }
    }
}

- (void)dynamicRefresh{
    if (self.session && ![self.session isRunning]) {
        return;
    }
    static BOOL flag = YES;
    if (flag) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            flag = YES;
        });
        flag = NO;
        [self ReFreshColor];
    }
}

- (void)ReFreshColor{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.colorList removeAllObjects];
        for (int i=0; i < weakSelf.totalNum;i++) {
            FinderPickView *finderPv = weakSelf.finderPickList[i];
            if (finderPv.tag - 100 < self.finderNum) {
                finderPv.hidden = NO;
            }else{
                finderPv.hidden = YES;
            }

            CGPoint tmpPoint =[weakSelf createRandomPoint];
            UIColor *pointColor = [weakSelf.livePreview colorOfPoint:tmpPoint];
            if (i<self.finderNum) {
                [self.colorList addObject:[UIColor toStrByUIColor:pointColor]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                finderPv.backgroundColor = pointColor;

                [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    finderPv.center = tmpPoint;
                } completion:^(BOOL finished) {
                }];
            });
        }
        NSArray *tmpArr = [self.colorList sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
            if (NSOrderedDescending==[obj1 compare:obj2])
            {
                return (NSComparisonResult)NSOrderedAscending;
            }
            if (NSOrderedAscending==[obj1 compare:obj2])
            {
                return (NSComparisonResult)NSOrderedDescending;
            }
            return (NSComparisonResult)NSOrderedSame;
        }];
        for (int j = 0; j < self.finderNum; j++) {
            dispatch_async(dispatch_get_main_queue(), ^{
            UIView *colorVw = weakSelf.colorViewList[j];
            colorVw.backgroundColor = [UIColor getColorStr:tmpArr[j]];
            });
        }
        
    });
}

- (CGPoint)createRandomPoint{
    int randomCX = [PublicFun getRandomNumber:25 to:kScreen_Width - 25];
    int randomCY = [PublicFun getRandomNumber:25 to:kScreen_Height - 64 *2 - 25];
    return CGPointMake(randomCX, randomCY);
}

- (BOOL)authCamera{
    __block BOOL auth = YES;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusNotDetermined:{
            // 许可对话没有出现，发起授权许可
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                //*******************先回主线程
                if (granted) {
                    //第一次用户接受
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //用户拒绝
                        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"温馨提示" message:@"你已阻止APP访问你的相机，请前往设置-隐私-相机中打开" delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
                        alert.delegate = self;
                        [alert show];
                    });
                    auth = NO;
                }
            }];
        }
            break;
        case AVAuthorizationStatusAuthorized:{
            // 已经开启授权，可继续
        }
            break;
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:{
            // 用户明确地拒绝授权，或者相机设备无法访问
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"温馨提示" message:@"你已阻止APP访问你的相机，请前往设置-隐私-相机中打开" delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
            alert.delegate = self;
            [alert show];
            auth = NO;
        }
            break;
        default:
            break;
    }
    {
        NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] || [mediaTypes count] <= 0)
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"温馨提示" message:@"相机不可用" delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
            [alert show];
            auth = NO;
        }
        else
        {
            
        }
    }
    return auth;
}

- (void)setupCamera{
    //[self.view.layer insertSublayer:self.previewLayer atIndex:1];
    if (![self.session isRunning]) {
        [self.session startRunning];
    }
}

- (void)setupMotionManager{
    self.accelerometerDataX = 0;
    self.accelerometerDataY = 0;
    self.accelerometerDataZ = 0;

    self.motionManager = [[CMMotionManager alloc] init];
    [self.motionManager setAccelerometerUpdateInterval:1.0/30.0];
    __weak typeof(self) weakSelf = self;
    if (!self.motionManager.accelerometerAvailable) {
        NSLog(@"The accelerometer is unavailable");
        return;
    }
    __block int i = 0;
    [self.motionManager startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init] withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
        if (error) {
            NSLog(@"CoreMotion Error : %@",error);
            [weakSelf.motionManager stopAccelerometerUpdates];
        }
        if (i == 0) {
            //weakSelf.accelerometerDataX = accelerometerData.acceleration.x;
            //weakSelf.accelerometerDataY = accelerometerData.acceleration.y;
            //weakSelf.accelerometerDataZ = accelerometerData.acceleration.z;
        }
        i++;
        if(fabs(weakSelf.accelerometerDataY - accelerometerData.acceleration.y) > .1 || fabs(weakSelf.accelerometerDataX - accelerometerData.acceleration.x) > .1 || fabs(weakSelf.accelerometerDataZ - accelerometerData.acceleration.z) > .1){
            [weakSelf dynamicRefresh];
            weakSelf.accelerometerDataX = accelerometerData.acceleration.x;
            weakSelf.accelerometerDataY = accelerometerData.acceleration.y;
            weakSelf.accelerometerDataZ = accelerometerData.acceleration.z;
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

//-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
//    if ([keyPath isEqualToString:@"adjustingFocus"]) {
//        NSLog(@"对焦.....");
//    }
//    adjustingFocus = YES;
//}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

-(IBAction)closeBtnClked:(id)sender{
    if (self.session) {
        [self.session stopRunning];
    }
    [self.motionManager stopAccelerometerUpdates];
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
//AVCaptureVideoDataOutput获取实时图像，这个代理方法的回调频率很快，几乎与手机屏幕的刷新频率一样快
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    //设置图像方向，否则largeImage取出来是反的
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    self.currentPreview = [self imageFromSampleBuffer:sampleBuffer];
    [self.livePreview setImage:self.currentPreview];
}

//CMSampleBufferRef转NSImage
-(UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer{
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
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    // 释放context和颜色空间
    CGContextRelease(context); CGColorSpaceRelease(colorSpace);
    // 用Quartz image创建一个UIImage对象image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    return (image);
}

#pragma mark - 手电筒
-(IBAction)openTorch:(UIButton*)button{
    button.selected = !button.selected;
    [self turnTorchOn:button.selected];
}

- (void)turnTorchOn:(BOOL)on{
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        if ([self.device hasTorch] && [self.device hasFlash]){
            [self.device lockForConfiguration:nil];
            if (on) {
                [self.device setTorchMode:AVCaptureTorchModeOn];
                
            } else {
                [self.device setTorchMode:AVCaptureTorchModeOff];
            }
            [self.device unlockForConfiguration];
        }
    }
}

#pragma mark - 切换前后摄像头
- (IBAction)switchFlipCamera:(UIButton *)button{
    NSUInteger cameraCount = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
    if (cameraCount > 1) {
        AVCaptureDevice *newCamera = nil;
        AVCaptureDeviceInput *newInput = nil;
        AVCaptureDevicePosition position = [[self.input device] position];
        if (position == AVCaptureDevicePositionFront){
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
        }else {
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
        }
        newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
        if (newInput != nil) {
            [self.session beginConfiguration];
            [self.session removeInput:self.input];
            if ([self.session canAddInput:newInput]) {
                [self.session addInput:newInput];
                self.input = newInput;
            }else {
                [self.session addInput:self.input];
            }
            [self.session commitConfiguration];
        }
        CABasicAnimation *ani = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        [ani setFromValue:@(0)];
        [ani setToValue:@(M_PI)];
        [ani setDuration:0.5];
        [ani setRepeatCount:0];
        ani.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [flipBtn.layer addAnimation:ani forKey:@"rotaion_180"];
        
    }
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position ) return device;
    return nil;
}


#pragma mark - getter
-(AVCaptureDevice *)device{
    if (_device == nil) {
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([_device lockForConfiguration:nil]) {
            //自动闪光灯
            if ([_device isFlashModeSupported:AVCaptureFlashModeAuto]) {
                [_device setFlashMode:AVCaptureFlashModeAuto];
            }
            //自动白平衡
            if ([_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
                [_device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
            }
            //自动对焦
            if ([_device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                [_device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            }
            //自动曝光
            if ([_device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                [_device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
            [_device unlockForConfiguration];
        }
    }
    return _device;
}

-(AVCaptureDeviceInput *)input{
    if (_input == nil) {
        _input = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:nil];
    }
    return _input;
}

-(AVCaptureStillImageOutput *)stillImageOutput{
    if (_stillImageOutput == nil) {
        _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    }
    return _stillImageOutput;
}

-(AVCaptureVideoDataOutput *)videoDataOutput{
    if (_videoDataOutput == nil) {
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
        //设置像素格式，否则CMSampleBufferRef转换NSImage的时候CGContextRef初始化会出问题
        [_videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    }
    return _videoDataOutput;
}

-(AVCaptureSession *)session{
    if (_session == nil) {
        _session = [[AVCaptureSession alloc] init];
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
        if ([_session canAddInput:self.input]) {
            [_session addInput:self.input];
        }
        if ([_session canAddOutput:self.stillImageOutput]) {
            [_session addOutput:self.stillImageOutput];
        }
        if ([_session canAddOutput:self.videoDataOutput]) {
            [_session addOutput:self.videoDataOutput];
        }
    }
    return _session;
}

//-(AVCaptureVideoPreviewLayer *)previewLayer{
//    if (_previewLayer == nil) {
//        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session]; //[AVCaptureVideoPreviewLayer layerWithSession:self.session];
//        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//        _previewLayer.frame = self.view.layer.bounds;
//        //_previewLayer.frame = kScreen_Bounds;
//    }
//    return _previewLayer;
//}

#pragma mark - UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    [self performSelector:@selector(closeBtnClked:) withObject:nil afterDelay:1.0];
}

#pragma mark - FingerPickViewDelegate
-(void)fingerPickViewBegan:(CGPoint)point{
    if (!self.loupeVw) {
        self.loupeVw = [[LoupeView alloc] init];
    }
    if (!self.loupeVw.targetVw) {
        self.loupeVw.targetVw = self.livePreview;
    }
    self.loupeVw.touchPoint = point;
    [self.view addSubview:self.loupeVw];
    [[self.loupeVw superview] bringSubviewToFront:self.loupeVw];
    [self.loupeVw setNeedsDisplay];
//    //创建运转动画
//    CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
//    pathAnimation.calculationMode = kCAAnimationPaced;
//    pathAnimation.fillMode = kCAFillModeForwards;
//    pathAnimation.removedOnCompletion = NO;
//    pathAnimation.duration = 6.0;
//    pathAnimation.repeatCount = 1000;
//    //设置运转动画的路径
//    CGMutablePathRef curvedPath = CGPathCreateMutable();
//    CGPathAddArc(curvedPath, NULL, point.x, point.y, 100, M_PI / 2, (M_PI / 2 + 2 * M_PI), 0);
//    pathAnimation.path = curvedPath;
//    CGPathRelease(curvedPath);
    //[self.loupeVw.layer addAnimation:pathAnimation forKey:@"moveCircle"];
    
}
-(void)fingerPickViewChanged:(FinderPickView *)finderPv withCenter:(CGPoint)point{
    UIColor *tempColor = [self.livePreview colorOfPoint:point];
    finderPv.backgroundColor = tempColor;
    
    self.loupeVw.touchPoint = point;
    [self.loupeVw setNeedsDisplay];
    
    if (self.colorList.count > finderPv.tag - 100) {
        [self.colorList setObject:[UIColor toStrByUIColor:tempColor] atIndexedSubscript:(finderPv.tag - 100)];
        NSArray *tmpArr = [self.colorList sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            
            if (NSOrderedDescending==[obj1 compare:obj2])
            {
                return (NSComparisonResult)NSOrderedAscending;
            }
            if (NSOrderedAscending==[obj1 compare:obj2])
            {
                return (NSComparisonResult)NSOrderedDescending;
            }
            return (NSComparisonResult)NSOrderedSame;
        }];
        __weak typeof(self) weakSelf = self;
        for (int j = 0; j < self.finderNum; j++) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIView *colorVw = weakSelf.colorViewList[j];
                colorVw.backgroundColor = [UIColor getColorStr:tmpArr[j]];
            });
        }
    }
}

-(void)fingerPickViewEnded{
    [self.loupeVw removeFromSuperview];
}


-(IBAction)saveBtnOnClick:(UIButton *)button{
    
}

-(IBAction)albumBtnOnClick:(UIButton *)button{
    ALAuthorizationStatus authorizationStatus = [ALAssetsLibrary authorizationStatus];
    if (authorizationStatus == ALAuthorizationStatusRestricted || authorizationStatus == ALAuthorizationStatusDenied) {
        NSDictionary *mainInfoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *appName = [mainInfoDictionary objectForKey:@"CFBundleDisplayName"];
        NSString *tipTextWhenNoPhotosAuthorization = [NSString stringWithFormat:@"请在设备的\"设置-隐私-照片\"选项中，允许%@访问你的手机相册", appName];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"没有授权访问相册" message:tipTextWhenNoPhotosAuthorization delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alert show];
    }else{
        if ([self.session isRunning]) {
            [self.session stopRunning];
        }
        UIImagePickerController *pickerVC = [[UIImagePickerController alloc] init];
        [pickerVC setSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
        pickerVC.delegate = self;
        [self presentViewController:pickerVC animated:YES completion:nil];
    }
}
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    if ([self.session isRunning]) {
        [self.session stopRunning];
    }
    self.livePreview.image = [info objectForKey:UIImagePickerControllerOriginalImage];
    __weak typeof(self) weakSelf = self;
    [picker dismissViewControllerAnimated:YES completion:^{
        [weakSelf ReFreshColor];
        for (FinderPickView *finderPv in weakSelf.finderPickList) {
            finderPv.isManual = YES;
        }
    }];
}
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    if (![self.session isRunning]) {
        [self.session startRunning];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}


-(IBAction)decreaseBtnOnClick:(UIButton *)button{
    if (self.finderNum == 3) {
        decreaseBtn.alpha = 0.6;
    }else if (self.finderNum<=2) {
        self.finderNum = 2;
        return;
    }
    if (self.finderNum == self.totalNum) {
        increaseBtn.alpha = 1.0;
    }
    self.finderNum--;
    [self ReFreshColor];
    CGFloat temp_w = kScreen_Width * 1.0 / self.finderNum;
    for (int i=0; i< self.totalNum ; i++) {
        UIView *colorVw = self.colorViewList[i];
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.4 animations:^{
                colorVw.width = temp_w;
                colorVw.x = i*temp_w;
            }];
        });
    }
}

-(IBAction)increaseBtnOnClick:(UIButton *)button{
    if (self.finderNum == self.totalNum -1) {
        increaseBtn.alpha = 0.6;
    }else if (self.finderNum >= self.totalNum) {
        self.finderNum = self.totalNum;
        return;
    }
    if (self.finderNum == 2) {
        decreaseBtn.alpha = 1.0;
    }
    self.finderNum++;
    [self ReFreshColor];
    CGFloat temp_w = kScreen_Width * 1.0 / self.finderNum;
    for (int i=0; i< self.totalNum ; i++) {
        UIView *colorVw = self.colorViewList[i];
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.4 animations:^{
                colorVw.width = temp_w;
                colorVw.x = i*temp_w;
            }];
        });
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
