//
//  SchetureViewController.m
//  Scheture
//
//  Created by 张奥 on 2019/7/11.
//  Copyright © 2019年 张奥. All rights reserved.
//

#import "SchetureViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#define SCREEN_Width [UIScreen mainScreen].bounds.size.width
#define SCREEN_Height [UIScreen mainScreen].bounds.size.height
@interface SchetureViewController ()<AVCaptureMetadataOutputObjectsDelegate , AVCaptureVideoDataOutputSampleBufferDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property (nonatomic,strong)UIImageView *activeImage;
@property (nonatomic, strong) UIImagePickerController *photoLibraryVC;
@end

@implementation SchetureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self checkCaptureStatus];
    
    //扫描条上下滚动
    [self performSelectorOnMainThread:@selector(timerFired) withObject:nil waitUntilDone:NO];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"相机" style:UIBarButtonItemStyleDone target:self action:@selector(getPhoto)];
    self.navigationItem.rightBarButtonItem = item;
    [self initUI];
    [self initSession];

}

-(void)initUI{
    CGFloat imageX = SCREEN_Width*0.15;
    CGFloat imageY = SCREEN_Width*0.15 + 64;
    //扫描框的四个角
    UIImageView *scanImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"saoyisao"]];
    scanImage.frame = CGRectMake(imageX, imageY, SCREEN_Width*0.7, SCREEN_Width*0.7);
    [self.view addSubview:scanImage];
    //扫描条
    UIImageView *activeImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"saoyisao-3"]];
    self.activeImage = activeImage;
    activeImage.frame = CGRectMake(imageX, imageY, SCREEN_Width*0.7, 4.f);
    [self.view addSubview:activeImage];
    
    //添加半透明蒙版
    UIView *maskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_Width, SCREEN_Height)];
    maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [self.view addSubview:maskView];
    //扣出扫描的一块
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRect:self.view.bounds];
    [maskPath appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(imageX, imageY, SCREEN_Width*0.7, SCREEN_Width*0.7)] bezierPathByReversingPath]];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.path = maskPath.CGPath;
    maskView.layer.mask = maskLayer;
}

-(void)initSession{
    //获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //创建摄像设备输入流
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    //创建云数据输出流
    AVCaptureMetadataOutput *metaOutPut = [[AVCaptureMetadataOutput alloc] init];
    [metaOutPut setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    //创建会话对象
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    session.sessionPreset = AVCaptureSessionPresetHigh;
    [session addOutput:metaOutPut];
    //创建摄像数据输入流并将其添加到会话对象上  -->用于识别光线强弱
    AVCaptureVideoDataOutput *videoDataOutPut = [[AVCaptureVideoDataOutput alloc] init];
    [videoDataOutPut setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    [session addOutput:videoDataOutPut];
    //添加摄像设备输入流会话对象
    [session addInput:deviceInput];
    //设备数据输出类型(如下设置为条形码和二维码兼容). 需要将数据输出添加到会话后才能制定元数据类型,否则报错
    metaOutPut.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeCode128Code];
    //实例化预览图层,用于显示会话对象
    AVCaptureVideoPreviewLayer *videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    videoPreviewLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:videoPreviewLayer atIndex:0];
    //启动会话
    [session startRunning];
    //设置扫描作用域范围
    CGRect intertRect = [videoPreviewLayer metadataOutputRectOfInterestForRect:CGRectMake(SCREEN_Width*0.15, SCREEN_Width*0.15+64, SCREEN_Width*0.7, SCREEN_Width*0.7)];
    metaOutPut.rectOfInterest = intertRect;
    CGRect layerRect = [videoPreviewLayer rectForMetadataOutputRectOfInterest:intertRect];
    NSLog(@"%@,  %@",NSStringFromCGRect(intertRect),NSStringFromCGRect(layerRect));
}

