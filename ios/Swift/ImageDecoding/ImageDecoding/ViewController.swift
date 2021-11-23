
import UIKit
import AVFoundation
import Photos
import DynamsoftBarcodeReader

class ViewController: UIViewController, DMDLSLicenseVerificationDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate, UIImagePickerControllerDelegate {
    
    var barcodeReader:DynamsoftBarcodeReader! = nil
    var sourceType:UIImagePickerController.SourceType!
    var loadingView:UIActivityIndicatorView!
    
    var selectedImageV:UIImageView! = UIImageView()
    var decodeButton:UIButton! = UIButton()
    var selectPictureButton:UIButton! = UIButton()
    
    let screenWidth = UIScreen.main.bounds.size.width
    let screenHeight = UIScreen.main.bounds.size.height
    let safeAreaBottomHeight:CGFloat = UIApplication.shared.statusBarFrame.size.height > 20 ? 34 : 0
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.white
        
        self.setUpUI()
        self.configurationDBR()
    }

    func setUpUI() {
       
        selectedImageV = UIImageView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        selectedImageV.backgroundColor = UIColor.white
        selectedImageV.image = UIImage(named: "DynamsoftDefaultImage")
        selectedImageV.layer.contentsGravity = CALayerContentsGravity.resizeAspect
        selectedImageV.layer.masksToBounds = true
        self.view.addSubview(selectedImageV)
        
        decodeButton = UIButton(type: .custom)
        decodeButton.frame = CGRect(x: (screenWidth - 100) / 2.0, y: screenHeight - 100, width: 100, height: 50)
        decodeButton.backgroundColor = UIColor.clear
        decodeButton.setTitle("decode", for: .normal)
        decodeButton.setTitleColor(UIColor.brown, for: .normal)
        decodeButton.layer.cornerRadius = 10;
        decodeButton.layer.borderColor = UIColor.brown.cgColor
        decodeButton.layer.borderWidth = 1
        decodeButton .addTarget(self, action: #selector(decodeAction), for: .touchUpInside)
        self.view.addSubview(decodeButton)
        
        selectPictureButton = UIButton(type: .custom)
        selectPictureButton.frame = CGRect(x: screenWidth - 60 - 20, y: 40 + safeAreaBottomHeight, width: 65, height: 65)
        selectPictureButton.setImage(UIImage(named: "icon_select"), for: .normal)
        selectPictureButton.addTarget(self, action: #selector(selectPic), for: .touchUpInside)
        self.view.addSubview(selectPictureButton)
        
        loadingView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        loadingView.center = self.view.center
        loadingView.style = .gray
        self.view.addSubview(loadingView)
    }
    
    //MARK: decodeAction
    @objc func decodeAction() {
        self.decodeButton?.isEnabled = false
        self.loadingView.startAnimating()
        
        // Method 1:decodeImage with image
        let image = self.selectedImageV.image

        DispatchQueue.global().async {
            let results = try! self.barcodeReader.decode(image!, withTemplate: "")
            self.handleResults(results: results)
        }
        
        // Method 2:decodeImage With base64String
//        let image = self.selectedImageV.image
//
//        DispatchQueue.global().async {
//            let results = try! self.barcodeReader.decodeBase64(self.encodeImageWithBase64(image: image!), withTemplate: "")
//            self.handleResults(results: results)
//        }
        
        // Method 3:decodeImage with buffer
        
//        let image = self.selectedImageV.image
//
//        DispatchQueue.global().async {
//            let results = self.dbrDecodeBufferWithImage(image: image!)
//            self.handleResults(results: results)
//        }
        
    }
    
    /// encode image with base64
    func encodeImageWithBase64(image : UIImage) -> String {
        let imageData = image.pngData()
        
        return (imageData?.base64EncodedString())!
    }
    
    /// barcode reader decodeImage with buffer
    func dbrDecodeBufferWithImage(image : UIImage) -> Array<iTextResult> {
        
        let width = image.cgImage?.width
        let height = image.cgImage?.height
        let stride = image.cgImage?.bytesPerRow
        let bpp = image.cgImage?.bitsPerPixel
        
        let provider = image.cgImage?.dataProvider
        let buffer : Data =  provider?.data as! Data
        
        
        var type : EnumImagePixelFormat = EnumImagePixelFormat.RGB_888
        
        switch bpp {
        case 1:
            type = EnumImagePixelFormat.binary
        case 8:
            type = EnumImagePixelFormat.grayScaled
        case 32:
            type = EnumImagePixelFormat.ARGB_8888
        case 48:
            type = EnumImagePixelFormat.RGB_161616
        case 64:
            type = EnumImagePixelFormat.ARGB_16161616
        default:
            type = EnumImagePixelFormat.RGB_888
        }
      
        
  
        return try! barcodeReader.decodeBuffer(buffer, withWidth: width!, height: height!, stride: stride!, format: type, templateName: "")
    }
    
    //MARK: selectPic
    @objc func selectPic() {
        self.selectPictureButton?.isEnabled = false
        self .getAlertActionType(1)
    }
    
    func configurationDBR() -> Void {
        let dls = iDMDLSConnectionParameters()
        dls.organizationID = "200001"
        
        barcodeReader = DynamsoftBarcodeReader(licenseFromDLS: dls, verificationDelegate: self)
        
        var error : NSError? = NSError()
        
        let settings = try? barcodeReader.getRuntimeSettings()
        settings!.expectedBarcodesCount = 5
        barcodeReader.update(settings!, error: &error)
    }
    
    //MARK: DMDLSLicenseVerificationDelegate
    func dlsLicenseVerificationCallback(_ isSuccess: Bool, error: Error?) {
        var msg:String? = nil
        if(error != nil)
        {
            let err = error as NSError?
            if err?.code == -1009 {
                msg = "Unable to connect to the public Internet to acquire a license. Please connect your device to the Internet or contact support@dynamsoft.com to acquire an offline license."
                showResult("No Internet", msg!, "Try Again") { [weak self] in
                    self?.configurationDBR()
                }
            }else{
                msg = err!.userInfo[NSUnderlyingErrorKey] as? String
                if(msg == nil)
                {
                    msg = err?.localizedDescription
                }
                showResult("Server license verify failed", msg!, "OK") {
                    
                }
            
            }
        }
        
        
    }
    
    /**
     show result
     */
    private func showResult(_ title: String, _ msg: String, _ acTitle: String, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: acTitle, style: .default, handler: { _ in completion() }))
            self.present(alert, animated: true, completion: nil)
            self.decodeButton?.isEnabled = true
        }
    }

    /**
     handle results
     */
    func handleResults(results: [iTextResult]?) {
        if results!.count > 0 {
            var msgText:String = ""
            var title:String = "Results"
            let msg = "Please visit: https://www.dynamsoft.com/customer/license/trialLicense?"
            for item in results! {
                if results!.first!.exception != nil && results!.first!.exception!.contains(msg) {
                    msgText = "\(msg)product=dbr&utm_source=installer&package=ios to request for 30 days extension."
                    title = "Exception"
                    break
                }
                if item.barcodeFormat_2.rawValue != 0 {
                    msgText = msgText + String(format:"\nFormat: %@\nText: %@\n", item.barcodeFormatString_2!, item.barcodeText ?? "No result")
                }else{
                    msgText = msgText + String(format:"\nFormat: %@\nText: %@\n", item.barcodeFormatString!,item.barcodeText ?? "No result")
                }
            }
            showResult(title, msgText, "OK") { self.loadingView.stopAnimating()
            }
        }else{
            showResult("No result", "", "OK") { self.loadingView.stopAnimating()
            }
        }
    }
    
    //MARK: Photo album authorization
    func getAlertActionType(_ t:Int){
        var type:UIImagePickerController.SourceType = .photoLibrary
        if (t == 1) {
            type = .photoLibrary
        }else if (t == 2) {
            type = .camera
        }
        sourceType = type
        let cameragranted:Int = self.AVAuthorizationStatusIsGranted()
        self.selectPictureButton?.isEnabled = true

        if cameragranted == 0 {
            let alertController = UIAlertController(title: "Tips", message: "Settings-Privacy-Camera/Album-Authorization", preferredStyle: .alert)
            let comfirmAction = UIAlertAction(title: "OK", style: .default) { ac in
                let url:URL = URL(fileURLWithPath: UIApplication.openSettingsURLString)
                if UIApplication.shared.canOpenURL(url) { UIApplication.shared.openURL(url) }
            }
            alertController.addAction(comfirmAction)
            self.present(alertController, animated: true, completion: nil)
        }else if cameragranted == 1 {
            self.presentPickerViewController()
        }
    }
    
    func AVAuthorizationStatusIsGranted() -> Int{
        let mediaType:AVMediaType = .video
        let authStatusVideo:AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
        let authStatusAlbm:PHAuthorizationStatus  = .authorized
        let authStatus:Int = sourceType == UIImagePickerController.SourceType.photoLibrary ? authStatusAlbm.rawValue : authStatusVideo.rawValue
        switch authStatus {
        case 0:
            if sourceType == UIImagePickerController.SourceType.photoLibrary {
                PHPhotoLibrary.requestAuthorization { status in
                    if status == .authorized {
                        self.presentPickerViewController()
                    }
                }
            }else{
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        self.presentPickerViewController()
                    }
                }
            }
            return 2
        case 1: return 0
        case 2: return 0
        case 3: return 1
        default:
            return 0
        }
    }
    
    func presentPickerViewController(){
        DispatchQueue.main.async {
            let picker = UIImagePickerController()
            if #available(iOS 11.0, *) {
                UIScrollView.appearance().contentInsetAdjustmentBehavior = .always
            }
            picker.delegate = self
            picker.sourceType = self.sourceType
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    //MARK: UIImagePickerViewDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        DispatchQueue.main.async {
            self.selectedImageV.image = image
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
}

