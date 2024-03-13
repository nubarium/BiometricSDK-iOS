//
//  CommonCapture.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 12/02/23.
//  Copyright © 2023 Google Inc. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import QuartzCore
import CoreMedia
import Vision

class CommonCaptureViewController: CameraViewController, PreviewFaceViewControllerDelegate, PreviewIdViewControllerDelegate {
    
    var delegate : CameraViewControllerDelegate?
    
    var confirmationPage = ""
    var requestId = ""
    
    internal var orientation : UIInterfaceOrientation?
    internal var launch = LaunchComponentView()
    internal var messagesResource:String = ""
    internal var allowManualSideView: Bool = false
    internal var globalTimeout: Int = 0
    
    internal var enableVideoHelp : Bool = false
    internal var enableTroubleshootHelp: Bool = false
    internal var showIntro: Bool = false
    internal var introIsVisible: Bool = false
        
    var selectedSideView: CameraSideView?
    internal var contador = 0
    internal var areaRect =  CGRect()
    internal var areaRectScale =  CGRect()
    internal var ratioScreen: CGFloat = 0.0
    internal var offsetY: CGFloat = 0.0
    internal var flagConfirmImage =  false
    internal var newAreaRect = CGRect()
    
    internal let messsageLayer = CATextLayer()
    internal let holeBorderLayer = CAShapeLayer()
    internal var holeLayer = CAShapeLayer()
    
    // UI definitions
    internal let lottieOk = LottieOverlay(name:"lottie_ok")
    internal let lottieFail = LottieOverlay(name:"lottie_fail")
    
    internal var isFinished = false
    internal var flagFirstTime = false
    internal var hasExpired = false
    
    internal var blockDetect = true
    internal var flagShowMessage = true
    
    // Schedule elements
    private let queue = Dispatch.DispatchQueue(label: "queue", attributes: .concurrent)
    internal var workItem : DispatchWorkItem? // = DispatchWorkItem{}
    
    internal var currentTaskDimension : Dimension?
    internal var currentTaskConfiguration : Task?//Configuration?
    internal var currentTaskStatus : TaskStatus = .notStarted
    
    internal var tasksToDo: Queue<Task> = Queue<Task>()
    internal var tasksCatalog: Queue<Task> = Queue<Task>()

    var sdkComponent: SdkComponent?
    
    func loadTasks(tasks: [Task]){
        print("LoadTasks")
        tasksToDo.enqueue(tasks)
        tasksCatalog.enqueue(tasks)
    }

    func reloadTasks(){
        tasksToDo.clear()
        tasksToDo.enqueue(tasksCatalog.all())
    }
    
    var currentTask: (Task, Dimension) {
        (currentTaskConfiguration!, currentTaskDimension!)
    }
    
    private var resolution : CGSize?
    
    override func viewDidLoad() {
        
        self.delegate?.updateStatus(status: ComponentStatus.inProgress )
        
        // Setup position previuos of loading
        super.viewDidLoad()
        
        resolution = videoResolution()
        setupBarButtons()
        flagFirstTime = true
        setupMl()
        
        if(sdkComponent!.showIntro){
            setupIntro()
        }else{
            startProcess()
        }
    }
    
    //
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if(!flagFirstTime){
            if(flagConfirmImage){
                returnToParent()
            }else{
                self.restartProcess()
                self.resumeSession()
            }
        }else{
            flagFirstTime = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("desaparezco")
        shutdown()
        if(self.delegate?.getStatus() != ComponentStatus.finalized){
            self.delegate?.updateStatus(status: ComponentStatus.finalized )
        }
    }
    
    func startTimer(){
        if(workItem == nil || workItem!.isCancelled){
            print("startTimer start")
            workItem = DispatchWorkItem {
                if(!self.isFinished){
                    self.hasExpired = true
                }
            }
            hasExpired = false
            let t = DispatchTime.now() + Double(globalTimeout)
            print("Se programa timeout  de ", t)
            DispatchQueue.main.asyncAfter(deadline: t) {
                self.queue.async(execute: self.workItem!) // not work
            }
        }else{
            print("startTimer ignore")
        }
    }
    
    func returnToParent(){
        self.navigationController?.popViewController(animated: false)
        self.dismiss(animated: false, completion: nil)
    }
    
    func setupMl(){
        
    }
    
