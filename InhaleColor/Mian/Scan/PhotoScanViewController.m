//
//  PhotoScanViewController.m
//  InhaleColor
//
//  Created by wukexiu on 17/4/21.
//  Copyright © 2017年 com.xm.InhaleColor. All rights reserved.
//

#import "PhotoScanViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface PhotoScanViewController ()<AVCaptureMetadataOutputObjectsDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,UIAlertViewDelegate>

//硬件设备
@property (nonatomic, strong) AVCaptureDevice *device;
//输入流
@property (nonatomic, strong) AVCaptureDeviceInput *input;
//协调输入输出流的数据
@property (nonatomic, strong) AVCaptureSession *session;
//预览层
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

//输出流
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;  //用于捕捉静态图片
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;    //原始视频帧，用于获取实时图像以及视频录制
@property (nonatomic, strong) AVCaptureMetadataOutput *metadataOutput;      //用于二维码识别以及人脸识别

//闪光灯
@property (nonatomic, strong) UIButton *torchButton;
//切换前后摄像头
@property (nonatomic, strong) UIButton *cameraButton;
//拍照
@property (nonatomic, strong) UIButton *takePhotoButton;

@end

@implementation PhotoScanViewController{
    BOOL stillImageFlag;
    BOOL videoDataFlag;
    BOOL metadataOutputFlag;
    UIImage *largeImage;
    UIImage *smallImage;
    
    UIImageView *ivSao;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
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
                    return;
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
            return ;
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
            return;
        }
        else
        {
            
        }
    }
    [self setupCamera];
    
    // 添加扫描图片
    {
        ivSao = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 290, 290)];
        ivSao.image = [UIImage imageNamed:@"sao"];
        [self.vwCenter addSubview:ivSao];
        self.vwCenter.clipsToBounds = YES;
        [self startAnimation];
    }
    
}

- (void) setupCamera{
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    [self.view addSubview:self.torchButton];
    [self.view addSubview:self.cameraButton];
    [self setupMenuButton];
    [self.view addSubview:self.takePhotoButton];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    AVCaptureDevice *camDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    int flags = NSKeyValueObservingOptionNew;
    [camDevice addObserver:self forKeyPath:@"adjustingFocus" options:flags context:nil];
    [_session startRunning];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"adjustingFocus"]) {
        NSLog(@"对焦.....");
    }
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    AVCaptureDevice *camDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [camDevice removeObserver:self forKeyPath:@"adjustingFocus"];
}

-(IBAction)backBtnClked:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 拍照
- (void)takePhoto{
    if (metadataOutputFlag) {
        return;
    }
    if (stillImageFlag) {
        [self screenshot];
    }else if (videoDataFlag){
        [self saveImageToPhotoAlbum:largeImage];
        [self saveImageToPhotoAlbum:smallImage];
    }
    [self.session stopRunning];
}

//AVCaptureStillImageOutput截取静态图片，会有快门声
-(void)screenshot{
    AVCaptureConnection * videoConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (!videoConnection) {
        NSLog(@"take photo failed!");
        return;
    }
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer == NULL) {
            return;
        }
        NSData * imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [UIImage imageWithData:imageData];
        [self saveImageToPhotoAlbum:image];
    }];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
//AVCaptureVideoDataOutput获取实时图像，这个代理方法的回调频率很快，几乎与手机屏幕的刷新频率一样快
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if (!videoDataFlag) {
        return;
    }
    
    static BOOL flag = YES;
    if (flag) {
        flag = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            flag = YES;
        });
        //设置图像方向，否则largeImage取出来是反的
        [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        largeImage = [self imageFromSampleBuffer:sampleBuffer];
        smallImage = [largeImage scaledToSize:CGSizeMake(512.0f, 512.0f)];
        
        NSLog(@"频率---------");
    }
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

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (!metadataOutputFlag) {
        return;
    }
    if (metadataObjects.count>0) {
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex :0];
#ifndef FACE
        [self.session stopRunning];
        NSLog(@"qrcode is : %@",metadataObject.stringValue);
#else
        AVMetadataObject *faceData = [self.previewLayer transformedMetadataObjectForMetadataObject:metadataObject];
        NSLog(@"faceData is : %@",faceData);
#endif
    }
}

#pragma mark - 保存至相册
- (void)saveImageToPhotoAlbum:(UIImage*)savedImage{
    UIImageWriteToSavedPhotosAlbum(savedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}

//指定回调方法
- (void)image: (UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (image == nil) {
        return;
    }
    NSString *msg = @"保存图片成功";
    if(error != NULL){
        msg = @"保存图片失败" ;
    }
    NSLog(@"%@",msg);
}

#pragma mark - 手电筒
-(void)openTorch:(UIButton*)button{
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
- (void)switchCamera{
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
    }
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position ) return device;
    return nil;
}

