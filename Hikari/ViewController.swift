//
//  ViewController.swift
//  Hikari
//
//  Created by ethan on 4/25/18.
//  Copyright © 2018 ethan. All rights reserved.
//
//  Working base app for RAW capture
//  https://ubunifu.co/swift/raw-photo-capture-sample-swift-4-ios-11
import UIKit
import AVFoundation
import Photos

class ViewController: UIViewController {
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var capturePhotoOutput: AVCapturePhotoOutput?
    var captureDevice: AVCaptureDevice?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var rawURL: URL?
    var compressedData: Data?
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var focus: UISlider!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.captureSession = AVCaptureSession()
        self.captureSession?.sessionPreset = .photo
        self.capturePhotoOutput = AVCapturePhotoOutput()
        self.captureDevice = AVCaptureDevice.default(for: .video)
        let input = try! AVCaptureDeviceInput(device: self.captureDevice!)
        self.captureSession?.addInput(input)
        self.captureSession?.addOutput(self.capturePhotoOutput!)
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
        self.previewLayer?.frame = self.previewView.bounds
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        self.previewView.layer.addSublayer(self.previewLayer!)
        self.captureSession?.startRunning()
        
        if let device = captureDevice {
            do{
                try device.lockForConfiguration()
                
                device.exposureMode = .custom
                device.focusMode = .locked
                device.unlockForConfiguration()
            }
            catch {
                
                print("didn't lock")
            }
            
        }
        
