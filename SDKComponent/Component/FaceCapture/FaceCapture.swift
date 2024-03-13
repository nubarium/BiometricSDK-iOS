//
//  FaceCapture.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 30/01/23.
//  Copyright © 2023 Nuabrium SA de CV. All rights reserved.
//
import UIKit
import Device
import AVFoundation

class FaceCapture:  SdkComponent, CameraViewControllerDelegate  {
    
    // View Controller Reference
    private var requestId: String = ""
    
    private var identifier : String = ""
    private var allow : [FaceCaptureFeature] = []
    private var deny : [FaceCaptureFeature] = []
    private var order : [FaceCaptureFeature] = []

    private var faceCaptureResponse: FaceCaptureResponse = FaceCaptureResponse()
    private var faceCaptureReasonFail: FaceCaptureReasonFail?
    private var reasonFail: String = ""
    private var faceCaptureReasonError: FaceCaptureReasonError?
    private var errorMessage: String = ""
    private var started: Bool = false
    private var position: AVCaptureDevice.Position = .front
    
    private var status: ComponentStatus = .created
    private var tasks: [Task] = []
    
    var allowCaptureOnFail : Bool = false
    
    // Public event listeners
    var onSuccess: ((_: FaceCaptureResult, _: UIImage, _: UIImage, _: UIImage )->Void)?
    var onFail: ((_: FaceCaptureResult, _: FaceCaptureReasonFail, _: String )->Void)?
    var onError: ((_: FaceCaptureReasonError, _: String)->Void)?
    // Public initialize events
    var onLoad: ((_: String)->Void)?
    var onInitError: ((_: FaceCaptureInitError, _: String)->Void)?
    
    // Custom validator
    private var customValidator: ((_: FaceCapturePreview)->Void)?
    private func throwResponse(responseType: ResponseEventType){
    }
    
    //private var tasksToDo: Queue<TaskConfiguration> = Queue<TaskConfiguration>()
    
    override init(viewController : UIViewController){
        super.init(viewController: viewController)
        self.identifier = "ComponentCapture"
        self.allowManualSideView = false
        
        //print("self.configuration", self.configuration)
        
        //var component
        for line in self.configuration!.components{
            if (line.type == .faceCapture) {
                print("Tasks", line.tasks)
                tasks = line.tasks
            }
        }
    }
    