    func nextTask() -> Bool{
        if(!tasksToDo.isEmpty){
            currentTaskConfiguration = tasksToDo.dequeue()
            currentTaskDimension = Dimension(conf: currentTaskConfiguration!)
            currentTaskDimension!.load(resolution: self.videoResolution())
            currentTaskStatus = .started
            if(workItem != nil && workItem?.isCancelled == false){
                workItem!.cancel()
            }
            self.globalTimeout = currentTaskConfiguration!.timeout
            
            return true
        }else{
            print("No more tasks to do")
        }
        return false
    }
    
    func startTask(){
        // Habilito bandera para leer la captura
        blockDetect = false
        // Setup de timer
        startTimer()
        // Seteo primer mensaje
        updateMessage(code: "clear")
    }
    
    func evaluateProcess(){
    }
    
    func stopTimer(){
        if(workItem != nil && workItem!.isCancelled == false){
            workItem!.cancel()
        }
    }

    func completeTask(){
        blockDetect = true
        currentTaskStatus = .completed
    }

    func cancelTask(){
        blockDetect = true
        currentTaskStatus = .cancelled
        stopTimer()
    }
    
    override func setupAVCapture() {
        super.setupAVCapture()
        
        // start the capture
        startCaptureSession()
    }
    
    override func setupComponent() {
        super.setupComponent()
        self.setupArea()
    }
    
