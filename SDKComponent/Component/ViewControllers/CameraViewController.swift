/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Contains the view controller for the Breakfast Finder.
 */

import UIKit
import AVFoundation
import Vision

enum ComponentStatus {
    case created, initialized, started, inProgress, finalized, aborted
}

protocol CameraViewControllerDelegate {
    func respond(response : Any, component : SDKComponent)
    func updateStatus(status: ComponentStatus)
    func getStatus() -> ComponentStatus
}

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var bufferSize : CGSize = .zero
    var rootLayer : CALayer! = nil
    var baseLayer : CALayer! = nil
    var areaLayer = CALayer()
    var flagArea : Bool = false
    var sideView : CameraSideView = .front
    
    var position : AVCaptureDevice.Position = .front
    
    @IBOutlet weak private var previewView: UIView!
    
    let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var detectionOverlay: CALayer! = nil
    
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAVCapture()
        setupLayers()
        updateLayerGeometry()
        setupComponent()
    }
    
    func setupSideView(sideView: CameraSideView){
        self.sideView = sideView
    }
    
    func setupComponent(){
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func selectedPreset() -> AVCaptureSession.Preset {
        return session.sessionPreset
    }
    
    func videoResolution() -> CGSize {
        var ret = CGSize()
        if(session.canSetSessionPreset(.hd1280x720) ){
            ret = CGSize(width:720, height: 1280)
        }else{
            if(session.canSetSessionPreset(.iFrame1280x720)    ){
                ret = CGSize(width:720, height: 1280)
            }else{
                if(session.canSetSessionPreset(.iFrame960x540)   ){
                    ret = CGSize(width:540, height: 960)
                }else{
                    if(session.canSetSessionPreset(.vga640x480)){
                        ret = CGSize(width:480, height: 640)
                    }
                }
            }
        }
        return ret;
    }
    
    /// Returns all cameras on the device.
    private func getListOfCameras() -> [AVCaptureDevice] {
        
    #if os(iOS)
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .builtInTelephotoCamera
            ],
            mediaType: .video,
            position: .unspecified)
    #elseif os(macOS)
        let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera
            ],
            mediaType: .video,
            position: .unspecified)
    #endif
        
        return session.devices
    }

    /// Returns all microphones on the device.
    private func getListOfMicrophones() -> [AVCaptureDevice] {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInMicrophone
            ],
            mediaType: .audio,
            position: .unspecified)
        
        return session.devices
    }

    /// Converts giving AVCaptureDevice list to the String
    private func convertDeviceListToString(_ devices: [AVCaptureDevice]) -> [String] {
        var names: [String] = []
        
        for device in devices {
            names.append(device.localizedName)
        }
        
        return names
    }

    private func getListOfCamerasAsString() -> [String] {
        let devices = getListOfCameras()
        return convertDeviceListToString(devices)
    }

    private func getListOfMicrophonesAsString() -> [String] {
        let devices = getListOfMicrophones()
        return convertDeviceListToString(devices)
    }

    

    func setupAVCapture() {
        var deviceInput: AVCaptureDeviceInput!
        

        //CameraSideView
        var isFrontAvailable = false, isBackAvailable = false
        //print("ListOfCameras", getListOfCameras())
        var lista = getListOfCameras()
        var x = 0
        
        var pos : AVCaptureDevice.Position? 
        for device in lista{
            x += 1
            if(device.position == AVCaptureDevice.Position.front){
                isFrontAvailable = true
            }
            if(device.position == AVCaptureDevice.Position.back){
                isBackAvailable = true
            }
        }
        print("sideView", sideView)
        if(self.sideView == .backOrFront){
            if(isBackAvailable){
                pos = .back
            }else{
                pos = .front
            }
        }
        if(self.sideView == .frontOrBack){
            if(isFrontAvailable){
                pos = .front
            }else{
                pos = .back
            }
        }
        if(self.sideView == .back){
            pos = .back
        }
        if(self.sideView == .front){
            pos = .front
        }
        // PARAMETRO
        // Select a video device, make an input
        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: pos!).devices.first
        do {
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            print("Could not create video device input: \(error)")
            return
        }
        
        session.beginConfiguration()
        
        if(session.canSetSessionPreset(.hd1280x720)){
            session.sessionPreset = .hd1280x720
        }else{
            if(session.canSetSessionPreset(.iFrame1280x720)){
                session.sessionPreset = .iFrame1280x720
            }else{
                if(session.canSetSessionPreset(.iFrame960x540)){
                    session.sessionPreset = .iFrame960x540
                }else{
                    if(session.canSetSessionPreset(.vga640x480)){
                        session.sessionPreset = .vga640x480
                    }
                }
            }
        }
        
        // Add a video input
        guard session.canAddInput(deviceInput) else {
            print("Could not add video device input to the session")
            session.commitConfiguration()
            return
        }
        session.addInput(deviceInput)
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            // Add a video data output
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            print("Could not add video data output to the session")
            session.commitConfiguration()
            return
        }
        let captureConnection = videoDataOutput.connection(with: .video)
        captureConnection?.videoOrientation = .portrait
        // Always process the frames
        captureConnection?.isEnabled = true
        do {
            try  videoDevice!.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            videoDevice!.unlockForConfiguration()
        } catch {
            print(error)
        }
        session.commitConfiguration()
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        //previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        //previewLayer.videoGravity = AVLayerVideoGravity.
        //previewLayer.backgroundColor = UIColor.white.cgColor
        
        //previewLayer = UIColor.black.cgColor
        /**
         Mirror
         if (self.cameraLayer!.connection.isVideoMirroringSupported)
         {
         self.cameraLayer!.connection.automaticallyAdjustsVideoMirroring = false
         self.cameraLayer!.connection.isVideoMirrored = true
         }
         */
        rootLayer = previewView.layer
        //previewView.sizeToFit()
        previewLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(previewLayer)
    }
    
    func startCaptureSession() {
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    // Clean up capture setup
    func teardownAVCapture() {
        previewLayer.removeFromSuperlayer()
        previewLayer = nil
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput, didDrop didDropSampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    }
    
    public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // to be implemented in the subclass
    }
    
    
    func setupLayers() {
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: bufferSize.width,
                                         height: bufferSize.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
    }
    
    func updateLayerGeometry() {
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / bufferSize.height
        let yScale: CGFloat = bounds.size.height / bufferSize.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // rotate the layer into screen orientation and scale and mirror
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        // center the layer
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        CATransaction.commit()
    }
    
}

enum Status {
    case read, warn, check, fail, pass
}