-(void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects != nil && metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *obj = metadataObjects[0];
        NSLog(@"%@",[obj stringValue]);
        [self playBeep];
    }else{
        NSLog(@"暂未识别出扫描的二维码");
    }
}
-(void)getPhoto{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusAuthorized) {//允许访问相册，直接进入相册选择器
            [self presentViewController:self.photoLibraryVC animated:YES completion:nil];
        }else if (status == PHAuthorizationStatusNotDetermined) {   //未确定是否允许，请求用户授权
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
                    [self presentViewController:self.photoLibraryVC animated:YES completion:nil];
                }
            }];
        }else {
            NSString *appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleDisplayName"];
            if (!appName) appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleName"];
            NSString *string = [NSString stringWithFormat:@"请在iPhone的设置中允许%@访问相册",appName];
            UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"相册访问受限" message:string preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
            [alertVC addAction:actionCancel];
            UIAlertAction *actionSet = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{UIApplicationOpenURLOptionUniversalLinksOnly : @NO} completionHandler:nil];
            }];
            [alertVC addAction:actionSet];
            [self presentViewController:alertVC animated:YES completion:nil];
        }
    }else {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"访问失败" message:@"当前设备不能访问相册或相机" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
        [alertVC addAction:actionCancel];
        [self presentViewController:alertVC animated:YES completion:nil];
    }
}
- (void)checkCaptureStatus {
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authorizationStatus == AVAuthorizationStatusAuthorized) {
    }else if (authorizationStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
            }else{
                [self.navigationController popViewControllerAnimated:YES];
            }
        }];
    }else {
        NSString *appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleDisplayName"];
        if (!appName) appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleName"];
        NSString *string = [NSString stringWithFormat:@"请在iPhone的设置中允许%@访问相机",appName];
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"相机访问受限" message:string preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [alertVC addAction:actionCancel];
        UIAlertAction *actionSet = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{UIApplicationOpenURLOptionUniversalLinksOnly : @NO} completionHandler:nil];
        }];
        [alertVC addAction:actionSet];
        [self presentViewController:alertVC animated:YES completion:nil];
    }
}

-(void)timerFired{
    [self.activeImage.layer addAnimation:[self moveY:2.5 Y:[NSNumber numberWithFloat:(SCREEN_Width*0.7-4)]] forKey:@"animation"];
}
//扫描线动画
-(CABasicAnimation *)moveY:(float)time Y:(NSNumber*)y{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    animation.toValue = y;
    animation.duration = time;
    animation.removedOnCompletion = YES;
    animation.repeatCount = MAXFLOAT;
    animation.fillMode = kCAFillModeForwards;
    return animation;
}
// 音效震动
- (void)playBeep{
    NSString *audioFile = [[NSBundle mainBundle] pathForResource:@"di"ofType:@"mp3"];
    NSURL *fileUrl = [NSURL fileURLWithPath:audioFile];
    
    SystemSoundID soundID;
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)fileUrl, &soundID);
    
    AudioServicesPlaySystemSound(soundID);
    
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}
- (UIImagePickerController *)photoLibraryVC {
    if (_photoLibraryVC == nil) {
        _photoLibraryVC = [[UIImagePickerController alloc] init];
        _photoLibraryVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        _photoLibraryVC.delegate = self;
        _photoLibraryVC.allowsEditing = YES;
    }
    return _photoLibraryVC;
}
#pragma mark - image picker view controller delegate

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:@"public.image"]) {
        UIImage *pickImage = [info objectForKey:UIImagePickerControllerEditedImage];
        
        NSData *imageData = UIImagePNGRepresentation(pickImage);
        CIImage *ciImage = [CIImage imageWithData:imageData];
        
        //创建探测器
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyLow}];
        NSArray *features = [detector featuresInImage:ciImage];
        
        NSString *content;
        //取出探测到的数据
        //        for (CIQRCodeFeature *result in features) {
        //            content = result.messageString;
        //        }
        if (features.count > 0) {
            CIQRCodeFeature *feature = features[0];
            content = feature.messageString;
        }
        
        __weak typeof(self) weakSelf = self;
        //选中图片后先返回扫描页面，然后跳转到新页面进行展示
        [picker dismissViewControllerAnimated:YES completion:^{
            if (content) {
                NSLog(@"%@",content);
                //震动
                [weakSelf playBeep];
            }else{
                UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"扫描提示" message:@"未识别图中的二维码" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
                [alertVC addAction:actionCancel];
                [weakSelf presentViewController:alertVC animated:YES completion:nil];
            }
        }];
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