        /*
        // Do any additional setup after loading the view, typically from a nib.
        
        let captureDevice = AVCaptureDevice.default(for: .video)
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            previewView.layer.addSublayer(videoPreviewLayer!)
            
            captureSession?.startRunning()
            
            // Get an instance of ACCapturePhotoOutput class
            
            capturePhotoOutput = AVCapturePhotoOutput()
            capturePhotoOutput?.isHighResolutionCaptureEnabled = true
            // Set the output on the capture session
            print(captureSession?.canAddOutput(capturePhotoOutput!))
            captureSession?.addOutput(capturePhotoOutput!)
            print(capturePhotoOutput?.__availableRawPhotoPixelFormatTypes.first)
            print("loaded")
            
            
        } catch {
            print(error)
        }
        
        */
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func focusChanged(_ sender: UISlider) {
        if let device = captureDevice {
            do{
                try device.lockForConfiguration()
                print(sender.value)
                device.setFocusModeLocked(lensPosition: sender.value, completionHandler: nil)
                //device.focusMode = .locked
                device.unlockForConfiguration()
            }
            catch {
                
                print("didn't lock")
            }
            
        }
    }
    @IBAction func isoChanged(_ sender: UISlider) {
        if let device = captureDevice {
            do{
                var iso = sender.value * 400
                iso = min(iso, device.activeFormat.maxISO)
                iso = max(iso, device.activeFormat.minISO)
                try device.lockForConfiguration()
                device.setExposureModeCustom(duration: device.exposureDuration, iso: iso, completionHandler: nil)
                device.focusMode = .locked
                device.unlockForConfiguration()
            }
            catch {
                
                print("didn't lock")
            }
            
        }
    }
    @IBAction func shutterspeedChanged(_ sender: UISlider) {
        let p = pow(Double(sender.value), 5.0) // Apply power function to expand slider's low-end range
        
        let minDurationSeconds = max(CMTimeGetSeconds((captureDevice?.activeFormat.minExposureDuration)!), 1.0/1000)
        let maxDurationSeconds = CMTimeGetSeconds((captureDevice?.activeFormat.maxExposureDuration)!)
        let newDurationSeconds = p * ( maxDurationSeconds - minDurationSeconds ) + minDurationSeconds; // Scale from 0-1 slider range to actual duration

        
        if let device = captureDevice {
            do{
                try device.lockForConfiguration()
                let preferredTimeScale : Int32 = 1
                let time = CMTimeMakeWithSeconds(newDurationSeconds, 1000*1000*1000)
                device.setExposureModeCustom(duration: time, iso: device.iso, completionHandler: nil)
                device.focusMode = .locked
                device.unlockForConfiguration()
            }
            catch {
                
                print("didn't lock")
            }
            
        }
    }
    @IBAction func onTapPhoto(_ sender: Any) {
        
        
 
        
        let photoSettings : AVCapturePhotoSettings!
        guard let availableRawFormat = capturePhotoOutput?.__availableRawPhotoPixelFormatTypes.first else { return }
        //photoSettings = AVCapturePhotoSettings(rawPixelFormatType: availableRawFormat.uint32Value)
        photoSettings = AVCapturePhotoSettings(rawPixelFormatType: availableRawFormat.uint32Value, processedFormat: [AVVideoCodecKey : AVVideoCodecType.jpeg])
        photoSettings.isAutoStillImageStabilizationEnabled = false
        photoSettings.flashMode = .off
        photoSettings.isHighResolutionPhotoEnabled = false
        let desiredPreviewPixelFormat = NSNumber(value: kCVPixelFormatType_32BGRA)
        if photoSettings.__availablePreviewPhotoPixelFormatTypes.contains(desiredPreviewPixelFormat) {
            photoSettings.previewPhotoFormat = [
                kCVPixelBufferPixelFormatTypeKey as String : desiredPreviewPixelFormat,
                kCVPixelBufferWidthKey as String : NSNumber(value: 512),
                kCVPixelBufferHeightKey as String : NSNumber(value: 512)
            ]
        }
        self.capturePhotoOutput?.capturePhoto(with: photoSettings, delegate: self)
        /*
        print("tapped")
        // Make sure capturePhotoOutput is valid
        guard let capturePhotoOutput = self.capturePhotoOutput else { return }
        print("available")
        guard let availableRawFormat = capturePhotoOutput.availableRawPhotoPixelFormatTypes.first else { return }
        print(availableRawFormat)
        // Get an instance of AVCapturePhotoSettings class
        //let rawFormatType = kCVPixelFormatType_14Bayer_RGGB
        print("capute photo start")
        
        //let photoSettings = AVCapturePhotoSettings.init(rawPixelFormatType: rawFormatType)
        print("photo settings initialized")
        // Set photo settings for our need
 */
        /*
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .auto
        // Call capturePhoto method by passing our photo settings and a
        // delegate implementing AVCapturePhotoCaptureDelegate
        print("capturing")
        capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self as AVCapturePhotoCaptureDelegate)
        print("captured")
        */
    }
    
}


extension ViewController : AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if(photo.isRawPhoto){
            let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMddHHmmss"
            formatter.locale = Locale.init(identifier: "en_US_POSIX")
            let filePath =  dir.appending(String(format: "/%@.dng", formatter.string(from: Date())))
            let dngFileURL = URL(fileURLWithPath: filePath)
            
