

#import "ViewController.h"
#import <Photos/Photos.h>
#import <DynamsoftBarcodeReader/DynamsoftBarcodeReader.h>

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController ()<DMDLSLicenseVerificationDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) DynamsoftBarcodeReader *barcodeReader;

@end

@implementation ViewController
{
    NSInteger sourceType;
    UIActivityIndicatorView *loadingView;
    
    UIImageView *selectedImageV;
    UIButton *decodeButton;
    UIButton *selectPictureButton;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setUpUI];
    [self configurationDBR];
   
}

- (void)setUpUI
{
    CGFloat SafeAreaBottomHeight = [[UIApplication sharedApplication] statusBarFrame].size.height > 20 ? 34 : 0;
    
    selectedImageV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    selectedImageV.backgroundColor = [UIColor whiteColor];
    
    selectedImageV.image = [UIImage imageNamed:@"DynamsoftDefaultImage"];
    selectedImageV.layer.contentsGravity = kCAGravityResizeAspect;
    selectedImageV.layer.masksToBounds = YES;
    [self.view addSubview:selectedImageV];
    
    decodeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    decodeButton.frame = CGRectMake((kScreenWidth - 100) / 2.0, kScreenHeight - 100, 100, 50);
    decodeButton.backgroundColor = [UIColor clearColor];
    [decodeButton setTitle:@"decode" forState:UIControlStateNormal];
    [decodeButton setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    decodeButton.layer.cornerRadius = 10;
    decodeButton.layer.borderColor = [UIColor brownColor].CGColor;
    decodeButton.layer.borderWidth = 1;
    [decodeButton addTarget:self action:@selector(decodeAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:decodeButton];
    
    selectPictureButton = [[UIButton alloc] initWithFrame:CGRectMake(kScreenWidth - 65 - 20, 44 + SafeAreaBottomHeight, 65, 65)];
    [selectPictureButton setImage:[UIImage imageNamed:@"icon_select"] forState:UIControlStateNormal];
    [selectPictureButton addTarget:self action:@selector(selectPic) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:selectPictureButton];
    
    // activityIndicatorView
    loadingView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    loadingView.center = self.view.center;
    [loadingView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:loadingView];
}

//MARK: decodeAction
- (void)decodeAction
{
    [decodeButton setEnabled:NO];
   
    [loadingView startAnimating];
    
    // Method 1:decodeImage with image
    UIImage *selectedImage = selectedImageV.image;

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSError* error = [[NSError alloc] init];
        // image decode
        NSArray<iTextResult*>* results = [self->_barcodeReader decodeImage:selectedImage withTemplate:@"" error:&error];
        [self handleResults:results err:error];
    });
    
    // Method 2:decodeImage With base64String
//    UIImage *selectedImage = selectedImageV.image;
//
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        NSError* error = [[NSError alloc] init];
//        // image decode
//        NSArray<iTextResult*>* results = [self->_barcodeReader decodeBase64:[self encodeImageWithBase64:selectedImage] withTemplate:@"" error:&error];
//
//        [self handleResults:results err:error];
//    });
   
    // Method 3:decodeImage with buffer
//    UIImage *selectedImage = selectedImageV.image;
//
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        NSError* error = [[NSError alloc] init];
//        // image decode
//        NSArray<iTextResult*>* results = [self dbrDecodeBufferWithImage:selectedImage];
//
//        [self handleResults:results err:error];
//    });
}

/// encode image with base64
- (NSString *)encodeImageWithBase64:(UIImage *)image
{
    NSData *imageData = UIImagePNGRepresentation(image);
    
    return [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}


/// barcode reader decodeImage with buffer
- (NSArray<iTextResult*>* _Nullable)dbrDecodeBufferWithImage:(UIImage *)image
{
    size_t width = CGImageGetWidth(image.CGImage);
    size_t height = CGImageGetHeight(image.CGImage);
    size_t stride = CGImageGetBytesPerRow(image.CGImage);
    size_t bpp = CGImageGetBitsPerPixel(image.CGImage);
    
    CGDataProviderRef provider = CGImageGetDataProvider(image.CGImage);
    NSData *buffer = (__bridge_transfer NSData *)CGDataProviderCopyData(provider);
    
    EnumImagePixelFormat type;
    
    switch (bpp) {
        case 1:
            type = EnumImagePixelFormatBinary;
            break;
        case 8:
            type = EnumImagePixelFormatGrayScaled;
            break;
        case 32:
            type = EnumImagePixelFormatARGB_8888;
            break;
        case 48:
            type = EnumImagePixelFormatRGB_161616;
            break;
        case 64:
            type = EnumImagePixelFormatARGB_16161616;
            break;
        default:
            type = EnumImagePixelFormatRGB_888;
            break;
    }
    
    NSError *error = nil;
    return [self.barcodeReader decodeBuffer:buffer withWidth:width height:height stride:stride format:type templateName:@"" error:&error];
}

//MARK: selectPic
- (void)selectPic
{
    [selectPictureButton setEnabled:NO];
    [self getAlertActionType:1];
}

- (void)configurationDBR{
    iDMDLSConnectionParameters* dls = [[iDMDLSConnectionParameters alloc] init];

    // Initialize license for Dynamsoft Barcode Reader.
    // The organization id 200001 here will grant you a public trial license good for 7 days. Note that network connection is required for this license to work.
    // If you want to use an offline license, please contact Dynamsoft Support: https://www.dynamsoft.com/company/contact/
    // You can also request a 30-day trial license in the customer portal: https://www.dynamsoft.com/customer/license/trialLicense?product=dbr&utm_source=installer&package=ios
    dls.organizationID = @"200001";
    _barcodeReader = [[DynamsoftBarcodeReader alloc] initLicenseFromDLS:dls verificationDelegate:self];
    
    NSError *error = [[NSError alloc] init];
   
    iPublicRuntimeSettings *setting = [_barcodeReader getRuntimeSettings:&error];
    setting.expectedBarcodesCount = 5;

    [_barcodeReader updateRuntimeSettings:setting error:&error];
   
}

#pragma mark - DMDLSLicenseVerificationDelegate
- (void)DLSLicenseVerificationCallback:(bool)isSuccess error:(NSError *)error
{
    if (isSuccess) {
        NSLog(@"DLS verify success!");
    }
    NSString* msg = @"";
    if(error != nil)
    {
        __weak ViewController *weakSelf = self;
        if (error.code == -1009) {
            msg = @"Unable to connect to the public Internet to acquire a license. Please connect your device to the Internet or contact support@dynamsoft.com to acquire an offline license.";
            [self showResult:@"No Internet"
                         msg:msg
                     acTitle:@"Try Again"
                  completion:^{
                [weakSelf configurationDBR];
                  }];
        }else{
            msg = error.userInfo[NSUnderlyingErrorKey];
            if(msg == nil)
            {
                msg = [error localizedDescription];
            }
            [self showResult:@"Server license verify failed"
                         msg:msg
                     acTitle:@"OK"
                  completion:^{
                
                  }];
        }
    }
}

/**
 show result
 */
- (void)showResult:(NSString *)title msg:(NSString *)msg acTitle:(NSString *)acTitle completion:(void (^)(void))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:acTitle style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    completion();
                                                }]];
        [self presentViewController:alert animated:YES completion:nil];
        
        [self->decodeButton setEnabled:true];
    });
}

