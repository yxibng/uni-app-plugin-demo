//
//  ObjectDetectorComponent.m
//  ObjectDetector
//
//  Created by yxibng on 2025/4/7.
//

#import "ObjectDetectorComponent.h"
#import "DCUniConvert.h"
#import <ObjectDetector/ObjectDetector-Swift.h>

static NSString *const kEventNameOnCameraOpen = @"onCameraOpen";
static NSString *const kEventNameOnCameraClose = @"onCameraClose";
static NSString *const kEventNameOnCaptured = @"onCaptured";
static NSString *const kEventNameOnDetectionCapture = @"onDetectionCapture";
static NSString *const kEventNameOnError = @"onError";


#pragma mark -

@interface UIImage (ToBase64String)
- (NSString * _Nullable)base64StringWithQuality:(float)quality;
@end

@implementation UIImage(ToBase64String)

- (NSString * _Nullable)base64StringWithQuality:(float)quality {
    NSData *data = UIImageJPEGRepresentation(self, quality);
    NSString *base64String = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    base64String = [base64String stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return base64String;
}
@end

#pragma mark -

@interface DetectedObjectsPreview : UIView
@end

@implementation DetectedObjectsPreview
@end

#pragma mark -

@interface ObjectDetectorComponent () <VisionDetectorDelegate, CameraManagerDelegate>
@property (nonatomic, strong) VisionDetector *detector;
@property (nonatomic, strong) CameraManager *cameraManager;
/*
 持续检测到目标，一秒回调一次
 */
@property (nonatomic, assign) double lastCallbackTime;
//是否立即拍照
@property (nonatomic, assign) BOOL shouldTakeNow;
@end


@implementation ObjectDetectorComponent


- (void)dealloc {
    [self.cameraManager stopSession];
}

- (VisionDetector *)detector {
    if (!_detector) {
        _detector = [[VisionDetector alloc] init];
        _detector.delegate = self;
    }
    return _detector;
}

- (CameraManager *)cameraManager {
    if (!_cameraManager) {
        _cameraManager = [[CameraManager alloc] init];
    }
    return _cameraManager;
}

-(void)onCreateComponentWithRef:(NSString *)ref type:(NSString *)type styles:(NSDictionary *)styles attributes:(NSDictionary *)attributes events:(NSArray *)events uniInstance:(DCUniSDKInstance *)uniInstance
{

}

- (UIView *)loadView {
    return  [DetectedObjectsPreview new];
}

- (void)viewDidLoad {
    self.cameraManager.previewView = self.view;
    self.cameraManager.delegate = self;
    
}

/// 前端更新属性回调方法
/// @param attributes 更新的属性
- (void)updateAttributes:(NSDictionary *)attributes {
    // 解析属性
}

/// 前端注册的事件会调用此方法
/// @param eventName 事件名称
- (void)addEvent:(NSString *)eventName {
    
}

/// 对应的移除事件回调方法
/// @param eventName 事件名称
- (void)removeEvent:(NSString *)eventName {
    
}

#pragma mark -  通过 WX_EXPORT_METHOD 将方法暴露给前端


//0 back , 1 front
UNI_EXPORT_METHOD(@selector(openCamera:))
- (void)openCamera:(NSString*) facing {
    if (facing.intValue == 1) {
        [self.cameraManager switchCameraWithIsFront:YES];
    } else {
        [self.cameraManager switchCameraWithIsFront:NO];
    }
    [self.cameraManager startSession];
}

UNI_EXPORT_METHOD(@selector(closeCamera))
- (void)closeCamera {
    [self.cameraManager stopSession];
}

//0 off, 1 open
UNI_EXPORT_METHOD(@selector(switchFlash:))
- (void )switchFlash:(NSString *)on {
    
    if (on.intValue == 1) {
        [self.cameraManager switchFlashWithOpen:YES];
    } else {
        [self.cameraManager switchFlashWithOpen:NO];
    }
}
UNI_EXPORT_METHOD(@selector(takePicture))
- (void)takePicture {
    self.shouldTakeNow = YES;
}

UNI_EXPORT_METHOD(@selector(setZoomLevel:))
- (void)setZoomLevel:(NSString*)level {
    [self.cameraManager setZoomLevel:level.floatValue];
}

#pragma mark -  给前端回调的事件

- (void)onCameraOpen {
    [self fireEvent:kEventNameOnCameraOpen
             params:nil
         domChanges:nil];
}

- (void)onCameraClose {
    [self fireEvent:kEventNameOnCameraClose
             params:nil
         domChanges:nil];
}

- (void)onDetectionCapture:(NSString*) base64_full base64_vehicle:(NSString *)base64_vehicle {
    [self fireEvent:kEventNameOnDetectionCapture
             params:@{@"detail":@{@"base64_full":base64_full,@"base64_vehicle":base64_vehicle}}
         domChanges:nil];
}


-(void)onCaptured:(NSString *) base64_full {
    [self fireEvent:kEventNameOnCaptured
             params:@{@"detail":@{@"base64_full":base64_full}}
         domChanges:nil];
}

- (void)onError:(NSString *)err {
    [self fireEvent:kEventNameOnError
             params:@{@"detail":@{@"err":err}}
         domChanges:nil];
}


#pragma mark - VisionDetectorDelegate

- (void)onErrorWithDetector:(VisionDetector * _Nonnull)detector message:(NSString * _Nonnull)message {
    [self onError:message];
}

- (void)onSuccessWithDetector:(VisionDetector * _Nonnull)detector annotedImage:(UIImage * _Nonnull)annotedImage objectImages:(NSArray<UIImage *> * _Nonnull)objectImages {
    double currentTime = [[NSDate date] timeIntervalSince1970] * 1000;
    if (currentTime - self.lastCallbackTime > 1000 && objectImages.count > 0) {
        NSString *annotedImageBase64 = [annotedImage base64StringWithQuality:0.85];
        UIImage *firstObjectImage = objectImages.firstObject;
        NSString *objectImageBase64 = [firstObjectImage base64StringWithQuality:0.90];
        if (!annotedImageBase64 || !objectImageBase64) {
            return;
        }
        [self onDetectionCapture:annotedImageBase64 base64_vehicle:objectImageBase64];
        self.lastCallbackTime = currentTime;
    }
}

- (void)onSuccessWithDetector:(VisionDetector * _Nonnull)detector objectBoxes:(NSArray<NSValue *> * _Nonnull)objectBoxes pixelBuffer:(CVPixelBufferRef _Nonnull)pixelBuffer {
    [self.cameraManager drawBoxes:objectBoxes pixelBuffer:pixelBuffer];
}

#pragma mark -

- (void)cameraManager:(CameraManager * _Nonnull)manager didFailWithError:(NSError * _Nonnull)error {
    [self onError:@"camera error"];
}

- (void)cameraManager:(CameraManager * _Nonnull)manager didOutput:(CVPixelBufferRef _Nonnull)pixelBuffer {
    [self.detector detectWithPixelBuffer:pixelBuffer];
    
    if (_shouldTakeNow) {
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        CIContext *context = [CIContext contextWithOptions:nil];
        CGRect extent = [ciImage extent];
        CGImageRef cgImage = [context createCGImage:ciImage fromRect:extent];
        UIImage *image = [UIImage imageWithCGImage:cgImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        CGImageRelease(cgImage);
        [self onCaptured:[image base64StringWithQuality:0.85]];
        _shouldTakeNow = NO;
    }
    
}

- (void)cameraManagerDidStart:(CameraManager * _Nonnull)manager {
    [self onCameraOpen];
}

- (void)cameraManagerDidStop:(CameraManager * _Nonnull)manager {
    [self onCameraClose];
}

@end