            let dngData = photo.fileDataRepresentation()!
            do {
                try dngData.write(to: dngFileURL, options: [])
                self.rawURL = dngFileURL
            } catch {
                print("Unable to write DNG file.")
                return
            }
        } else{
            
            self.compressedData = photo.fileDataRepresentation()
        }
        
        //Try saving based on earlier code
        /*
        PHPhotoLibrary.shared().performChanges( {
            let creationRequest = PHAssetCreationRequest.forAsset()
            let creationOptions = PHAssetResourceCreationOptions()
            creationOptions.shouldMoveFile = true
            creationRequest.addResource(with: .photo, data: jpegData, options: nil)
            creationRequest.addResource(with: .alternatePhoto, fileURL: dngFileURL, options: creationOptions)
        }, completionHandler: completionHandler)
        */
        /*
        PHPhotoLibrary.shared().performChanges( {
            let creationRequest = PHAssetCreationRequest.forAsset()
            let creationOptions = PHAssetResourceCreationOptions()
            creationOptions.shouldMoveFile = true
            creationRequest.addResource(with: .photo, data: dngData, options: nil)
            creationRequest.addResource(with: .alternatePhoto, fileURL: dngFileURL, options: creationOptions)
        }, completionHandler: nil)
        */
        //From helpful stackoverflow commenter
        
        /*
        PHPhotoLibrary.shared().performChanges({
            // Add the compressed (HEIF) data as the main resource for the Photos asset.
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: self.compressedData!, options: nil)
            
            // Add the RAW (DNG) file as an altenate resource.
            let options = PHAssetResourceCreationOptions()
            options.shouldMoveFile = true
            creationRequest.addResource(with: .alternatePhoto, fileURL: self.rawURL!, options: options)
        }, completionHandler: nil)
        
        
        
        //Continue template
        let items = [dngFileURL]
        let activityView = UIActivityViewController.init(activityItems: items, applicationActivities: nil)
        activityView.popoverPresentationController?.sourceView = self.view
        activityView.excludedActivityTypes = [
            UIActivityType.copyToPasteboard,
            UIActivityType.assignToContact,
            UIActivityType.openInIBooks,
        ]
        self.present(activityView, animated: true, completion: nil)
 */
    }
    
    /*
    //Code grabbed from https://stackoverflow.com/questions/46478262/taking-photo-with-custom-camera-ios-11-0-swift-4-update-error?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("ran")
        // Check if there is any error in capturing
        guard error == nil else {
            print("Fail to capture photo: \(String(describing: error))")
            return
        }
        
        // Check if the pixel buffer could be converted to image data
        guard let imageData = photo.fileDataRepresentation() else {
            print("Fail to convert pixel buffer")
            return
        }
        
        // Check if UIImage could be initialized with image data
        guard let capturedImage = UIImage.init(data: imageData , scale: 1.0) else {
            print("Fail to convert image data to UIImage")
            return
        }
        
        // Get original image width/height
        let imgWidth = capturedImage.size.width
        let imgHeight = capturedImage.size.height
        // Get origin of cropped image
        let imgOrigin = CGPoint(x: (imgWidth - imgHeight)/2, y: (imgHeight - imgHeight)/2)
        // Get size of cropped iamge
        let imgSize = CGSize(width: imgHeight, height: imgHeight)
        
        // Check if image could be cropped successfully
        guard let imageRef = capturedImage.cgImage?.cropping(to: CGRect(origin: imgOrigin, size: imgSize)) else {
            print("Fail to crop image")
            return
        }
        
        // Convert cropped image ref to UIImage
        let imageToSave = UIImage(cgImage: imageRef, scale: 1.0, orientation: .down)
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
        
        // Stop video capturing session (Freeze preview)
        //captureSession.stopRunning()
    }
    */
    /*
    func photoOutput(_ captureOutput: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,
                     previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
                 resolvedSettings: AVCaptureResolvedPhotoSettings,
                 bracketSettings: AVCaptureBracketedStillImageSettings?,
                 error: Error?) {
        // get captured image
        // Make sure we get some photo sample buffer
        guard error == nil,
            let photoSampleBuffer = photoSampleBuffer else {
                print("Error capturing photo: \(String(describing: error))")
                return
        }
        // Convert photo same buffer to a jpeg image data by using // AVCapturePhotoOutput
        guard let imageData =
            AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else {
                return
        }
        // Initialise a UIImage with our image data
        let capturedImage = UIImage.init(data: imageData , scale: 1.0)
        if let image = capturedImage {
            // Save our captured image to photos album
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
    }
 */
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        //guard error != nil else { print("Error capturing photo: \(error!)"); return }
        
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges({
                // Add the compressed (HEIF) data as the main resource for the Photos asset.
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: self.compressedData!, options: nil)
                
                // Add the RAW (DNG) file as an altenate resource.
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = true
                creationRequest.addResource(with: .alternatePhoto, fileURL: self.rawURL!, options: options)
            }, completionHandler: nil)
        }
        
    }
}