    private func validateParameters(){
        let frontCameras = getListOfCameras(position: .front)
        let backCameras = getListOfCameras(position: .back)
        
        if(sideView == .front){
            position = .front
        }else{
            if(sideView == .frontElseBack){
                if(frontCameras.count > 0){
                    position = .front
                }else{
                    if(backCameras.count > 0){
                        position = .back
                    }else{
                        // error
                    }
                }
            }else{
                if(sideView == .frontOrBack){
                    if(frontCameras.count>0 && backCameras.count>0){
                        allowManualSideView = true
                    }
                    if(frontCameras.count > 0){
                        position = .front
                    }else{
                        if(backCameras.count > 0){
                            position = .back
                        }else{
                            // error
                        }
                    }
                }else{
                    if(sideView == .back){
                        position = .back
                    }else{
                        if(sideView == .backElseFront){
                            if(backCameras.count > 0){
                                position = .back
                            }else{
                                if(frontCameras.count > 0){
                                    position = .front
                                }else{
                                    // error
                                }
                            }
                        }else{
                            if(sideView == .backOrFront){
                                if(frontCameras.count>0 && backCameras.count>0){
                                    allowManualSideView = true
                                }
                                if(backCameras.count > 0){
                                    position = .back
                                }else{
                                    if(frontCameras.count > 0){
                                        position = .front
                                    }else{
                                        // error
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func recoverRequestId() -> String{
        self.requestId = ""
        let defaults = UserDefaults.standard
        let code = (String(describing: self)).snakeCased()!
        if let id = defaults.string(forKey: code + ".request_id") {
            print("recover request id", id)
            self.requestId = id
        }
        return self.requestId
    }
    
    private func saveRequestId(){
        let defaults = UserDefaults.standard
        let code = (String(describing: self)).snakeCased()!
        defaults.setValue(requestId, forKey: code + ".request_id")
        defaults.synchronize()
    }
    
    private func validateRequest(){
        let dInfo = UIDevice.deviceInfo
        let version = ComponentInfo.version.description
        print("dInfo", dInfo)
        //let _info = ["ios": dInfo]
        let apiRequest = ServiceSdk.validateToken(token: requestId, device: dInfo["id"] as! String, force_request: true, component: "bf", version: version)
        apiRequest.start()
        apiRequest.onSuccess { entity in
            let data:ValidateTokenModel = (entity.content as! ValidateTokenModel)
            print("ValidateTokenModel", data)
            if(data.status.lowercased()=="ok" || data.status.lowercased()=="valid"){
                self.onLoad!(self.requestId)
            }else{
                if(data.message == "accountLocked"){
                    self.onInitError!(.accountLocked, "User account ("  + self.username + ") locked.")
                }else{
                    if(data.message == "userDisabled"){
                        self.onInitError!(.userDisabled, "User account ("  + self.username + ") disabled.")
                    }else{
                        if(data.message == "invalid_device" || data.message == "invalidDevice"){
                            self.authAndCreateRequest()
                        }else{
                            // Falta homologar server y cliente
                            self.onInitError!(.unknown, data.message)
                        }
                    }
                }
            }
        }
        apiRequest.onFailure { error in
            if error.httpStatusCode == 401 || error.httpStatusCode == 403 {
                self.onInitError!(.badCredentials, FaceCaptureInitError.badCredentials.description)
            }else{
                self.onInitError!(.invalidStatusCode, String(error.httpStatusCode!))
            }
            print("error", error)
        }
    }
    
    private func authAndCreateRequest(){
        let dInfo = UIDevice.deviceInfo
        let version = ComponentInfo.version.description
        print("dInfo", dInfo)
        let info = ["ios": dInfo]
        let apiRequest = ServiceSdk.createRequest(component : "bf", version: version, device:dInfo["id"] as! String, tag:tags,info:info)
        apiRequest.start()
        apiRequest.onSuccess { entity in
            let data:RequestModel = (entity.content as! RequestModel)
            if(data.status!.lowercased()=="ok" || data.status!.lowercased()=="valid"){
                self.requestId = data.id
                self.saveRequestId()
                self.onLoad!(self.requestId)
                print("data", data)
            }else{
                if(data.message! == "accountLocked"){
                    self.onInitError!(.accountLocked, "User account ("  + self.username + ") locked.")
                }else{
                    if(data.message == "userDisabled"){
                        self.onInitError!(.userDisabled, "User account ("  + self.username + ") disabled.")
                    }else{

                            // Falta homologar server y cliente
                            self.onInitError!(.unknown, data.message!)
                    }
                }
            }
        }
        apiRequest.onFailure { error in
            if error.httpStatusCode == 401 || error.httpStatusCode == 403 {
                self.onInitError!(.badCredentials, FaceCaptureInitError.badCredentials.description)
            }else{
                self.onInitError!(.invalidStatusCode, String(error.httpStatusCode!))
            }
            print("error", error)
        }
    }

    //##### Public ####
    
    func initialize(){
        
        updateStatus(status: ComponentStatus.initialized)
        
        // Use the latest credentials
        ServiceSdk.logIn(username: username, password: password)
        
        validateParameters()
        
        // Create for recover request
        let id = recoverRequestId()
        print("ID Recovered", id)
        if(id == ""){
            authAndCreateRequest()
        }else{
            validateRequest()
        }
    }
    
    // Initialize credentials
    func credentials(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    func policyRules(allow: [FaceCaptureFeature], deny: [FaceCaptureFeature], order: [FaceCaptureFeature]) {
        self.allow = allow
        self.deny = deny
        self.order = order
    }
    
    func prepare(segue:UIStoryboardSegue){
        if (segue.identifier == "ComponentCapture" && self.status == ComponentStatus.started) {
            var faceCaptureOptions = FaceCaptureOptions()
            faceCaptureOptions.id = requestId
            faceCaptureOptions.showPreview = showPreview
            faceCaptureOptions.livenessRequired = livenessRequired
            faceCaptureOptions.allow = allow
            faceCaptureOptions.deny = deny
            faceCaptureOptions.order = order
            faceCaptureOptions.maxValidations = maxValidations
            faceCaptureOptions.showIntro = showIntro
            faceCaptureOptions.allowCaptureOnFail = allowCaptureOnFail
            faceCaptureOptions.timeout = timeout
            //faceCaptureOptions.level = level
            faceCaptureOptions.aditionalConfigurationParameters = aditionalConfigurationParameters
            faceCaptureOptions.enableVideoHelp = enableVideoHelp
            faceCaptureOptions.enableTroubleshootHelp = enableTroubleshootHelp
            faceCaptureOptions.messagesResource = messagesResource
            faceCaptureOptions.allowManualSideView = allowManualSideView
            faceCaptureOptions.sideView = sideView
            
            // telling the compiler what type of VC the sugue.destination is
            let destinationVC = segue.destination as! ComponentCaptureViewController
            destinationVC.faceCaptureOptions = faceCaptureOptions
            destinationVC.loadTasks(tasks: tasks)
            destinationVC.requestId = self.requestId
            destinationVC.sdkComponent = (self as SdkComponent)
            destinationVC.delegate = self
        }
    }
    
    func start(){
        self.started = true
        self.status = ComponentStatus.started
        (self.viewController).performSegue(withIdentifier: identifier, sender: self.viewController)
    }
    
    func process(){
        if(started && faceCaptureResponse.responseEventType != .undefined){
            let result = faceCaptureResponse.faceCaptureResult
            switch faceCaptureResponse.responseEventType{
            case .success:
                print("Exito")
                self.onSuccess!(result,faceCaptureResponse.face, faceCaptureResponse.area, faceCaptureResponse.frame)
            case .fail:
                self.onFail!(result, faceCaptureResponse.faceCaptureReasonFail!, reasonFail)
            case .error:
                self.onError!(faceCaptureResponse.faceCaptureReasonError!, errorMessage)
            case .undefined:
                break
            }
        }
    }

    /*    */
    func updateStatus(status: ComponentStatus) {
        self.status = status
    }
    
    func getStatus() -> ComponentStatus {
        return self.status
    }
    
    func respond(response: Any, component : SDKComponent) {
        print("Tarantino")
        self.faceCaptureResponse = (response as? FaceCaptureResponse)!
        //responseType = faceCaptureResponse.faceCaptureResponseEventType
        print("result", self.faceCaptureResponse.faceCaptureResult.result)
    }
    
}

struct FaceCaptureResponse{
    var frame: UIImage =  UIImage()
    var face: UIImage =  UIImage()
    var area: UIImage =  UIImage()
    var faceCaptureResult = FaceCaptureResult()
    var faceCaptureReasonFail: FaceCaptureReasonFail?
    var reasonFail = ""
    var faceCaptureReasonError: FaceCaptureReasonError?
    var errorMessage = ""
    var responseEventType: ResponseEventType = .undefined
}

struct FaceCapturePreview{
    var frame: UIImage =  UIImage()
    var face: UIImage =  UIImage()
    var area: UIImage =  UIImage()
    var faceCaptureResult = FaceCaptureResult()
}

struct FaceCaptureResult{
    var result:String = "unevaluated"
    var confidence : Double = 0.0
    var retro: [String] = []
}

struct FaceCaptureOptions{
    var id: String = ""
    var livenessRequired: Bool = true
    var level: AntispoofingLevel = .medium
    var showPreview: Bool = false
    var showIntro: Bool = true
    var enableVideoHelp: Bool = false
    var enableTroubleshootHelp: Bool =  false
    var timeout : Int = 60
    var maxValidations : Int = 3
    var allowCaptureOnFail : Bool = false
    var sideView : CameraSideView = .front
    var allowManualSideView = false
    var allow: [FaceCaptureFeature] = []
    var deny: [FaceCaptureFeature] = [.glasses, .facemask]
    var order: [FaceCaptureFeature] = []
    var aditionalConfigurationParameters: [ComponentCaptureParameter: Any] = [:]
    
    var messagesResource: String = ""
    var tasks: [Task] = []
}

enum ComponentCaptureParameter{
    case helpVideoUrl,
         troubleshootUrl,
         showTroubleshootAfterFail,
         countInvalidRuleAsFail
}
