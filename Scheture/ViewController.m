//
//  ViewController.m
//  Scheture
//
//  Created by 张奥 on 2019/7/11.
//  Copyright © 2019年 张奥. All rights reserved.
//

#import "ViewController.h"
#import "SchetureViewController.h"
#import <CoreImage/CoreImage.h>
@interface ViewController (){
    UIImageView    *_imageView;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeCustom];
    button1.frame = CGRectMake(80, 80, 80, 60);
    button1.backgroundColor = [UIColor blueColor];
    [button1 setTitle:@"生成二维码" forState:UIControlStateNormal];
    [button1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button1.titleLabel.font = [UIFont systemFontOfSize:13.f];
    button1.layer.cornerRadius = 8.f;
    button1.layer.masksToBounds = YES;
    [button1 addTarget:self action:@selector(clickButton1:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
    button2.frame = CGRectMake(200, 80, 80, 60);
    button2.backgroundColor = [UIColor blueColor];
    [button2 setTitle:@"二维码扫描" forState:UIControlStateNormal];
    [button2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button2.titleLabel.font = [UIFont systemFontOfSize:13.f];
    button2.layer.cornerRadius = 8.f;
    button2.layer.masksToBounds = YES;
    [button2 addTarget:self action:@selector(clickButton2:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button2];
    
    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(100,CGRectGetMaxY(button1.frame)+100, 200, 200)];
   
    [self.view addSubview:_imageView];
}

-(void)clickButton1:(UIButton*)button{

     _imageView.image = [self createQRCodeWithUrl:@"www.baidu.com"];
}
-(void)clickButton2:(UIButton*)button{
    [self.navigationController pushViewController:[SchetureViewController new] animated:YES];
}

-(UIImage *)createQRCodeWithUrl:(NSString *)url{
    //创建一个二维码滤镜实例
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    //滤镜恢复默认设置
    [filter setDefaults];
    
    //2. 给滤镜添加数据
    NSString *string = url;
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    //使用kvc的方式给filter赋值
    [filter setValue:data forKey:@"inputMessage"];
    //生成二维码
    CIImage *image = [filter outputImage];
    //转成高清格式
    UIImage *qrcode = [self createNonInterpolatedUIImageFormCIImage:image withSize:200];
    //添加logo
    qrcode = [self drawImage:[UIImage imageNamed:@"login_slogan"] inImage:qrcode];
    return qrcode;
}
// 将二维码转成高清的格式
- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size {
    
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}
// 添加logo
- (UIImage *)drawImage:(UIImage *)newImage inImage:(UIImage *)sourceImage {
    CGSize imageSize; //画的背景 大小
    imageSize = [sourceImage size];
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);
    [sourceImage drawAtPoint:CGPointMake(0, 0)];
    //获得 图形上下文
    CGContextRef context=UIGraphicsGetCurrentContext();
    //画 自己想要画的内容(添加的图片)
    CGContextDrawPath(context, kCGPathStroke);
    // 注意logo的尺寸不要太大,否则可能无法识别
    CGRect rect = CGRectMake(imageSize.width / 2 - 25, imageSize.height / 2 - 25, 50, 50);
    //    CGContextAddEllipseInRect(context, rect);
    CGContextClip(context);
    
    [newImage drawInRect:rect];
    
    //返回绘制的新图形
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
