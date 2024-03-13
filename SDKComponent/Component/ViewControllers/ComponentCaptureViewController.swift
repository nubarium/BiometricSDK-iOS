//
//  FaceCameraViewController.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 20/01/23.
//  Copyright © 2023 Nuabrium SA de CV. All rights reserved.
//
import UIKit
import AVFoundation
import MLKitFaceDetection
//import MLKitTextRecognition
import MLKitVision
import QuartzCore
import CoreMedia
import Vision

class ComponentCaptureViewController: CommonCaptureViewController {
    
    // Face elements
    var faceCaptureOptions : FaceCaptureOptions = FaceCaptureOptions()
    private var faceCaptureResponse : FaceCaptureResponse = FaceCaptureResponse()

    private var lastFaceFeatures: FaceFeaturesModel?
    private var lastValidateFace: ValidateFaceModel?

    // Face
    let faceDetectorOptions = FaceDetectorOptions()
    var faceDetector = FaceDetector.faceDetector()
    var bestFace : FaceDetail?
    var bestDocument : [String: IdDetail]?
    
    private let maxNumFacesOk = 25
    private let faceEvaluation = FaceEvaluation()
    private var counterStaticEye = 0

    private var flagFaceCheckFeatures = false
    private var statusFaceCheckFeatures: StatusRequest = .notStarted
    private var statusValidateFace: StatusRequest = .notStarted

    // Id Elements
    private var idCaptureResponse : IdCaptureResponse = IdCaptureResponse()
    var idCaptureOptions : IdCaptureOptions = IdCaptureOptions()
    
    private var lastIdFeatures: IdFeaturesModel?
    private var lastValidateId: ValidateIdModel?
    
    private var flagIdCheckFeatures = false
    private var statusIdCheckFeatures: StatusRequest = .notStarted
    private var statusValidateId: StatusRequest = .notStarted
    
    private let idEvaluation = IdEvaluation()
    //private var idCaptureResponse : IdCaptureResponse = IdCaptureResponse()

    
    // Id
    // Public properties
    let component : SDKComponent = .faceCapture
    var componentHelper: ComponentHelper?

    private var counterFail = 0
    private var countResets = 0
    