    func setupArea(){
        
        areaRect = currentTaskDimension!.frameAreaOnScreen()
        print("areaRect", areaRect)
        areaRectScale = currentTaskDimension!.frameAreaOnImage()
        print("areaRectScale", areaRectScale)
        print("areaMaskCamera", currentTaskDimension!.frameMaskCamera())
        // Layer with the black background
        let maskLayer = CALayer()
        maskLayer.name = "MaskOrTransparency"
        maskLayer.bounds = currentTaskDimension!.frameMaskCamera()
        maskLayer.position = currentTaskDimension!.positionMaskCamera()
        maskLayer.cornerRadius = 0//150
        maskLayer.borderColor = UIColor.white.cgColor
        maskLayer.borderWidth = 0
        
        if(currentTaskConfiguration!.area.maskFill == .defaultBackground){
            print("background 1")
            maskLayer.backgroundColor = self.view.backgroundColor?.cgColor
        }else{
            if(currentTaskConfiguration!.area.maskFill == .transparency ){
                print("background 2")
                maskLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 0.5])
            }else{
                print("background 3")
                maskLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 1.0, 1.0])
            }
        }
        
        holeLayer.frame = view.bounds
        var circlePath: UIBezierPath?
        if(currentTaskDimension!.shapeType == ShapeType.rectangle){
            if(currentTaskDimension!.shapeRadius > 0){
                print("circlePath 1")
                circlePath = UIBezierPath(roundedRect: areaRect, cornerRadius: 20)
            }else{
                print("circlePath 2")
                circlePath = UIBezierPath(roundedRect: areaRect, cornerRadius: 0)
            }
        }else{
            print("circlePath 3")
            circlePath = UIBezierPath(ovalIn: areaRect)
        }
        let path = UIBezierPath(rect: view.bounds)
        // Append additional path which will create a circle
        path.append(circlePath!)
        // Setup the fill rule to EvenOdd to properly mask the specified area and make a crater
        holeLayer.fillRule = CAShapeLayerFillRule.evenOdd
        // Append the circle to the path so that it is subtracted.
        holeLayer.path = path.cgPath
        // Mask the layer with the hole.
        maskLayer.mask = holeLayer
        // Add transparency to root
        rootLayer.addSublayer(maskLayer)
        print("radius", currentTaskDimension!.shapeRadius)
        newAreaRect = currentTaskDimension!.frameAreaOnScreenRelative()
        holeBorderLayer.lineWidth = CGFloat(4)//lineWidth)
        if(currentTaskDimension!.shapeType == ShapeType.rectangle){
            if(currentTaskDimension!.shapeRadius > 0){
                print("hole1")
                holeBorderLayer.path = UIBezierPath(roundedRect: newAreaRect, cornerRadius: CGFloat(currentTaskDimension!.shapeRadius)).cgPath
            }else{
                print("hole2")
                holeBorderLayer.path = UIBezierPath(rect: newAreaRect).cgPath
            }
        }else{
            print("hole3")
            holeBorderLayer.path = UIBezierPath(ovalIn: newAreaRect).cgPath
        }
        holeBorderLayer.strokeColor = UIColor.white.cgColor
        holeBorderLayer.fillColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 1.0, 0])
        rootLayer.addSublayer(holeBorderLayer)
        
        messsageLayer.name = "Message"
        //messsageLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMakeRotation(M_PI_2));
        messsageLayer.alignmentMode = CATextLayerAlignmentMode.center
        print("currentTaskDimension!.frameMessage()", currentTaskDimension!.frameMessage())
        messsageLayer.bounds =  currentTaskDimension!.frameMessage()
        messsageLayer.position = currentTaskDimension!.positionMessage()
        messsageLayer.shadowOffset = CGSize(width: 1, height: 1)
        messsageLayer.contentsScale = 2.0
        
        //messsageLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 1.0, 1.0])
        //messsageLayer.borderWidth = 1
        //messsageLayer.borderColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 0.0, 1.0, 1])
        //messsageLayer.shadowOpacity = 0.7
        
        rootLayer.addSublayer(messsageLayer)
        
        // Layer with the black background
    }
    
    let maskLayer = CALayer()
    func resetupArea(){
        
        areaRect = currentTaskDimension!.frameAreaOnScreen()
        areaRectScale = currentTaskDimension!.frameAreaOnImage()
        
        // Layer with the black background
        
        maskLayer.name = "MaskOrTransparency"
        maskLayer.bounds = currentTaskDimension!.frameMaskCamera()
        maskLayer.position = currentTaskDimension!.positionMaskCamera()
        maskLayer.cornerRadius = 0//150
        maskLayer.borderColor = UIColor.white.cgColor
        maskLayer.borderWidth = 0
        
        if(currentTaskConfiguration!.area.maskFill == .defaultBackground){
            maskLayer.backgroundColor = self.view.backgroundColor?.cgColor
        }else{
            if(currentTaskConfiguration!.area.maskFill == .transparency ){
                maskLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 0.5])
            }else{
                maskLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 1.0, 1.0])
            }
        }
        
        var circlePath: UIBezierPath?
        //print("currentTaskDimension!.shapeType", currentTaskDimension!.shapeType.debugDescription)
        if(currentTaskDimension!.shapeType == ShapeType.rectangle){
            if(currentTaskDimension!.shapeRadius > 0){
                circlePath = UIBezierPath(roundedRect: areaRect, cornerRadius: 20)
            }
        }else{
            circlePath = UIBezierPath(ovalIn: areaRect)
        }
        let path = UIBezierPath(rect: view.bounds)
        // Append additional path which will create a circle
        path.append(circlePath!)
        holeLayer.path = path.cgPath
        

        
        newAreaRect = currentTaskDimension!.frameAreaOnScreenRelative()
        holeBorderLayer.lineWidth = CGFloat(4)//lineWidth)
        if(currentTaskDimension!.shapeType == ShapeType.rectangle ){
            if(currentTaskDimension!.shapeRadius > 0){
                holeBorderLayer.path = UIBezierPath(roundedRect: newAreaRect, cornerRadius: CGFloat(currentTaskDimension!.shapeRadius)).cgPath
            }else{
                holeBorderLayer.path = UIBezierPath(rect: newAreaRect).cgPath
            }
        }else{
            holeBorderLayer.path = UIBezierPath(ovalIn: newAreaRect).cgPath
            //holeBorderLayer.path = UIBezierPath(rect: newAreaRect).cgPath
        }
        holeBorderLayer.strokeColor = UIColor.white.cgColor
        holeBorderLayer.fillColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 1.0, 0])
        //rootLayer.addSublayer(holeBorderLayer)
        /*
        messsageLayer.name = "Message"
        //messsageLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMakeRotation(M_PI_2));
        messsageLayer.alignmentMode = CATextLayerAlignmentMode.center
        print("currentTaskDimension!.frameMessage()", currentTaskDimension!.frameMessage())
        messsageLayer.bounds =  currentTaskDimension!.frameMessage()
        messsageLayer.position = currentTaskDimension!.positionMessage()
        messsageLayer.shadowOffset = CGSize(width: 1, height: 1)
        messsageLayer.contentsScale = 2.0
        
        //messsageLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 1.0, 1.0])
        //messsageLayer.borderWidth = 1
        //messsageLayer.borderColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 0.0, 1.0, 1])
        //messsageLayer.shadowOpacity = 0.7
        
        //rootLayer.addSublayer(messsageLayer)
        
        // Layer with the black background
         */
    }
    
    func openPreviewImage(){
        flagConfirmImage = false
        pauseSession()
        print("confirmationPage 2", confirmationPage)
        if(confirmationPage != ""){
            performSegue(withIdentifier: confirmationPage, sender: self)
        }
    }
    
    func restartTask(){
        isFinished = false
        hasExpired = false
        flagFirstTime = false
        blockDetect = false
        startTimer()
    }
    
    func restartProcess(){
        print("restart process")
        isFinished = false
        hasExpired = false
        flagFirstTime = false
        blockDetect = false
        flagShowMessage = true
        reloadTasks()
        
        if(nextTask()){
            print("Saco la primer tarea y la inicio")
            startTask()
        }
        
    }
    
    func processSuccess(){
        self.isFinished = true
    }
    
    func processFail(){
        self.returnToParent()
    }
    
    func resetEvaluation(){
        
    }
    
    func processImage(image: CMSampleBuffer){
        
    }
    
    //let requests: [VNRequest]
    

    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        contador = contador + 1
        if(isFinished){
            return
        }
        var res = contador % 5
        if(currentTask.0.type == .idCapture ){
            res = contador % 10
        }
        if(res == 0){
            if(!blockDetect){
                processImage(image: sampleBuffer)
            }
        }
        
        /*
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let exifOrientation = CGImagePropertyOrientation(rawValue: exifOrientationFromDeviceOrientation().rawValue) else { return }
            var requestOptions: [VNImageOption : Any] = [:]

        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
              requestOptions = [.cameraIntrinsics : cameraIntrinsicData]
            }
            
            // perform image request for face recognition
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: requestOptions)
        
            do {
                
                //imageRequestHandler.perform(<#T##requests: [VNRequest]##[VNRequest]#>)
              try imageRequestHandler.perform(self.requests)
                
            }
            catch {
              print(error)
            }
         */
    }
    
    func getMessage(forKey: String) -> String{
        var key = forKey
        if(key.starts(with: ".")){
            key.removeFirst()
        }
        return Utils.localizedString(forKey: key, defaultTable: "DefaultFaceCapture", alternateTable: self.messagesResource )
    }
    
    func pauseSession () {
        //print("******* Pause session")
        DispatchQueue.main.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    func resumeSession () {
        //print("******* resume session")
        DispatchQueue.main.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    // Return data from child
    func respond(accept : Bool){
        flagConfirmImage = accept
    }
    
    func pauseWhileValidate(){
        self.blockDetect = true
        stopTimer()
    }
    
    func restartAfterValidate(){
        self.blockDetect = false
    }
    
    func shutdown(){
        lottieOk.hide()
        lottieFail.hide()
        isFinished = true
        pauseSession()
        stopTimer()
    }
    
    // INTRO
    private var rotated = false
    
    @IBAction func selectHelpAction(_ sender: Any) {
        selectHelp()
    }
    
    @IBAction func confirmRotateAction(_ sender: Any) {
        confirmRotate()
    }
    
    @IBAction func back(_ sender: Any) {
        onPressBack()
    }
    
    func onPressBack(){
        print("showIntro", showIntro)
        print("introIsVisible", introIsVisible)
        print("blockDetect", blockDetect)
        if(self.showIntro && !introIsVisible){
            cancelTask()
            launch.showView()
            introIsVisible = true
        }else{
            stopTimer()
            self.navigationController?.popViewController(animated: true)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func switchSideview(){
        if(self.selectedSideView == .frontOrBack){
            rotated = !rotated
            self.selectedSideView = .backOrFront
        }else{
            if(self.selectedSideView == .backOrFront){
                rotated = !rotated
                self.selectedSideView = .frontOrBack
            }
        }
    }
    
    func confirmRotate() {
        
        var title = "Cámara Trasera"
        var side = "trasera"
        var message = "¿ Deseas rotar a la cámara \(side) ?"
        
        if(self.selectedSideView == .backOrFront){
            title = "Cámara Frontal"
            side = "frontal"
            message = "¿ Deseas rotar a la cámara \(side) ?"
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: UIAlertAction.Style.cancel, handler: { _ in
            //Cancel Action
        }))
        alert.addAction(UIAlertAction(title: "Rotar",
                                      style: UIAlertAction.Style.default,  //destructive
                                      handler: {(_: UIAlertAction!) in
            //Sign out action
            self.switchSideview()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func selectHelp() {
        if(enableVideoHelp  && enableTroubleshootHelp){
            
            let alert = UIAlertController(title: "Ayuda", message: "Selecciona la mejor opción para ayudarte en tu prueba", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Video de explicación", style: .default, handler: { (_) in
                // OpenVideo
            }))
            
            alert.addAction(UIAlertAction(title: "Instrucciones y dudas", style: .default, handler: { (_) in
                // OpenHelpeView
            }))
            
            alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: { (_) in
                // OpenHelpeView
            }))
            self.present(alert, animated: true, completion: nil)
        }else{
            if(!enableVideoHelp  && enableTroubleshootHelp){
                // OpenHelpeView
            }else{
                if(enableVideoHelp  && !enableTroubleshootHelp){
                    // OpenVideo
                }
            }
        }
    }
    
    func setupBarButtons(){
        
        navigationItem.rightBarButtonItems = []
        
        if(enableVideoHelp  || enableTroubleshootHelp){
            let help = UIBarButtonItem(image: UIImage(systemName: "questionmark.circle.fill"), style: .plain ,target: self, action: #selector(selectHelpAction))
            navigationItem.rightBarButtonItems?.append(help)
        }
        
        if(allowManualSideView){
            let rotateCamera = UIBarButtonItem(image: UIImage(systemName: "arrow.triangle.2.circlepath.camera") , style: .plain , target: self, action: #selector(confirmRotateAction))
            navigationItem.rightBarButtonItems?.append(rotateCamera)
        }
        self.navigationItem.hidesBackButton = true

        let newBackButton = UIBarButtonItem(title: "Back", style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.back(_:)))
        self.navigationItem.leftBarButtonItem = newBackButton
        
    }
    
    func startProcess(){
        startTask()
    }
    
    func setupIntro(){
        introIsVisible = true
        launch.onClose(fn: {
            self.introIsVisible = false
            self.blockDetect = false
            self.startProcess()
        })
        launch.backgroundColor = .red
        launch.frame = view.bounds
        self.view.addSubview(launch)
    }
    
    func updateMessage(code: String){
        if(!flagShowMessage){
            return
        }
        var msg = ""
        var modeColor = "white"
        var borderColor = modeColor
        var textColor = modeColor
        var modeTextColor = textColor
        if traitCollection.userInterfaceStyle == .light {
            modeColor = "darkBlue"
            modeTextColor = "#223874"
            textColor = "#223874" // "darkgray"
        } else {
            modeColor = "white"
        }
        
        let taskConfiguration = (currentTask.0)
        
        print("update mensaje", code)
        var exist = false
        var mssg: Message?
        for message in taskConfiguration.messages {
            if(message.id == code){
                exist = true
                mssg  = message
                print("existe")
            }else{
                print("no existe")
            }
        }

        if(exist){
            //print("existe keep")
            //print(mssg!)
            print("amilcar")
            print(mssg!)
            if(mssg!.msg.contains("nbm")){
                print("lo buscare en mis mensajes")
                print(mssg!.msg)
                msg = getMessage(forKey: mssg!.msg)
                print("dinamico")
                print(msg)
            }else{
                msg = mssg!.msg
            }
            if(mssg!.textColor != nil && mssg!.textColor!.contains("modeTextColor")){
                textColor = modeTextColor
            }else{
                if(mssg!.textColor != nil && mssg!.textColor!.contains("modeColor")){
                    textColor = modeColor
                }else{
                    textColor = mssg!.textColor!
                }
            }
            if(mssg!.borderColor != nil && mssg!.textColor!.contains("modeColor")){
                borderColor = modeColor
            }
                
                
        }else{
            //print("no mando ningun mensaje y limpio")
        }
        
        holeBorderLayer.strokeColor = getColor(name: borderColor).cgColor

        let styles:[String:String] = ["message-capture":"color: %@;font-family: -apple-system;font-size:24px;font-weight:bold;"]
        var style: String? = styles["message-capture"]

        if(textColor != "white" && !textColor.starts(with: "#")){
            textColor = "-apple-system-"+textColor
        }else{
            
        }
        style = String(format: style!, textColor)

        let mesgFormatted = msg.splitHtml(every: 20, sep: "<br/>")
        messsageLayer.string = mesgFormatted.htmlAttributedString(style: (style)!)
    }
    
    
    func updateMessageWait(code: String, after: Int){
        blockDetect = true
        updateMessage(code: code)
        flagShowMessage = false
        let t = DispatchTime.now() + Double(after)
        DispatchQueue.main.asyncAfter(deadline: t ) {
            self.flagShowMessage = true
            self.blockDetect = false
            self.updateMessage(code: "start")
        }
    }

    
    func getColor(name:String) -> UIColor{
        switch name{
            case "orange":
                return .systemOrange
            case "yellow":
                return .systemYellow
            case "white":
                return .white
            case "black":
                return .black
            case "teal":
                return .systemTeal
            case "green":
                return .systemGreen
            case "red":
                return .systemRed
            case "blue":
                return .systemBlue
            case "darkBlue":
                return UIColor(rgb: 0x223874)
            case "gray":
                return .systemGray
            case "darkGray":
                return .darkGray
            default:
                return .systemBlue
        }
    }
    
}