#pragma mark - 菜单按钮
-(void)scanMenuChange:(UIButton *)aButton{
    if (!self.session.isRunning) {
        [self.session startRunning];
    }
    stillImageFlag = NO;
    videoDataFlag = NO;
    metadataOutputFlag = NO;
    switch (aButton.tag) {
        case 10:
        {
            stillImageFlag = YES;
        }
            break;
        case 11:
        {
            videoDataFlag = YES;
            largeImage = nil;
            smallImage = nil;
        }
            break;
        case 12:
        {
            metadataOutputFlag = YES;
        }
            break;
            
        default:
            break;
    }
    for (int i = 10; i < 13; i ++) {
        UIButton *button = (UIButton *)[self.view viewWithTag:i];
        button.selected = NO;
    }
    aButton.selected = YES;
}

-(void)setupMenuButton{
    NSArray *titles = @[@"静态图像",@"实时图像",@"二维码"];
    CGFloat width = [UIScreen mainScreen].bounds.size.width / titles.count;
    for (int i = 0; i < 3; i ++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(i * width, [UIScreen mainScreen].bounds.size.height - 160.0f, width, 49.0f);
        button.tag = 10 + i;
        [button addTarget:self action:@selector(scanMenuChange:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithRed:36./255. green:185./255. blue:243./255. alpha:1.] forState:UIControlStateSelected];
        [button setTitle:titles[i] forState:UIControlStateNormal];
        [button setTitle:titles[i] forState:UIControlStateSelected];
        [self.view addSubview:button];
        if (i == 0) {
            [self scanMenuChange:button];
        }
    }
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

-(AVCaptureMetadataOutput *)metadataOutput{
    if (_metadataOutput == nil) {
        _metadataOutput = [[AVCaptureMetadataOutput alloc]init];
        [_metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        //设置扫描区域
        _metadataOutput.rectOfInterest = self.view.bounds;
    }
    return _metadataOutput;
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
        if ([_session canAddOutput:self.metadataOutput]) {
            [_session addOutput:self.metadataOutput];
#ifndef FACE
            //设置扫码格式
            self.metadataOutput.metadataObjectTypes = @[
                                                        AVMetadataObjectTypeQRCode,
                                                        AVMetadataObjectTypeEAN13Code,
                                                        AVMetadataObjectTypeEAN8Code,
                                                        AVMetadataObjectTypeCode128Code
                                                        ];
#else
            self.metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
#endif
        }
    }
    return _session;
}

-(AVCaptureVideoPreviewLayer *)previewLayer{
    if (_previewLayer == nil) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session]; //[AVCaptureVideoPreviewLayer layerWithSession:self.session];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _previewLayer.frame = self.view.layer.bounds;
        //_previewLayer.frame = kScreen_Bounds;
    }
    return _previewLayer;
}

-(UIButton *)torchButton{
    if (_torchButton == nil) {
        _torchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _torchButton.frame = CGRectMake(0.0f, 32.0f, 100.0f, 64.0f);
        [_torchButton setImage:[UIImage imageNamed:@"flash_icon"] forState:UIControlStateNormal];
        [_torchButton setImage:[UIImage imageNamed:@"flash_icon1"] forState:UIControlStateSelected];
        [_torchButton addTarget:self action:@selector(openTorch:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _torchButton;
}

-(UIButton *)cameraButton{
    if (_cameraButton == nil) {
        _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cameraButton.frame = CGRectMake(kScreen_Width - 100.0f, 32.0f, 100.0f, 64.0f);
        [_cameraButton setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
        [_cameraButton addTarget:self action:@selector(switchCamera) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraButton;
}

-(UIButton *)takePhotoButton{
    if (_takePhotoButton == nil) {
        _takePhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _takePhotoButton.frame = CGRectMake(15.0f, kScreen_Height - 91.0f, kScreen_Width - 30.0f, 42.0f);
        _takePhotoButton.backgroundColor = [UIColor redColor];
        [_takePhotoButton setTitle:@"拍照" forState:UIControlStateNormal];
        [_takePhotoButton addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
        _takePhotoButton.layer.cornerRadius = 5.0f;
        [_takePhotoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    return _takePhotoButton;
}


-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    [self performSelector:@selector(backBtnClked:) withObject:nil afterDelay:1.0];
}

-(void)startAnimation{
    ivSao.frame = CGRectMake(0, -290, 290, 290);
    ivSao.alpha = 0.1;
    [UIView animateWithDuration:1.2 delay:0.1 options:UIViewAnimationOptionCurveEaseIn animations:^{
        ivSao.frame = CGRectMake(0, -15, 290, 290);
        ivSao.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            ivSao.frame = CGRectMake(0, 0, 290, 290);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                ivSao.alpha = 0;
            } completion:^(BOOL finished) {
                [self startAnimation];
            }];
        }];
    }];
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