/**
 handle results
 */
- (void)handleResults:(NSArray<iTextResult *> *)results err:(NSError*)error{
    if (results.count > 0) {
        NSString *title = @"Results";
        NSString *msgText = @"";
        NSString *msg = @"Please visit: https://www.dynamsoft.com/customer/license/trialLicense?";
        for (NSInteger i = 0; i< [results count]; i++) {
            if (results[i].exception != nil && [results[i].exception containsString:msg]) {
                msgText = [msg stringByAppendingString:@"product=dbr&utm_source=installer&package=ios to request for 30 days extension."];
                title = @"Exception";
                break;
            }
            if (results[i].barcodeFormat_2 != 0) {
                msgText = [msgText stringByAppendingString:[NSString stringWithFormat:@"\nFormat: %@\nText: %@\n", results[i].barcodeFormatString_2, results[i].barcodeText]];
            }else{
                msgText = [msgText stringByAppendingString:[NSString stringWithFormat:@"\nFormat: %@\nText: %@\n", results[i].barcodeFormatString, results[i].barcodeText]];
            }
        }
        [self showResult:title
                     msg:msgText
                 acTitle:@"OK"
              completion:^{
            
              }];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->loadingView stopAnimating];
        });
    }else{
        NSString *msg = error.code == 0 ? @"" : error.userInfo[NSUnderlyingErrorKey];
        [self showResult:@"No result" msg:msg  acTitle:@"OK" completion:^{
            [self->loadingView stopAnimating];
        }];
    }
}

#pragma mark - Photo album authorization
- (void)getAlertActionType:(NSInteger)type {
    NSInteger sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    if (type == 1) {
        sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }else if (type == 2) {
        sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    [self creatUIImagePickerControllerWithAlertActionType:sourceType];
}

- (void)creatUIImagePickerControllerWithAlertActionType:(NSInteger)type {
    sourceType = type;
    NSInteger cameragranted = [self AVAuthorizationStatusIsGranted];
    [selectPictureButton setEnabled:YES];
   
    if (cameragranted == 0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Tips"
                                                                                 message:@"Settings-Privacy-Camera/Album-Authorization"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *comfirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
        }];
        [alertController addAction:comfirmAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }else if (cameragranted == 1) {
        [self presentPickerViewController];
    }
}

- (NSInteger)AVAuthorizationStatusIsGranted{
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatusVideo = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    PHAuthorizationStatus authStatusAlbm  = [PHPhotoLibrary authorizationStatus];
    NSInteger authStatus = sourceType == UIImagePickerControllerSourceTypePhotoLibrary ? authStatusAlbm : authStatusVideo;
    
    switch (authStatus) {
        case 0: {
            if (sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                    if (status == PHAuthorizationStatusAuthorized) {
                        [self presentPickerViewController];
                    }
                }];
            }else{
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    if (granted) {
                        [self presentPickerViewController];
                    }
                }];
            }
        }
            return 2;
        case 1: return 0;
        case 2: return 0;
        case 3: return 1;
        default:return 0;
    }
}

- (void)presentPickerViewController{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        if (@available(iOS 11.0, *)){
            [[UIScrollView appearance] setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentAlways];
        }
        picker.delegate = self;
        picker.sourceType = self->sourceType;
        [self presentViewController:picker animated:YES completion:nil];
    });
}

#pragma mark - UIImagePicker delegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self->selectedImageV.image = image;
    });
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}



@end
