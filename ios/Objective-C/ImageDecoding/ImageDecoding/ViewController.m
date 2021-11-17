

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

- (void)decodeAction
{
    [decodeButton setEnabled:NO];
   
    [loadingView startAnimating];
    UIImage *selectedImage = selectedImageV.image;

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSError* error = [[NSError alloc] init];
        // image decode
        NSArray<iTextResult*>* results = [self->_barcodeReader decodeImage:selectedImage withTemplate:@"" error:&error];
        [self handleResults:results err:error];
    });
}

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
    // LocalizationModes       : LocalizationModes are all enabled as default. Barcode reader will automatically switch between the modes and try decoding continuously until timeout or the expected barcode count is reached. Please manually update the enabled modes list or change the expected barcode count to promote the barcode scanning speed.
    // Read more about localization mode members: https://www.dynamsoft.com/barcode-reader/parameters/enum/parameter-mode-enums.html?ver=latest#localizationmode
    // BarcodeFormatIds        : The simpler barcode format, the faster decoding speed.
    // ExpectedBarcodesCount   : The barcode scanner will try to find 512 barcodes. If the result count does not reach the expected amount, the barcode scanner will try other algorithms in the setting list to find enough barcodes.
    // DeblurModes             : DeblurModes are all enabled as default. Barcode reader will automatically switch between the modes and try decoding continuously until timeout or the expected barcode count is reached. Please manually update the enabled modes list or change the expected barcode count to promote the barcode scanning speed.
    // Read more about deblur mode members: https://www.dynamsoft.com/barcode-reader/parameters/enum/parameter-mode-enums.html#deblurmode
    // ScaleUpModes            : It is a parameter to control the process for scaling up an image used for detecting barcodes with small module size.
    // GrayscaleTransformationModes : The image will be transformed into inverted grayscale with GTM_INVERTED mode.
    // DPMCodeReadingModes     : It is a parameter to control how to read direct part mark (DPM) barcodes.
    
    NSString* json = @"{\"ImageParameter\": {\"BarcodeFormatIds\": [\"BF_ALL\"],\"ExpectedBarcodesCount\": 5,\"RegionPredetectionModes\": [{\"Mode\": \"RPM_GENERAL\"}],\"DPMCodeReadingModes\":[{\"Mode\":\"DPMCRM_GENERAL\"}],\"LocalizationModes\": [{\"Mode\": \"LM_CONNECTED_BLOCKS\"},{\"Mode\": \"LM_SCAN_DIRECTLY\",\"ScanDirection\": 0},{\"Mode\": \"LM_STATISTICS\"},{\"Mode\": \"LM_LINES\"},{\"Mode\": \"LM_STATISTICS_MARKS\"},{\"Mode\": \"LM_STATISTICS_POSTAL_CODE\"}],\"BinarizationModes\": [{\"BlockSizeX\": 0,\"BlockSizeY\": 0,\"EnableFillBinaryVacancy\": 1,\"Mode\": \"BM_LOCAL_BLOCK\",\"ThresholdCompensation\": 10},{\"EnableFillBinaryVacancy\": 0,\"Mode\": \"BM_LOCAL_BLOCK\",\"ThresholdCompensation\": 15}],\"DeblurModes\": [{\"Mode\": \"DM_DIRECT_BINARIZATION\"},{\"Mode\": \"DM_THRESHOLD_BINARIZATION\"},{\"Mode\": \"DM_GRAY_EQUALIZATION\"},{\"Mode\": \"DM_SMOOTHING\"},{\"Mode\": \"DM_MORPHING\"},{\"Mode\": \"DM_DEEP_ANALYSIS\"},{\"Mode\": \"DM_SHARPENING\"}],\"GrayscaleTransformationModes\": [{\"Mode\": \"GTM_ORIGINAL\"},{\"Mode\": \"GTM_INVERTED\"}],\"ScaleUpModes\": [{\"Mode\": \"SUM_AUTO\"}],\"Name\":\"ReadRateFirstSettings\",\"Timeout\":30000}}";

    [_barcodeReader initRuntimeSettingsWithString:json conflictMode:EnumConflictModeOverwrite error:&error];
   
}

#pragma mark - DMDLSLicenseVerificationDelegate
- (void)DLSLicenseVerificationCallback:(bool)isSuccess error:(NSError *)error
{
    if (isSuccess) {
        NSLog(@"verify success!");
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