    override func viewDidLoad() {
        
        confirmationPage = "goToConfirmation"
                
        self.enableVideoHelp = self.sdkComponent!.enableVideoHelp
        self.enableTroubleshootHelp = self.sdkComponent!.enableTroubleshootHelp
                        
        // Setup position previuos of loading
        setupSideView(sideView: sdkComponent!.sideView)
        super.viewDidLoad()
                
        self.selectedSideView = self.sdkComponent!.sideView
        self.showIntro = self.sdkComponent!.showIntro
        self.messagesResource = self.sdkComponent!.messagesResource
        self.allowManualSideView = self.sdkComponent!.allowManualSideView
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (component == .faceCapture) {
            updateMessage(code: "clear")
        }
        if (component == .idCapture) {
            updateMessage(code: "clear")
        }
        if (component == .videoRecorder) {
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("confirmationPage 1", confirmationPage)
        if segue.identifier == confirmationPage {
            if(component == .faceCapture){
                let destinationVC = segue.destination as! PreviewFaceViewController
                destinationVC.faceDetail = self.bestFace
                destinationVC.delegate = self
            }
            if(component == .idCapture){
                let destinationVC = segue.destination as! PreviewIdViewController
                destinationVC.documentDetail = self.bestDocument
                destinationVC.delegate = self
            }
        }
    }
    
    override func returnToParent(){
        // Return face capture to top
        print("faceresponse", faceCaptureResponse.faceCaptureResult.result)
        print("idresponse", idCaptureResponse.result.result)
        if ( faceCaptureResponse.faceCaptureResult.result != "unevaluated" ){ //( component == .faceCapture ) {
            print("respondo facecpature")
            self.delegate?.respond(response: faceCaptureResponse, component: .faceCapture)
        }
        print("idresponse", idCaptureResponse.result.result)
        if ( idCaptureResponse.result.result != "unevaluated" ) { //component == .idCapture ) {
            print("respondo idcapture")
            self.delegate?.respond(response: idCaptureResponse, component: .idCapture)
        }
        if ( component == .videoRecorder ) {
            self.delegate?.respond(response: faceCaptureResponse, component: .videoRecorder)
        }
        super.returnToParent()
    }
        
    override func onPressBack(){
        super.onPressBack()
    }
    
    override func setupMl(){
        if(component == .faceCapture || component == .videoRecorder){
            //CONTOUR_MODE_NONE
            faceDetectorOptions.landmarkMode = .none
            faceDetectorOptions.classificationMode = .all
            faceDetectorOptions.performanceMode = .fast
            faceDetectorOptions.contourMode = .none
            //options.minFaceSize
            faceDetectorOptions.minFaceSize = CGFloat(0.45)
            // [END config_face]
            faceDetector = FaceDetector.faceDetector(options: faceDetectorOptions)
        }
    }
    
    override func setupArea(){
        // Task: Face
        if(!nextTask()){
            print("Cant setup area cause no tasks")
        }
        super.setupArea()
    }

    override func startTask() {
        super.startTask()
        if(currentTask.0.type == .faceCapture ){
            faceEvaluation.reset()
            statusFaceCheckFeatures = .notStarted
            counterStaticEye = 0
        }
        if(currentTask.0.type == .idCapture ){
            idEvaluation.reset()
        }
        countResets = 0
        counterFail = 0
    }
    
    override func restartProcess() {
        super.restartProcess()
        // Face component
        faceEvaluation.reset()
        statusFaceCheckFeatures = .notStarted
        counterStaticEye = 0
        
        // Id Component
        idEvaluation.reset()
        
        
        /*if(currentTask.0.type == .faceCapture ){
            faceEvaluation.reset()
            statusFaceCheckFeatures = .notStarted
            counterStaticEye = 0
        }
        if(currentTask.0.type == .idCapture ){
            idEvaluation.reset()
        }*/
    }
    
    override func restartTask() {
        super.restartTask()
        updateMessage(code: "clear")

        if(currentTask.0.type == .faceCapture ){
            faceEvaluation.reset()
            statusFaceCheckFeatures = .notStarted
            counterStaticEye = 0
        }
        if(currentTask.0.type == .idCapture ){
            idEvaluation.reset()
        }
        countResets = 0
        counterFail = 0
    }

    override func cancelTask() {
        super.cancelTask()
    }
    
    override func completeTask() {
     
        //super.completeTask()
        blockDetect = true
        
        currentTaskStatus = .completed
        print("^^^ 1")
        // Si ya finalizo el proceso, procedo de acuerdo a al configuracion
        if(currentTaskConfiguration?.orientation == .landscape){
            self.orientation = .landscapeLeft
        }
        if(currentTaskConfiguration?.orientation == .portrait){
            self.orientation = .portrait
        }
        
        print("currentTaskConfiguration", currentTaskConfiguration!)
        print("component", component)
        
       
        
        print("^^^ 2")
        DispatchQueue.main.async {
            self.lottieOk.show()
             // Any other UI updates go here
         }
        
        
        print("^^^ 3")
        if( !nextTask() ){
            print("^^^ 5")
            if(self.sdkComponent!.showPreview){
                print("^^^ 6")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    print("^^^ 7")
                    //self.openPreviewImage()
                    self.returnToParent()
                }
            }else{
                print("^^^ 8")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.returnToParent()
                }
            }
        }else{
            print("^^^ 9")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                print("^^^ 10")

                self.resetupArea()
                self.startTask()
            }
        }
        
    
    }
    
    override func evaluateProcess(){
        super.evaluateProcess()
    }
    
    
    override func resetEvaluation(){
        self.countResets += 1
        if(currentTask.0.type == .faceCapture ){
            self.faceEvaluation.reset()
        }
        if(currentTask.0.type == .idCapture ){
            self.idEvaluation.reset()
        }
    }
    
    override func processSuccess() {
        super.processSuccess()
        
        if(currentTask.0.type == .faceCapture ){
            processSuccessFace()
        }
        if(currentTask.0.type == .idCapture ){
            processSuccessId()
        }
    }
    
    func processSuccessFace(){
        //self.updateMessageFace(code: .success)
        self.updateMessage(code: "success")

        // Append the last know retro features
        let features : [String] = retroFaceFeatures()
        var outputRetro:[String] = []
        //outputRetro.append(contentsOf: retro)
        outputRetro.append(contentsOf: features)
        
        self.faceCaptureResponse = FaceCaptureResponse()
        self.faceCaptureResponse.responseEventType = .success
        self.faceCaptureResponse.faceCaptureResult.result = lastValidateFace!.result!
        self.faceCaptureResponse.faceCaptureResult.confidence = lastValidateFace!.confidence!
        self.faceCaptureResponse.faceCaptureReasonFail = .none
        self.faceCaptureResponse.faceCaptureReasonError = .none
        self.faceCaptureResponse.faceCaptureResult.retro = outputRetro
        self.faceCaptureResponse.area = (self.bestFace?.areaImage())!
        self.faceCaptureResponse.face = (self.bestFace?.faceImage())!
        self.faceCaptureResponse.frame = (self.bestFace?.frameImage())!
        
        self.completeTask()
    }

    func processSuccessId(){
        //self.updateMessageFace(code: .success)
        //self.updateMessage(code: "success")

        // Append the last know retro features
        let features : [String] = []     // retroIdFeatures()
        var outputRetro:[String] = []
        //outputRetro.append(contentsOf: retro)
        outputRetro.append(contentsOf: features)
        
        //self.idCaptureResponse = IdCaptureResponse()
        self.idCaptureResponse.responseEventType = .success
        self.idCaptureResponse.result.result = "pass" //lastValidateFace!.result!
        self.idCaptureResponse.result.confidence = 1.0 // lastValidateFace!.confidence!
        self.idCaptureResponse.result.retro = outputRetro
        self.idCaptureResponse.reasonFail = .none
        self.idCaptureResponse.error = .none
        
        //let image : UIImage = self.idEvaluation.bestFace().frameImage()
        
        //self.idCaptureResponse.front = image //(self.bestDocument?["front"]!.documentImage())!
        //self.idCaptureResponse.back = image //(self.bestDocument?["back"]!.documentImage())!
     
        self.completeTask()
    }
    
    func processFailFace(retro: [String], faceCaptureReasonFail: FaceCaptureReasonFail, score: Double){
        
        // Append the last know retro features
        var outputRetro:[String] = []
        outputRetro.append(contentsOf: retro)
        if(faceCaptureReasonFail !=  FaceCaptureReasonFail.timeout){
            let features : [String] = retroFaceFeatures()
            outputRetro.append(contentsOf: features)
        }
        
        self.faceCaptureResponse = FaceCaptureResponse()
        self.faceCaptureResponse.responseEventType = .fail
        self.faceCaptureResponse.faceCaptureResult.result = "fail"
        self.faceCaptureResponse.faceCaptureResult.confidence = score
        self.faceCaptureResponse.faceCaptureReasonFail = faceCaptureReasonFail
        self.faceCaptureResponse.faceCaptureResult.retro = outputRetro
        
        
        self.lottieFail.show()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.processFail()
        }
    }
    
    override func processImage(image: CMSampleBuffer){
        if(currentTask.0.type == .idCapture ){
            detectId(sampleBuffer: image)
        }
        if(currentTask.0.type == .faceCapture ){
            detectFace(sampleBuffer: image)
        }
    }
    
    func detectId(sampleBuffer: CMSampleBuffer){
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let image = UIImage(pixelBuffer: pixelBuffer!)
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer!, orientation: .left ) // .right
        let idDetector: IdDetector = IdDetector(area: self.areaRectScale)
        
        let recognizeTextRequest = VNRecognizeTextRequest { (request, error) in
            if(error == nil){
                let idDetail = idDetector.process(request: request, image: image!)
                if(idDetail == nil){
                    print("Es nulo, no hay ID")
                }else{
                    print("Id Detectado", idDetail)
                    if(self.blockDetect == false){
                        print("1")
                        if(self.idEvaluation.count() < 3){
                            print("2")
                            self.idEvaluation.addId(id: idDetail!)
                        }else{
                            print("3")
                            self.blockDetect = true
                            self.validateIdRequest()
                            //let str = self.idEvaluation.bestFace().frameImage().convertImageToBase64String()
                            //print(str)
                        }
                    }else{
                        print("4")
                        //print("ignoro")
                    }
                }
            }
        }
        recognizeTextRequest.recognitionLevel = .accurate

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([recognizeTextRequest])
            } catch {
                print(error)
            }
        }
    }

    func validateIdRequest(){
        print("*** validateIdRequest")
        pauseWhileValidate()
        print("*** validateIdRequesasdadadst")
        
        DispatchQueue.main.async {
            LoadingOverlay.shared.showOverlay()
            // Any other UI updates go here
        }
        
           
        
        print("*** 1")
        //self.idEvaluation.bestFace().frameImage().convertImageToBase64String()
        let image : UIImage = self.idEvaluation.bestFace().frameImage()
        print("*** 2")
        guard let imageData = image.jpegData(compressionQuality: 0.50) else { return  }
        print("*** 3")
        let img = UIImage(data: imageData)
        print("*** 4")
        print("conteo", tasksToDo.all().count)
        if(tasksToDo.all().count == 1){
            self.idCaptureResponse.front = img!
        }else{
            self.idCaptureResponse.back = img!
        }
        pauseWhileValidate()
        pauseWhileValidate()
        DispatchQueue.main.async {
            LoadingOverlay.shared.hideOverlayView()
            // Any other UI updates go here
        }
        
        // Completa la tarea internamente y en caso
        processSuccessId();
        
        
        //let strImage = "data:image/jpeg;base64," +  img!.convertImageToBase64String()
        //print(strImage)
        //self.processSuccessId()
        print("*** completo tarea")
        //self.completeTask()
        print("*** siguiente tarea")
        
       
        
       
        /*
        let apiRequest = ServiceSdk.validateFace(id: requestId, face: strImage, level: AntispoofingLevel.medium, allow: [], deny: [], order: [])
        apiRequest.start()
        statusValidateFace = .started
        apiRequest.onSuccess { entity in
            self.statusValidateFace = .completed
            
            LoadingOverlay.shared.hideOverlayView()
            
            let response:ValidateFaceModel = (entity.content as! ValidateFaceModel)
            print("response validate", response)
            if(response.status.lowercased() == "ok"){
                if(response.features != nil){
                    self.lastFaceFeatures = response.features
                }
                if(response.result?.lowercased() == "pass" || response.result?.lowercased() == "warning"){
                    self.lastValidateFace = response
                    self.processSuccessFace()
                }else{
                    self.counterFail += 1
                    //low_evaluation, facemask_not_allowed, glasses_not_allowed, no_face
                    self.processFailFace(retro: self.retroFaceFeatures(), faceCaptureReasonFail: FaceCaptureReasonFail.livenessFail, score: response.confidence!)
                }
            }else{
                self.lastValidateFace = response
                self.statusValidateFace = .failed
            }
        }
        apiRequest.onFailure { error in
            self.statusValidateFace = .failed
            print("hard error", error)
            LoadingOverlay.shared.hideOverlayView()
        }
        */
    }
    
    
    func detectFace(sampleBuffer: CMSampleBuffer) {
        let faceProcessor: FaceProcessor = FaceProcessor(area: self.areaRectScale)
        //faceProcessor.processAsync(sampleBuffer: sampleBuffer, processFace)
        faceProcessor.processAsync(sampleBuffer: sampleBuffer, {
            faces, sampleBuffer, error  in
            
            if(error == nil){

                if(self.blockDetect == false){
                    self.parseFaceDetail(faces: faces, image: sampleBuffer)
                }else{

                }
            }else{

            }
            
        })
    }
    
    func parseFaceDetail(faces: [FaceDetail], image: CMSampleBuffer){
        if faces.count == 0 {
            if(self.hasExpired){
                self.isFinished = true
                self.updateMessage(code: "expired")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    var retro: [String] = []
                    if(self.counterStaticEye > 0){
                        retro = ["static_eye"]
                    }
                    self.processFailFace(retro: retro, faceCaptureReasonFail: .timeout, score: 0.0)
                }
            }else{
                self.updateMessage(code: "noFace")
                self.resetEvaluation()
            }
            return
        }
        if faces.count > 2 {
            if(self.hasExpired){
                self.isFinished = true
                self.updateMessage(code: "expired")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    var retro: [String] = ["many_faces"]
                    if(self.counterStaticEye > 0){
                        retro.append("static_eye")
                    }
                    self.processFailFace(retro: retro, faceCaptureReasonFail: .timeout, score: 0.0)
                }
            }else{
                self.updateMessage(code: "manyFaces")
                self.resetEvaluation()
            }
            return
        }
        // Faces detected
        faces.forEach { face in
            let faceDetail = faces[0]
            if(faceDetail.isValid()){
                if(faceDetail.isInside()){
                    if(self.faceEvaluation.count()==10 && self.statusFaceCheckFeatures == .notStarted ){ // self.flagCheckFeatures == false
                        print("Check Features Thread")
                        self.bestFace = self.faceEvaluation.bestFace()
                        self.checkFaceFeatures()
                        self.flagFaceCheckFeatures = true
                        return
                    }
                    
                    self.faceEvaluation.addFace(face: faceDetail)
                    if(self.faceEvaluation.count() >= self.maxNumFacesOk){
                        var isBlinking = true
                        if(self.sdkComponent!.livenessRequired){
                            isBlinking = self.faceEvaluation.isBlinking()
                        }
                        if(isBlinking){
                            self.bestFace = self.faceEvaluation.bestFace()
                            self.validateFaceRequest()
                        }else{
                            self.counterFail += 1
                            if(self.counterFail > self.sdkComponent!.maxValidations){
                                self.isFinished = true
                                self.updateMessage(code: "maxValidations")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    self.processFailFace(retro: ["static_eye"], faceCaptureReasonFail: .maxValidationsExceeded, score: 0.0)
                                }
                            }else{
                                if(self.hasExpired){
                                    self.isFinished = true
                                    self.updateMessage(code: "expired")
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        self.processFailFace(retro: ["static_eye"], faceCaptureReasonFail: .timeout, score: 0.0)
                                    }
                                }else{
                                    self.counterStaticEye += 1
                                    self.updateMessage(code: "staticEye")
                                    self.resetEvaluation()
                                }
                            }
                        }
                    }else{
                        self.updateMessage(code: "keep")
                        return
                    }
                }
            }else{
                // return if exired
                if(self.hasExpired){
                    self.isFinished = true
                    self.updateMessage(code: "expired")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        var retro: [String] = []
                        if(self.counterStaticEye > 0){
                            retro = []
                        }
                        self.processFailFace(retro: retro, faceCaptureReasonFail: .timeout, score: 0.0)
                    }
                }else{
                    //Keep trying if hasnt expired
                    self.resetEvaluation()
                    if(faceDetail.isInside()){
                        if(faceDetail.tooFar()){
                            self.updateMessage(code: "farAway")
                            //print("Es INVALIDO y esta DENTRO pero esta muy LEJOS")
                        }else{
                            if(faceDetail.tooClose()){
                                self.updateMessage(code: "tooClose")
                                //print("Es INVALIDO y esta DENTRO pero esta muy CERCA")
                            }else{
                                if(faceDetail.pose() == .left || faceDetail.pose() == .right){
                                    self.updateMessage(code: "align")
                                }else{
                                    self.updateMessage(code: "unknown")
                                }
                                //print("Es INVALIDO y esta DENTRO y de TAMANO CORRECTO")
                            }
                        }
                    }else{
                        self.updateMessage(code: "outbounds")
                        //print("Es INVALIDO y esta FUERA")
                    }
                }
            }
        }
    }
    
    func checkFaceFeatures(){
        DispatchQueue.main.async {
            self.checkFaceFeaturesRequest()
        }
    }
    
    func validateFaceRequest(){
        pauseWhileValidate()
        LoadingOverlay.shared.showOverlay()
        let image : UIImage = (self.bestFace!).areaImage()
        guard let imageData = image.jpegData(compressionQuality: 0.50) else { return  }
        let img = UIImage(data: imageData)
        let strImage = "data:image/jpeg;base64," +  img!.convertImageToBase64String()
        
        let apiRequest = ServiceSdk.validateFace(id: requestId, face: strImage, level: AntispoofingLevel.medium, allow: [], deny: [], order: [])
        apiRequest.start()
        statusValidateFace = .started
        apiRequest.onSuccess { entity in
            self.statusValidateFace = .completed
            
            LoadingOverlay.shared.hideOverlayView()
            
            let response:ValidateFaceModel = (entity.content as! ValidateFaceModel)
            print("response validate", response)
            if(response.status.lowercased() == "ok"){
                if(response.features != nil){
                    self.lastFaceFeatures = response.features
                }
                if(response.result?.lowercased() == "pass" || response.result?.lowercased() == "warning"){
                    self.lastValidateFace = response
                    self.processSuccessFace()
                }else{
                    self.counterFail += 1
                    //low_evaluation, facemask_not_allowed, glasses_not_allowed, no_face
                    self.processFailFace(retro: self.retroFaceFeatures(), faceCaptureReasonFail: FaceCaptureReasonFail.livenessFail, score: response.confidence!)
                }
            }else{
                self.lastValidateFace = response
                self.statusValidateFace = .failed
            }
        }
        apiRequest.onFailure { error in
            self.statusValidateFace = .failed
            print("hard error", error)
            LoadingOverlay.shared.hideOverlayView()
        }
    }
    
    func checkFaceFeaturesRequest(){
        LoadingOverlay.shared.showOverlay()
        let image : UIImage = (self.bestFace!).areaImage()
        guard let imageData = image.jpegData(compressionQuality: 0.70) else { return }
        let img = UIImage(data: imageData)
        let strImage = "data:image/jpeg;base64," +  img!.convertImageToBase64String()
        
        let apiRequest = ServiceSdk.checkFaceFeatures(id: requestId, face: strImage)
        apiRequest.start()
        statusFaceCheckFeatures = .started
        apiRequest.onSuccess { entity in
            self.statusFaceCheckFeatures = .completed
            self.lastFaceFeatures = (entity.content as! FaceFeaturesModel)
            
            //if(self.lastFaceFeatures!.status!.lowercased() == "ok"){
            self.validateFaceFeatures(faceFeatures: self.lastFaceFeatures!)
            //}else{
            
            //}
            LoadingOverlay.shared.hideOverlayView()
        }
        apiRequest.onFailure { error in
            self.statusFaceCheckFeatures = .failed
            print("hard error", error)
            LoadingOverlay.shared.hideOverlayView()
        }
    }
    
    func validateFaceFeatures(faceFeatures: FaceFeaturesModel) {//}-> [FaceCaptureFeature]{
        //print("faceFeatures", faceFeatures)
        if(faceFeatures.status == "error" ){
            self.statusFaceCheckFeatures = .failed
            print("soft error","Do nothing cheking features and avoid to check")
        }else{
            flagFaceCheckFeatures = true
            var features : [String] = []
            if(faceFeatures.has_glasses != nil && faceFeatures.has_glasses!){
                features.append("glasses")
            }
            if(faceFeatures.has_hat != nil && faceFeatures.has_hat!){
                features.append("hat")
            }
            if(faceFeatures.has_mask != nil && faceFeatures.has_mask!){
                features.append("mask")
            }
            if(faceFeatures.has_facemask != nil && faceFeatures.has_facemask!){
                features.append("facemask")
            }
            if(faceFeatures.blur != nil && faceFeatures.blur! < 60){
                features.append("veryBlurred")
            }
            if(faceFeatures.blur != nil && faceFeatures.blur! < 100){
                features.append("blurred")
            }
            var failed:[FaceCaptureFeature] = []
            if features.count>0 {
                
                for feature:FaceCaptureFeature in faceCaptureOptions.deny{
                    if(features.contains(feature.description)){
                        failed.append(feature)
                        if(feature.description == "glasses"){
                            //updateMessageFaceWait(code: .hasGlasses ,after: 3)
                            updateMessageWait(code: "hasGlasses" ,after: 3)
                        }else{
                            if(feature.description == "facemask"){
                                //updateMessageFaceWait(code: .hasFacemask,after: 3)
                                updateMessageWait(code: "hasFacemask",after: 3)
                            }else{
                                if(feature.description == "mask"){
                                    //updateMessageFaceWait(code: .hasMask, after: 3)
                                    updateMessageWait(code: "hasMask", after: 3)
                                }else{
                                    if(feature.description == "hat"){
                                        //updateMessageFaceWait(code: .hasHat, after: 3)
                                        updateMessageWait(code: "hasHat", after: 3)
                                    }else{
                                        if(feature.description == "blurred"){
                                            //updateMessageFaceWait(code: .blurred, after: 3)
                                            updateMessageWait(code: "blurred", after: 3)
                                        }else{
                                            if(feature.description == "veryBlurred"){
                                                //updateMessageFaceWait(code: .veryBlurred, after: 3)
                                                updateMessageWait(code: "veryBlurred", after: 3)
                                            }else{
                                                //updateMessageFaceWait(code: .notClearFace, after: 3)
                                                updateMessageWait(code: "notClearFace", after: 3)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        self.resetEvaluation()
                    }
                }
            }
        }
        //return failed
    }
    
    private func retroIdFeatures() -> [String]{
        var features : [String] = []
        if(lastFaceFeatures!.has_glasses != nil && lastFaceFeatures!.has_glasses!){
            features.append("has_glasses")
        }
        if(lastFaceFeatures!.has_hat != nil && lastFaceFeatures!.has_hat!){
            features.append("has_hat")
        }
        if(lastFaceFeatures!.has_mask != nil && lastFaceFeatures!.has_mask!){
            features.append("has_mask")
        }
        if(lastFaceFeatures!.has_facemask != nil && lastFaceFeatures!.has_facemask!){
            features.append("has_facemask")
        }
        if(lastFaceFeatures!.blur != nil && lastFaceFeatures!.blur! < 60){
            features.append("very_blurred")
        }
        if(lastFaceFeatures!.blur != nil && lastFaceFeatures!.blur! < 100){
            features.append("blurred")
        }
        return features
    }
    
    private func retroFaceFeatures() -> [String]{
        var features : [String] = []
        if(lastFaceFeatures!.has_glasses != nil && lastFaceFeatures!.has_glasses!){
            features.append("has_glasses")
        }
        if(lastFaceFeatures!.has_hat != nil && lastFaceFeatures!.has_hat!){
            features.append("has_hat")
        }
        if(lastFaceFeatures!.has_mask != nil && lastFaceFeatures!.has_mask!){
            features.append("has_mask")
        }
        if(lastFaceFeatures!.has_facemask != nil && lastFaceFeatures!.has_facemask!){
            features.append("has_facemask")
        }
        if(lastFaceFeatures!.blur != nil && lastFaceFeatures!.blur! < 60){
            features.append("very_blurred")
        }
        if(lastFaceFeatures!.blur != nil && lastFaceFeatures!.blur! < 100){
            features.append("blurred")
        }
        return features
    }

}
